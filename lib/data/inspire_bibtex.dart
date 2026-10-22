import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'reference_metadata.dart';

class InspireBibtexException implements Exception {
  const InspireBibtexException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Fetches the INSPIRE-HEP BibTeX entry for a reference.
///
/// Endpoints are the ones used by the local zotero-inspire plugin:
/// - record:  /api/literature/{recid}?format=bibtex
/// - DOI:    /api/literature?q=doi:{doi}&size=1&format=bibtex
class InspireBibtexService {
  /// [uriBuilder] replaces the INSPIRE address, for tests against a local
  /// server; the app always uses [bibtexUri].
  const InspireBibtexService({this.uriBuilder});

  final Uri? Function({required String inspireId, required String doi})?
  uriBuilder;

  static final Map<String, String> _citeKeyCache = {};
  static final Map<String, String> _bibtexCache = {};

  /// INSPIRE's BibTeX entry begins with `@article{KEY,` (or another entry
  /// type). The key is authoritative and avoids the slow metadata field
  /// projection endpoint.
  static String? parseBibtexKey(String bibtex) {
    final match = RegExp(r'^\s*@[A-Za-z]+\s*\{\s*([^,\s]+)\s*,')
        .firstMatch(bibtex.trim());
    return match?.group(1);
  }

  static Uri? bibtexUri({required String inspireId, required String doi}) {
    final id = inspireId.trim();
    if (RegExp(r'^[0-9]+$').hasMatch(id)) {
      return Uri.https('inspirehep.net', '/api/literature/$id', {
        'format': 'bibtex',
      });
    }
    final normalized = ReferenceMetadataService.normalizeDoi(doi);
    if (!ReferenceMetadataService.isValidDoi(normalized)) return null;
    return Uri.https('inspirehep.net', '/api/literature', {
      'q': 'doi:$normalized',
      'size': '1',
      'format': 'bibtex',
    });
  }

  static bool canFetch({required String inspireId, required String doi}) =>
      bibtexUri(inspireId: inspireId, doi: doi) != null;

  /// Returns the INSPIRE BibTeX key (cite key) for a reference. The result is
  /// cached in memory for the current app session.
  Future<String?> fetchCiteKey({
    required String inspireId,
    required String doi,
  }) async {
    final key = '${inspireId.trim()}|${doi.trim().toLowerCase()}';
    final cached = _citeKeyCache[key];
    if (cached != null) return cached;
    try {
      final bibtex = await fetchBibtex(inspireId: inspireId, doi: doi);
      final parsed = parseBibtexKey(bibtex);
      if (parsed != null && parsed.isNotEmpty) {
        if (_citeKeyCache.length > 200) _citeKeyCache.remove(_citeKeyCache.keys.first);
        _citeKeyCache[key] = parsed;
      }
      return parsed;
    } on InspireBibtexException {
      return null;
    }
  }

  Future<String> fetchBibtex({
    required String inspireId,
    required String doi,
  }) async {
    final cacheKey = '${inspireId.trim()}|${doi.trim().toLowerCase()}';
    final cached = _bibtexCache[cacheKey];
    if (cached != null) return cached;
    final uri = (uriBuilder ?? bibtexUri)(inspireId: inspireId, doi: doi);
    if (uri == null) {
      throw const InspireBibtexException('没有可用的 INSPIRE ID 或 DOI');
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8)
      ..idleTimeout = const Duration(seconds: 4);
    try {
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 12));
      request.headers.set(HttpHeaders.acceptHeader, 'application/x-bibtex');
      request.headers.set(HttpHeaders.userAgentHeader,
          'ParticleDesk/0.1 (offline PDG reader; INSPIRE BibTeX export)');
      final response = await request.close().timeout(const Duration(seconds: 12));
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 404) {
        throw const InspireBibtexException('INSPIRE 未找到该文献');
      }
      if (response.statusCode != 200) {
        throw InspireBibtexException('INSPIRE 返回 HTTP ${response.statusCode}');
      }
      final text = body.trim();
      if (text.isEmpty) {
        throw const InspireBibtexException('INSPIRE 返回了空 BibTeX');
      }
      if (!text.startsWith('@') || !text.contains('{')) {
        throw const InspireBibtexException('INSPIRE 返回内容不是 BibTeX');
      }
      if (_bibtexCache.length > 100) _bibtexCache.remove(_bibtexCache.keys.first);
      _bibtexCache[cacheKey] = text;
      return text;
    } on TimeoutException {
      throw const InspireBibtexException('联网查询超时');
    } on SocketException {
      throw const InspireBibtexException('无法连接 INSPIRE');
    } on HandshakeException {
      throw const InspireBibtexException('无法建立 TLS 连接');
    } on HttpException {
      // The connection dropped part-way through the answer.
      throw const InspireBibtexException('INSPIRE 连接中断');
    } on FormatException {
      // The body was not valid UTF-8 text.
      throw const InspireBibtexException('INSPIRE 返回了无法读取的内容');
    } finally {
      client.close(force: true);
    }
  }
}
