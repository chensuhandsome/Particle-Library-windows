import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import 'zotero_bridge.dart';

/// Thrown when zotero-inspire cannot complete an add request.
class ZoteroInspireException implements Exception {
  const ZoteroInspireException(this.message, {this.cancelled = false});

  final String message;
  final bool cancelled;

  @override
  String toString() => message;
}

/// What the installed zotero-inspire exposes through its external write API.
class ZoteroInspireStatus {
  const ZoteroInspireStatus({
    required this.available,
    this.capabilities = const <String>{},
    this.version,
  });

  final bool available;
  final Set<String> capabilities;
  final String? version;

  bool get canAdd =>
      available &&
      capabilities.contains('add_item') &&
      capabilities.contains('pick_save_target');

  static const ZoteroInspireStatus unavailable = ZoteroInspireStatus(
    available: false,
  );
}

/// The target returned by zotero-inspire's own save-target picker.
class ZoteroSaveTarget {
  const ZoteroSaveTarget({
    required this.libraryID,
    required this.collectionIDs,
    required this.tags,
    required this.note,
    this.selectedPath = '',
  });

  final int libraryID;
  final List<int> collectionIDs;
  final List<String> tags;
  final String note;
  final String selectedPath;
}

/// Result of `add_item`; [existing] is true when the record was already in
/// Zotero and no new item was created.
class ZoteroAddResult {
  const ZoteroAddResult({
    required this.itemKey,
    required this.itemID,
    required this.libraryID,
    required this.existing,
  });

  final String itemKey;
  final int itemID;
  final int libraryID;
  final bool existing;
}

class _ZoteroResponse {
  const _ZoteroResponse(this.status, this.body);

  final int status;
  final Map<String, Object?> body;
}

/// Local client for zotero-inspire's external APIs.
///
/// The plugin owns both the save-target picker and item creation. This client
/// only starts the picker, polls it, and sends the chosen target to `add_item`;
/// it never reads or edits Zotero's database.
class ZoteroInspireApi {
  const ZoteroInspireApi({
    this.baseUrl = 'http://127.0.0.1:23119',
    this.tokenOverride,
    this.pollInterval = const Duration(milliseconds: 350),
    this.pickerTimeout = const Duration(minutes: 5),
  });

  final String baseUrl;
  final String? tokenOverride;
  final Duration pollInterval;
  final Duration pickerTimeout;

  static const String _writePath = '/connector/zinspireWrite';
  static const String _pickerPath = '/connector/zinspirePickSaveTarget';
  static const Duration _requestTimeout = Duration(seconds: 5);
  static const Duration _addTimeout = Duration(seconds: 30);

  static String? _cachedToken;
  static const MethodChannel _activationChannel = MethodChannel('pdg.zotero');

  /// Extracts the plugin's write token from a Zotero `prefs.js`.
  ///
  /// The token is a 43-character base64url string. Returns null when the pref is
  /// absent or does not have the expected form.
  static String? parseWriteToken(String prefsJs) {
    final match = RegExp(
      r'user_pref\s*\(\s*"extensions\.zotero\.inspiremeta\.external_token"\s*,\s*"([A-Za-z0-9_-]{43})"\s*\)\s*;',
    ).firstMatch(prefsJs);
    return match?.group(1);
  }

  /// Checks zotero-inspire's write endpoint and capabilities.
  Future<ZoteroInspireStatus> probe() async {
    if (!ZoteroBridge.isSupportedPlatform) {
      return ZoteroInspireStatus.unavailable;
    }
    for (var attempt = 0; attempt < 2; attempt++) {
      final tokens = await _resolveTokens(refresh: attempt > 0);
      if (tokens.isEmpty) return ZoteroInspireStatus.unavailable;
      for (final token in tokens) {
        try {
          final response = await _post(_writePath, <String, Object?>{
            'op': 'ping',
          }, token: token);
          if (response.status == HttpStatus.notFound) {
            return ZoteroInspireStatus.unavailable;
          }
          if (response.status == HttpStatus.forbidden) {
            _cachedToken = null;
            continue;
          }
          if (response.status != HttpStatus.ok || response.body['ok'] != true) {
            continue;
          }
          _cachedToken = token;
          final raw = response.body['capabilities'];
          final capabilities = <String>{
            if (raw is List)
              for (final item in raw) item.toString(),
          };
          return ZoteroInspireStatus(
            available: true,
            capabilities: capabilities,
            version: response.body['version']?.toString(),
          );
        } catch (_) {
          return ZoteroInspireStatus.unavailable;
        }
      }
    }
    return ZoteroInspireStatus.unavailable;
  }

  /// Opens the plugin's save-target picker and waits for the user.
  ///
  /// Returns null when the picker is cancelled or expires.
  Future<ZoteroSaveTarget?> pickSaveTarget() async {
    final token = await _requireToken();
    final _ZoteroResponse start;
    try {
      start = await _post(_pickerPath, <String, Object?>{
        'wait': false,
        'multi': true,
        'includeTagsNote': true,
      }, token: token);
    } catch (error) {
      throw ZoteroInspireException('Zotero picker is unavailable: $error');
    }
    if (start.status == HttpStatus.conflict) {
      throw const ZoteroInspireException(
        'Another zotero-inspire picker is already open.',
      );
    }
    if (start.status != HttpStatus.ok) {
      throw ZoteroInspireException(
        'Zotero picker returned HTTP ${start.status}.',
      );
    }
    final requestID = start.body['requestID']?.toString() ?? '';
    if (requestID.isEmpty) {
      final status = start.body['status']?.toString();
      if (status == 'done') return _targetFrom(start.body);
      if (status == 'cancelled' || status == 'expired') return null;
      throw const ZoteroInspireException(
        'Zotero picker returned no request id.',
      );
    }

    final deadline = DateTime.now().add(pickerTimeout);
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(pollInterval);
      final _ZoteroResponse poll;
      try {
        poll = await _post(_pickerPath, <String, Object?>{
          'requestID': requestID,
        }, token: token);
      } catch (error) {
        throw ZoteroInspireException('Zotero picker is unavailable: $error');
      }
      if (poll.status != HttpStatus.ok) {
        throw ZoteroInspireException(
          'Zotero picker returned HTTP ${poll.status}.',
        );
      }
      final status = poll.body['status']?.toString() ?? '';
      if (status == 'pending') continue;
      if (status == 'done') return _targetFrom(poll.body);
      if (status == 'cancelled' || status == 'expired') return null;
      if (status == 'error') {
        throw ZoteroInspireException(
          poll.body['error']?.toString() ?? 'Zotero picker failed.',
        );
      }
    }
    throw const ZoteroInspireException(
      'Timed out waiting for the Zotero target.',
    );
  }

  /// Creates the item in the target chosen by [pickSaveTarget].
  Future<ZoteroAddResult> addItem({
    required String recid,
    required ZoteroSaveTarget target,
  }) async {
    final token = await _requireToken();
    final _ZoteroResponse response;
    try {
      response = await _post(
        _writePath,
        <String, Object?>{
          'op': 'add_item',
          'recid': recid,
          'library_id': target.libraryID,
          'collection_ids': target.collectionIDs,
          'tags': target.tags,
          'note': target.note,
        },
        token: token,
        timeout: _addTimeout,
      );
    } catch (error) {
      throw ZoteroInspireException('Could not add to Zotero: $error');
    }
    if (response.status != HttpStatus.ok || response.body['ok'] != true) {
      final code = response.body['code']?.toString() ?? '';
      final message = response.body['error']?.toString() ?? '';
      throw ZoteroInspireException(
        message.isEmpty
            ? 'Zotero add_item returned HTTP ${response.status}.'
            : '$message${code.isEmpty ? '' : ' ($code)'}',
      );
    }
    final itemKey = response.body['item_key']?.toString() ?? '';
    final itemID = _positiveInt(response.body['item_id']);
    final libraryID = _positiveInt(response.body['library_id']);
    if (itemKey.isEmpty || itemID == null || libraryID == null) {
      throw const ZoteroInspireException(
        'Zotero add_item returned an incomplete item.',
      );
    }
    return ZoteroAddResult(
      itemKey: itemKey,
      itemID: itemID,
      libraryID: libraryID,
      existing: response.body['status'] == 'existing',
    );
  }

  /// Probe, picker, then add. Returns null when the picker is cancelled.
  Future<ZoteroAddResult?> addItemWithPicker(String recid) async {
    final status = await probe();
    if (!status.canAdd) {
      throw const ZoteroInspireException(
        'zotero-inspire with add_item is not available.',
      );
    }
    await _activateZotero();
    try {
      final target = await pickSaveTarget();
      if (target == null) return null;
      return await addItem(recid: recid, target: target);
    } finally {
      await _activateSelf();
    }
  }

  Future<void> _activateZotero() async {
    if (!Platform.isMacOS) return;
    try {
      await _activationChannel.invokeMethod<bool>('activateZotero');
    } catch (_) {
      // The picker may still be visible if Zotero is already frontmost.
    }
  }

  Future<void> _activateSelf() async {
    if (!Platform.isMacOS) return;
    try {
      await _activationChannel.invokeMethod<bool>('activateSelf');
    } catch (_) {
      // Activation is cosmetic; never turn a successful add into an error.
    }
  }

  Future<String> _requireToken() async {
    final tokens = await _resolveTokens();
    if (tokens.isEmpty) {
      throw const ZoteroInspireException(
        'zotero-inspire write token was not found in the Zotero profile.',
      );
    }
    return _cachedToken ?? tokens.first;
  }

  Future<List<String>> _resolveTokens({bool refresh = false}) async {
    if (tokenOverride != null) return <String>[tokenOverride!];
    if (!refresh && _cachedToken != null) {
      return <String>[_cachedToken!];
    }
    return _findTokens();
  }

  Future<List<String>> _findTokens() async {
    final tokens = <String>{};
    for (final root in _profileRoots()) {
      try {
        final dir = Directory(root);
        if (!await dir.exists()) continue;
        await for (final entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is! File || !entity.path.endsWith('prefs.js')) continue;
          try {
            final token = parseWriteToken(await entity.readAsString());
            if (token != null) tokens.add(token);
          } catch (_) {
            // Unreadable profile; try the next one.
          }
        }
      } catch (_) {
        // Ignore absent/unreadable profile roots.
      }
    }
    return tokens.toList(growable: false);
  }

  Iterable<String> _profileRoots() sync* {
    final home = _userHome();
    if (Platform.isMacOS && home.isNotEmpty) {
      yield '$home/Library/Application Support/Zotero/Profiles';
    }
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? '';
      if (appData.isNotEmpty) {
        yield '$appData/Zotero/Zotero/Profiles';
        yield '$appData/Zotero/Profiles';
      }
    }
    if (Platform.isLinux && home.isNotEmpty) {
      yield '$home/.zotero/zotero';
    }
  }

  /// The real home directory, not the App Sandbox container.
  ///
  /// A sandboxed macOS app sees `HOME` as
  /// `~/Library/Containers/<bundle-id>/Data`; the Zotero profile lives under
  /// the real `/Users/<user>/Library/Application Support/Zotero`.
  String _userHome() {
    if (Platform.isMacOS) {
      final user =
          Platform.environment['USER'] ?? Platform.environment['LOGNAME'] ?? '';
      if (user.isNotEmpty) return '/Users/$user';
    }
    return Platform.environment['HOME'] ?? '';
  }

  Future<_ZoteroResponse> _post(
    String path,
    Map<String, Object?> body, {
    required String token,
    Duration timeout = _requestTimeout,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    // The write token authorises changes to the Zotero library. It is only ever
    // sent to this machine: a base address that is not loopback is refused
    // before anything is sent.
    if (!_isLoopbackHost(uri.host)) {
      throw const ZoteroInspireException(
        'The Zotero address must be on this computer.',
      );
    }
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.postUrl(uri).timeout(timeout);
      request.headers.contentType = ContentType.json;
      request.headers.set('x-zinspire-token', token);
      request.headers.set('zotero-allowed-request', 'true');
      final payload = utf8.encode(jsonEncode(body));
      // Zotero's Connector server rejects chunked bodies without a length.
      request.contentLength = payload.length;
      request.add(payload);
      final response = await request.close().timeout(timeout);
      final text = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      if (text.isEmpty) {
        return _ZoteroResponse(response.statusCode, const <String, Object?>{});
      }
      final decoded = jsonDecode(text);
      return _ZoteroResponse(
        response.statusCode,
        decoded is Map
            ? Map<String, Object?>.from(decoded)
            : const <String, Object?>{},
      );
    } on SocketException {
      throw const ZoteroInspireException('Zotero is not reachable.');
    } on TimeoutException {
      throw const ZoteroInspireException('Zotero did not respond in time.');
    } on FormatException {
      throw const ZoteroInspireException('Zotero returned invalid JSON.');
    } finally {
      client.close(force: true);
    }
  }

  static bool _isLoopbackHost(String host) =>
      host == '127.0.0.1' || host == 'localhost' || host == '::1' || host == '[::1]';

  static ZoteroSaveTarget _targetFrom(Map<String, Object?> body) {
    final libraryID = _positiveInt(body['libraryID']);
    final rawCollections = body['collectionIDs'];
    final collections = <int>[
      if (rawCollections is List)
        for (final value in rawCollections)
          if (_positiveInt(value) case final int id) id,
    ];
    final rawTags = body['tags'];
    final tags = <String>[
      if (rawTags is List)
        for (final value in rawTags)
          if (value.toString().trim() case final String tag when tag.isNotEmpty)
            tag,
    ];
    if (libraryID == null) {
      throw const ZoteroInspireException('Zotero picker returned no library.');
    }
    return ZoteroSaveTarget(
      libraryID: libraryID,
      collectionIDs: collections,
      tags: tags,
      note: body['note']?.toString() ?? '',
      selectedPath: body['selectedPath']?.toString() ?? '',
    );
  }

  static int? _positiveInt(Object? value) {
    final parsed = value is num ? value.toInt() : int.tryParse('$value');
    return parsed != null && parsed > 0 ? parsed : null;
  }
}
