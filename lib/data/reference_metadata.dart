import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Optional DOI enrichment for references whose snapshot title is empty.
///
/// The snapshot remains the source of truth. This service only fetches a
/// display title from Crossref for an explicit user action; the result is
/// cached in the local user store and labelled with its source.
class CrossrefTitleResult {
  const CrossrefTitleResult({
    required this.doi,
    required this.title,
    required this.source,
  });

  final String doi;
  final String title;
  final String source;
}

class ReferenceMetadataException implements Exception {
  const ReferenceMetadataException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReferenceMetadataService {
  const ReferenceMetadataService();

  static final RegExp _doiPattern = RegExp(r'^10\.[0-9]{4,9}/\S+$');

  /// Removes common URL/prefix forms and rejects malformed DOIs.
  static String normalizeDoi(String raw) {
    var value = raw.trim();
    if (value.toLowerCase().startsWith('doi:')) {
      value = value.substring(4).trim();
    }
    for (final prefix in const [
      'https://doi.org/',
      'http://doi.org/',
      'https://dx.doi.org/',
      'http://dx.doi.org/',
    ]) {
      if (value.toLowerCase().startsWith(prefix)) {
        value = value.substring(prefix.length).trim();
        break;
      }
    }
    return value;
  }

  static bool isValidDoi(String raw) {
    final value = normalizeDoi(raw);
    return value.isNotEmpty &&
        _doiPattern.hasMatch(value) &&
        !value.contains(RegExp(r'\s'));
  }

  static bool hasInspireId(String value) =>
      RegExp(r'^[0-9]+$').hasMatch(value.trim());

  /// A direct record link when INSPIRE already gave an ID; otherwise an
  /// explicit INSPIRE search by DOI, then by title. The fallback is a search,
  /// not a claim that the record was matched.
  static Uri? inspireUri({
    required String inspireId,
    required String doi,
    required String title,
  }) {
    final id = inspireId.trim();
    if (hasInspireId(id)) {
      return Uri.parse('https://inspirehep.net/literature/$id');
    }
    final normalized = normalizeDoi(doi);
    if (isValidDoi(normalized)) {
      return Uri.https('inspirehep.net', '/search', {'p': 'doi:$normalized'});
    }
    final cleaned = title.trim();
    if (cleaned.isNotEmpty) {
      return Uri.https('inspirehep.net', '/search', {'p': 'title "$cleaned"'});
    }
    return null;
  }

  static Uri? crossrefUri(String raw) {
    final doi = normalizeDoi(raw);
    if (!isValidDoi(doi)) return null;
    return Uri.parse(
        'https://api.crossref.org/works/${Uri.encodeComponent(doi)}');
  }

  Future<CrossrefTitleResult> fetchTitleByDoi(String rawDoi) async {
    final doi = normalizeDoi(rawDoi);
    if (!isValidDoi(doi)) {
      throw const ReferenceMetadataException('DOI 格式无效');
    }
    final uri = crossrefUri(doi);
    if (uri == null) {
      throw const ReferenceMetadataException('DOI 格式无效');
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8)
      ..idleTimeout = const Duration(seconds: 4);
    try {
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 12));
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.userAgentHeader,
          'ParticleDesk/0.1 (offline PDG reader; DOI title lookup)');
      final response = await request.close().timeout(const Duration(seconds: 12));
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 404) {
        throw const ReferenceMetadataException('Crossref 未找到该 DOI');
      }
      if (response.statusCode != 200) {
        throw ReferenceMetadataException(
            'Crossref 返回 HTTP ${response.statusCode}');
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        throw const ReferenceMetadataException('Crossref 返回格式异常');
      }
      final message = decoded['message'];
      if (message is! Map) {
        throw const ReferenceMetadataException('Crossref 未返回文献记录');
      }
      final titles = message['title'];
      String? title;
      if (titles is List) {
        for (final value in titles) {
          final cleaned = cleanTitle(value?.toString() ?? '');
          if (cleaned.isNotEmpty) {
            title = cleaned;
            break;
          }
        }
      }
      if (title == null) {
        throw const ReferenceMetadataException('Crossref 记录没有题名');
      }
      return CrossrefTitleResult(doi: doi, title: title, source: 'Crossref');
    } on TimeoutException {
      throw const ReferenceMetadataException('联网查询超时');
    } on SocketException {
      throw const ReferenceMetadataException('无法连接 Crossref');
    } on HandshakeException {
      throw const ReferenceMetadataException('无法建立 TLS 连接');
    } finally {
      client.close(force: true);
    }
  }

  /// Crossref titles can contain JATS/MathML markup. Keep the text content,
  /// strip tags, decode the common entities and collapse whitespace.
  static String cleanTitle(String raw) {
    var text = raw.replaceAll(RegExp(r'<[^>]*>'), ' ');
    text = text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
    text = text.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
      final code = int.tryParse(match.group(1)!, radix: 16);
      return code == null ? match.group(0)! : String.fromCharCode(code);
    });
    text = text.replaceAllMapped(RegExp(r'&#([0-9]+);'), (match) {
      final code = int.tryParse(match.group(1)!);
      return code == null ? match.group(0)! : String.fromCharCode(code);
    });
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }
}
