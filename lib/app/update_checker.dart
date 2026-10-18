import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_strings.dart';

/// Current application version. Keep in sync with `pubspec.yaml`.
const String appVersion = '0.1.0';

/// Optional override for testing or for a self-hosted release manifest.
///
/// The default points at the public GitHub Releases API. While the repository
/// is private this returns 404; the UI reports "update check unavailable"
/// rather than crashing. Pass
/// `--dart-define=UPDATE_MANIFEST_URL=https://.../latest.json` to test another
/// endpoint.
const String updateManifestUrl = String.fromEnvironment(
  'UPDATE_MANIFEST_URL',
  defaultValue:
      'https://api.github.com/repos/fkguo/Particle-Library/releases/latest',
);

class UpdateInfo {
  const UpdateInfo({required this.version, required this.url, this.notes = ''});

  final String version;
  final String url;
  final String notes;
}

class UpdateCheckException implements Exception {
  const UpdateCheckException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UpdateChecker {
  UpdateChecker._();

  static bool get isConfigured =>
      Uri.tryParse(updateManifestUrl)?.hasScheme ?? false;

  /// Returns a newer release, or null when the app is current.
  ///
  /// Accepts either a GitHub Releases API response or a small manifest:
  /// `{"version":"0.2.0","url":"https://...","notes":"..."}`.
  static Future<UpdateInfo?> check({
    Uri? endpoint,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final uri = endpoint ?? Uri.tryParse(updateManifestUrl);
    if (uri == null || !uri.hasScheme) {
      throw const UpdateCheckException('No update endpoint is configured.');
    }
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.userAgentHeader, 'ParticleLibrary');
      final response = await request.close().timeout(timeout);
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        throw UpdateCheckException(
          response.statusCode == HttpStatus.notFound
              ? 'No published release is reachable yet.'
              : 'Update server returned HTTP ${response.statusCode}.',
        );
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        throw const UpdateCheckException('Invalid update response.');
      }
      final data = Map<String, Object?>.from(decoded);
      final version =
          (data['version'] ?? data['tag_name'])?.toString().trim() ?? '';
      final url = (data['url'] ?? data['html_url'])?.toString().trim() ?? '';
      final notes = (data['notes'] ?? data['body'])?.toString().trim() ?? '';
      if (version.isEmpty || url.isEmpty) {
        throw const UpdateCheckException('Update response lacks version/url.');
      }
      return compareVersions(version, appVersion) > 0
          ? UpdateInfo(
              version: version.replaceFirst(RegExp(r'^[vV]'), ''),
              url: url,
              notes: notes,
            )
          : null;
    } on UpdateCheckException {
      rethrow;
    } on SocketException catch (error) {
      throw UpdateCheckException('Cannot reach the update server: $error');
    } on HttpException catch (error) {
      throw UpdateCheckException('Update request failed: $error');
    } on FormatException catch (error) {
      throw UpdateCheckException('Invalid update data: $error');
    } finally {
      client.close(force: true);
    }
  }

  static int compareVersions(String a, String b) {
    List<int> parts(String value) => value
        .replaceFirst(RegExp(r'^[vV]'), '')
        .split(RegExp(r'[.+-]'))
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
    final left = parts(a);
    final right = parts(b);
    final length = left.length > right.length ? left.length : right.length;
    for (var i = 0; i < length; i++) {
      final l = i < left.length ? left[i] : 0;
      final r = i < right.length ? right[i] : 0;
      if (l != r) return l.compareTo(r);
    }
    return 0;
  }
}

Future<void> showUpdateAvailableDialog(
  BuildContext context,
  AppStrings strings,
  UpdateInfo info,
) async {
  final open = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(strings.updateAvailableTitle(info.version)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 320),
        child: SingleChildScrollView(
          child: Text(
            info.notes.isEmpty
                ? strings.updateAvailableMessage
                : '${strings.updateAvailableMessage}\n\n${info.notes}',
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(strings.updateLater),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(strings.updateOpen),
        ),
      ],
    ),
  );
  if (open != true) return;
  final uri = Uri.tryParse(info.url);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
