import '../core/app_paths.dart';

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

class ReviewCacheException implements Exception {
  const ReviewCacheException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Local cache for official PDG review PDFs.
///
/// The PDFs are downloaded only on demand (or by the explicit "cache all"
/// action). Downloads are written to a `.partial` file and renamed only after
/// a `%PDF` header check, so an interrupted download never becomes a cached
/// review.
class ReviewCache {
  ReviewCache(this.rootDirectory);

  final Directory rootDirectory;

  static const _edition = '2026';

  static Future<ReviewCache> open() async {
    try {
      final support = await appSupportDirectory();
      final root = Directory('${support.path}/ParticleDesk/reviews/$_edition');
      await root.create(recursive: true);
      return ReviewCache(root);
    } catch (error) {
      throw ReviewCacheException('无法访问综述缓存目录：$error');
    }
  }

  File fileFor(String fileName) {
    final safe = fileName.replaceAll(RegExp(r'[\\/]'), '_');
    return File('${rootDirectory.path}/$safe');
  }

  Future<Set<String>> cachedFiles(Iterable<String> fileNames) async {
    final result = <String>{};
    for (final name in fileNames) {
      if (await fileFor(name).exists()) result.add(name);
    }
    return result;
  }

  Future<int> cachedBytes(Iterable<String> fileNames) async {
    var total = 0;
    for (final name in fileNames) {
      final file = fileFor(name);
      if (await file.exists()) total += await file.length();
    }
    return total;
  }

  /// Downloads running now, by target path. A second request for the same
  /// review (a double tap, or a tap during "cache all") joins the first instead
  /// of starting another one: two downloads share one `.partial` file, delete
  /// each other's data, and the first to finish would cache the other's
  /// half-written file.
  static final Map<String, Future<File>> _inFlight = <String, Future<File>>{};

  /// Largest review accepted. The real ones are a few MB.
  @visibleForTesting
  static int maxBytes = 256 << 20;

  /// Lets tests download from a local server; production accepts https only.
  @visibleForTesting
  static bool allowLoopbackHttp = false;

  Future<File> download({
    required String fileName,
    required String url,
    void Function(int received, int? total)? onProgress,
  }) {
    final target = fileFor(fileName);
    final running = _inFlight[target.path];
    if (running != null) return running;
    final future = _download(target, url, onProgress);
    _inFlight[target.path] = future;
    future.whenComplete(() {
      if (identical(_inFlight[target.path], future)) {
        _inFlight.remove(target.path);
      }
    }).ignore();
    return future;
  }

  Future<File> _download(
    File target,
    String url,
    void Function(int received, int? total)? onProgress,
  ) async {
    if (await target.exists() && await _isPdf(target)) return target;

    final uri = Uri.tryParse(url);
    final loopbackOk =
        allowLoopbackHttp &&
        uri != null &&
        uri.scheme == 'http' &&
        (uri.host == '127.0.0.1' || uri.host == 'localhost');
    if (uri == null || (uri.scheme != 'https' && !loopbackOk)) {
      throw const ReviewCacheException('综述链接不是 HTTPS 地址');
    }
    await rootDirectory.create(recursive: true);
    final partial = File('${target.path}.partial');
    if (await partial.exists()) await partial.delete();

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 12)
      ..idleTimeout = const Duration(seconds: 8);
    IOSink? sink;
    try {
      final request = await client
          .getUrl(uri)
          .timeout(const Duration(seconds: 15));
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'ParticleDesk/0.1 (offline PDG reader; review PDF cache)',
      );
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      if (response.statusCode != 200) {
        throw ReviewCacheException('PDG 返回 HTTP ${response.statusCode}');
      }
      final expected = response.contentLength > 0
          ? response.contentLength
          : null;
      if (expected != null && expected > maxBytes) {
        throw const ReviewCacheException('综述文件过大');
      }
      sink = partial.openWrite();
      var received = 0;
      await for (final chunk in response.timeout(const Duration(seconds: 30))) {
        received += chunk.length;
        if (received > maxBytes) {
          throw const ReviewCacheException('综述文件过大');
        }
        sink.add(chunk);
        onProgress?.call(received, expected);
      }
      await sink.flush();
      await sink.close();
      sink = null;
      if (received == 0 || !await _isPdf(partial)) {
        throw const ReviewCacheException('下载内容不是有效 PDF');
      }
      if (expected != null && received != expected) {
        throw const ReviewCacheException('下载内容不完整');
      }
      if (await target.exists()) await target.delete();
      await partial.rename(target.path);
      return target;
    } on TimeoutException {
      throw const ReviewCacheException('下载综述超时');
    } on SocketException {
      throw const ReviewCacheException('无法连接 PDG 网站');
    } on HandshakeException {
      throw const ReviewCacheException('无法建立 TLS 连接');
    } on HttpException {
      throw const ReviewCacheException('下载中断');
    } finally {
      await sink?.close();
      if (await partial.exists()) {
        try {
          await partial.delete();
        } catch (_) {}
      }
      client.close(force: true);
    }
  }

  /// Deletes only the selected cached PDFs and leaves other reviews intact.
  Future<int> removeFiles(Iterable<String> fileNames) async {
    var removed = 0;
    for (final fileName in fileNames) {
      final file = fileFor(fileName);
      if (await file.exists()) {
        await file.delete();
        removed++;
      }
    }
    return removed;
  }

  Future<void> clear() async {
    if (await rootDirectory.exists()) {
      await rootDirectory.delete(recursive: true);
    }
    await rootDirectory.create(recursive: true);
  }

  Future<bool> _isPdf(File file) async {
    try {
      final handle = await file.open();
      try {
        final header = await handle.read(5);
        return String.fromCharCodes(header) == '%PDF-';
      } finally {
        await handle.close();
      }
    } catch (_) {
      return false;
    }
  }
}
