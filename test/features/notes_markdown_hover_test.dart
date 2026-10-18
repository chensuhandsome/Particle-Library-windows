import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/app/app_theme.dart';
import 'package:pdgapp/features/notes/notes_markdown_preview.dart';

void main() {
  testWidgets('mouse hover reaches an inline note link', (tester) async {
    String? hovered;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: NotesMarkdownPreview(
            markdown: '[source](pdgid:S016MPL)',
            onOpenLink: (_) {},
            onHoverLink: (target, _) => hovered = target,
          ),
        ),
      ),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('source')));
    await tester.pump();
    expect(hovered, 'pdgid:S016MPL');
  });
}
