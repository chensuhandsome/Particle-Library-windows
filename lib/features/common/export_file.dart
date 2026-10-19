import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Saves a generated file on desktop, or opens the system share sheet on
/// Android/iOS (file_selector's save dialog is not implemented on mobile).
Future<bool> saveOrShareBytes({
  required String suggestedName,
  required List<int> bytes,
  required XTypeGroup type,
  String mimeType = 'application/octet-stream',
}) async {
  if (Platform.isAndroid || Platform.isIOS) {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$suggestedName');
    await file.writeAsBytes(bytes, flush: true);
    await shareFile(file, mimeType: mimeType);
    return true;
  }
  final location = await getSaveLocation(
    suggestedName: suggestedName,
    acceptedTypeGroups: [type],
  );
  if (location == null) return false;
  await File(location.path).writeAsBytes(bytes, flush: true);
  return true;
}

Future<void> shareFile(File file, {String mimeType = 'application/zip'}) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: mimeType)],
      subject: file.uri.pathSegments.last,
    ),
  );
}

/// Returns a writable temporary path for a file that will be shared.
Future<String> temporaryExportPath(String fileName) async {
  final directory = await getTemporaryDirectory();
  return '${directory.path}/$fileName';
}
