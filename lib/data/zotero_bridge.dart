import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Best-effort link to a running Zotero desktop instance.
///
/// Zotero's local API is read-only. This bridge therefore supports opening an
/// existing item by its INSPIRE recid; it never creates or mutates Zotero data.
/// If no item is found, the caller can copy BibTeX for a manual Zotero import.
class ZoteroBridge {
  const ZoteroBridge();

  static const String _base = 'http://127.0.0.1:23119';

  /// Quick check that Zotero's local API is reachable.
  Future<bool> isAvailable() async {
    try {
      final response = await _get(Uri.parse('$_base/api/users/0/items?limit=1'))
          .timeout(const Duration(seconds: 2));
      return response != null && response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Finds an existing Zotero item by INSPIRE recid, DOI or arXiv id.
  ///
  /// The recid is preferred (zotero-inspire writes it to Archive Location),
  /// but many manually imported items only carry a DOI or arXiv identifier.
  /// Queries are local and read-only; nothing is created or changed.
  Future<String?> findItemKey({
    String? recid,
    String? doi,
    String? arxivId,
  }) async {
    final recidKey = recid?.trim() ?? '';
    final doiKey = normalizeDoi(doi ?? '');
    final arxivKey = normalizeArxiv(arxivId ?? '');
    final queries = <String>[
      if (recidKey.isNotEmpty) ...<String>[
        recidKey,
        'INSPIRE-$recidKey',
        'INSPIRE:$recidKey',
      ],
      if (doiKey.isNotEmpty) doiKey,
      if (arxivKey.isNotEmpty) arxivKey,
    ];
    for (final query in queries) {
      final items = await _itemsFor(query);
      for (final item in items) {
        final key = item.key;
        final data = item.data;
        if (recidKey.isNotEmpty && extractInspireRecid(data) == recidKey) {
          return key;
        }
        if (doiKey.isNotEmpty && extractDoi(data) == doiKey) {
          return key;
        }
        if (arxivKey.isNotEmpty && extractArxiv(data) == arxivKey) {
          return key;
        }
      }
    }
    return null;
  }

  /// Backwards-compatible recid-only lookup.
  Future<String?> findItemKeyForRecid(String recid) =>
      findItemKey(recid: recid);

  Future<List<_ZoteroItem>> _itemsFor(String query) async {
    final uri = Uri.parse(
      '$_base/api/users/0/items?q=${Uri.encodeQueryComponent(query)}'
      '&limit=25&format=json&qmode=everything',
    );
    final response = await _get(uri).timeout(const Duration(seconds: 10));
    if (response == null || response.statusCode != 200) {
      return const <_ZoteroItem>[];
    }
    final body = await response.transform(utf8.decoder).join();
    final decoded = jsonDecode(body);
    if (decoded is! List) return const <_ZoteroItem>[];
    final result = <_ZoteroItem>[];
    for (final raw in decoded) {
      if (raw is! Map) continue;
      final data = raw['data'];
      final key = raw['key']?.toString() ?? '';
      if (key.isEmpty || data is! Map) continue;
      result.add(_ZoteroItem(key, Map<String, Object?>.from(data)));
    }
    return result;
  }

  static String normalizeDoi(String value) {
    var doi = value.trim().toLowerCase();
    doi = doi.replaceFirst(RegExp(r'^https?://(?:dx\.)?doi\.org/'), '');
    doi = doi.replaceFirst(RegExp(r'^doi:\s*'), '');
    return doi;
  }

  static String normalizeArxiv(String value) {
    var arxiv = value.trim().toLowerCase();
    arxiv = arxiv.replaceFirst(RegExp(r'^arxiv:\s*'), '');
    arxiv = arxiv.replaceFirst(RegExp(r'v\d+$'), '');
    return arxiv;
  }

  static String? extractDoi(Map<String, Object?> data) {
    final candidates = <String>[
      data['DOI']?.toString() ?? '',
      data['doi']?.toString() ?? '',
      data['url']?.toString() ?? '',
      data['extra']?.toString() ?? '',
    ];
    for (final candidate in candidates) {
      final match = RegExp(
        r'10\.\d{4,9}/[^\s,;]+',
        caseSensitive: false,
      ).firstMatch(candidate);
      if (match != null) return normalizeDoi(match.group(0)!);
    }
    return null;
  }

  static String? extractArxiv(Map<String, Object?> data) {
    final archive = data['archive']?.toString().trim().toLowerCase() ?? '';
    final location = data['archiveLocation']?.toString().trim() ?? '';
    if (archive == 'arxiv' && location.isNotEmpty) {
      return normalizeArxiv(location);
    }
    final candidates = <String>[
      data['url']?.toString() ?? '',
      data['extra']?.toString() ?? '',
      location,
    ];
    for (final candidate in candidates) {
      final match = RegExp(
        r'(?:arxiv:\s*|arxiv\.org/(?:abs|pdf)/)([a-z\-]+(?:\.[a-z\-]+)?/\d{7}|\d{4}\.\d{4,5})',
        caseSensitive: false,
      ).firstMatch(candidate);
      if (match != null) return normalizeArxiv(match.group(1)!);
    }
    return null;
  }

  static String? extractInspireRecid(Map<String, Object?> data) {
    // zotero-inspire stores the recid in Archive Location with Archive=INSPIRE.
    final archive = data['archive']?.toString().trim().toLowerCase() ?? '';
    final archiveLocation = data['archiveLocation']?.toString().trim() ?? '';
    final locationRecid = RegExp(
      r'^(?:INSPIRE|INSPIRE-ID|RECID)?[\s:#-]*(\d+)$',
      caseSensitive: false,
    ).firstMatch(archiveLocation);
    if (locationRecid != null &&
        (archive == 'inspire' ||
            archiveLocation.toUpperCase().contains('INSPIRE'))) {
      return locationRecid.group(1);
    }
    final url = data['url']?.toString() ?? '';
    final link = RegExp(
      r'^https?://(?:www\.)?inspirehep\.net/(?:(?:api/)?literature|record)/([0-9]+)',
      caseSensitive: false,
    ).firstMatch(url);
    if (link != null) return link.group(1);
    final extra = data['extra']?.toString() ?? '';
    final fromExtra = RegExp(
      r'(?:INSPIRE(?:\s*(?:ID|recid))?\s*[:#-]\s*|recid\s*[:#-]\s*|'
      r'inspirehep\.net/(?:literature|record)/)(\d+)(?![\d/])',
      caseSensitive: false,
    ).firstMatch(extra);
    if (fromExtra != null) return fromExtra.group(1);
    final callNumber = data['callNumber']?.toString() ?? '';
    final fromCallNumber = RegExp(
      r'^(?:INSPIRE[\s:#-]*)?(\d+)$',
      caseSensitive: false,
    ).firstMatch(callNumber.trim());
    return fromCallNumber?.group(1);
  }

  Future<HttpClientResponse?> _get(Uri uri) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 2)
      ..idleTimeout = const Duration(seconds: 2);
    try {
      final request = await client.getUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'Particle Library/0.1 (local Zotero lookup)',
      );
      return await request.close();
    } catch (_) {
      client.close(force: true);
      return null;
    }
  }
}

class _ZoteroItem {
  const _ZoteroItem(this.key, this.data);
  final String key;
  final Map<String, Object?> data;
}
