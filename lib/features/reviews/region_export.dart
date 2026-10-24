import 'dart:io';

/// Where "Export Markdown" writes the note text and its region screenshot.
///
/// [chosenPath] is what the save dialog returned. It is the Markdown file as
/// chosen (the extension is matched without regard to case, so `X.MD` stays
/// `X.MD` and is not turned into a different file name); a name without the
/// extension gains `.md`. The image goes beside it with the extension `.png`,
/// and an existing image is never overwritten: the screenshot gets the next
/// free `-N` suffix instead.
({String markdown, String image}) regionExportPaths(
  String chosenPath, {
  bool Function(String path)? exists,
}) {
  final taken = exists ?? (path) => File(path).existsSync();
  final hasExtension = chosenPath.toLowerCase().endsWith('.md');
  final stem = hasExtension
      ? chosenPath.substring(0, chosenPath.length - 3)
      : chosenPath;
  var image = '$stem.png';
  for (var n = 1; taken(image); n++) {
    image = '$stem-$n.png';
  }
  return (markdown: hasExtension ? chosenPath : '$chosenPath.md', image: image);
}

/// The Markdown body for an exported region: the screenshot, then the comment.
///
/// The image name is percent-encoded, parentheses included, so a space or
/// bracket in the file name cannot end the link early.
String regionMarkdown({required String imageName, required String comment}) {
  final target = Uri.encodeComponent(imageName)
      .replaceAll('(', '%28')
      .replaceAll(')', '%29');
  final body = StringBuffer('![Region]($target)\n');
  final text = comment.trim();
  if (text.isNotEmpty) {
    body
      ..writeln()
      ..writeln(text);
  }
  return body.toString();
}
