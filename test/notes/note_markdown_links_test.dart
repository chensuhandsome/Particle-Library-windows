import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/app/app_theme.dart';
import 'package:pdgapp/features/notes/notes_markdown_preview.dart';
import 'package:pdgapp/notes/notes.dart';

void main() {
  // 27% of the DOIs in the PDG data hold parentheses; the capture sheet writes
  // them unescaped into the link destination.
  const doiTarget = 'reference:doi:10.1016/0370-2693(93)90355-u';

  group('plain text of a link whose destination has parentheses', () {
    test('keeps only the label', () {
      expect(
        plainTextFromMarkdown('Source: [B 302 (1993)]($doiTarget) done'),
        'Source: B 302 (1993) done',
      );
    });

    test('an image with such a destination keeps only its alt text', () {
      expect(plainTextFromMarkdown('![fig](my(file)name.png) end'), 'fig end');
    });

    test('plain parentheses in prose are untouched', () {
      expect(plainTextFromMarkdown('see (a) and (b)'), 'see (a) and (b)');
    });
  });

  group('inputs that used to take quadratic time', () {
    String timed(String Function() run, {int limitMs = 3000}) {
      final watch = Stopwatch()..start();
      final result = run();
      expect(
        watch.elapsedMilliseconds,
        lessThan(limitMs),
        reason: 'took ${watch.elapsedMilliseconds} ms',
      );
      return result;
    }

    test('a long run of "[" is linear', () {
      timed(() => plainTextFromMarkdown('[' * 80000));
    });

    test('a long run of "<" is linear', () {
      timed(() => plainTextFromMarkdown('<' * 80000));
    });

    test('a long run of "![" is linear', () {
      timed(() => plainTextFromMarkdown('![' * 40000));
    });

    test('a long run of "[a](" is linear', () {
      timed(() => plainTextFromMarkdown('[a](' * 20000));
    });
  });

  testWidgets('a link to a DOI with parentheses opens the whole target', (
    tester,
  ) async {
    String? opened;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: NotesMarkdownPreview(
            markdown: 'Source: [B 302 (1993)]($doiTarget) done',
            onOpenLink: (target) => opened = target,
          ),
        ),
      ),
    );
    // The label is the link; nothing of the destination leaks into the text.
    expect(find.textContaining('90355'), findsNothing);
    await tester.tap(find.text('B 302 (1993)'));
    expect(opened, doiTarget);
  });

  testWidgets('a long run of "[" does not freeze the preview', (tester) async {
    final watch = Stopwatch()..start();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: NotesMarkdownPreview(markdown: '[' * 40000)),
      ),
    );
    expect(watch.elapsedMilliseconds, lessThan(5000));
  });
}
