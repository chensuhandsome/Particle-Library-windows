import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/app/app_theme.dart';
import 'package:pdgapp/features/notes/notes_markdown_preview.dart';

void main() {
  testWidgets('renders headings, lists, code and inline math', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: NotesMarkdownPreview(
            markdown: r'''# Title

- **bold** item

```
code <x>
```

Math $\alpha_\pi$''',
          ),
        ),
      ),
    );
    expect(find.textContaining('Title'), findsOneWidget);
    expect(find.textContaining('bold'), findsOneWidget);
    expect(find.textContaining('code <x>'), findsOneWidget);
    expect(find.byType(SelectableText), findsWidgets);
  });
}
