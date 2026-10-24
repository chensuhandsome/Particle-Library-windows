import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/app/app_theme.dart';
import 'package:pdgapp/features/common/page_outline.dart';

class _StatefulCounter extends StatefulWidget {
  @override
  State<_StatefulCounter> createState() => _StatefulCounterState();
}

class _StatefulCounterState extends State<_StatefulCounter> {
  int count = 0;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => setState(() => count++),
    child: Text('count $count'),
  );
}

void main() {
  testWidgets('outline target scrolls near the top of the viewport', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 1200),
                Container(key: key, height: 160, color: Colors.blue),
                const SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    scrollToOutlineTarget(key);
    await tester.pumpAndSettle();
    final top = tester.getRect(find.byKey(key)).top;
    expect(top, lessThan(120));
    expect(top, greaterThanOrEqualTo(0));
  });
  group('the page body keeps its state when the layout around it changes', () {
    const items = [PageOutlineItem(label: 'Section')];

    Widget host({required double width, required List<PageOutlineItem> items}) =>
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                height: 400,
                child: PageOutlineScaffold(
                  label: 'Contents',
                  items: items,
                  child: _StatefulCounter(),
                ),
              ),
            ),
          ),
        );

    testWidgets('resizing across the width threshold', (tester) async {
      await tester.pumpWidget(host(width: 1000, items: items));
      await tester.tap(find.byType(TextButton));
      await tester.tap(find.byType(TextButton));
      await tester.pump();
      expect(find.text('count 2'), findsOneWidget);

      await tester.pumpWidget(host(width: 500, items: items));
      expect(find.text('count 2'), findsOneWidget);

      await tester.pumpWidget(host(width: 1000, items: items));
      expect(find.text('count 2'), findsOneWidget);
    });

    testWidgets('the outline appearing and disappearing', (tester) async {
      await tester.pumpWidget(host(width: 1000, items: items));
      await tester.tap(find.byType(TextButton));
      await tester.pump();
      expect(find.text('count 1'), findsOneWidget);

      // A search with no matches empties the outline; the page body (and the
      // search field in it) must survive that.
      await tester.pumpWidget(host(width: 1000, items: const []));
      expect(find.text('count 1'), findsOneWidget);

      await tester.pumpWidget(host(width: 1000, items: items));
      expect(find.text('count 1'), findsOneWidget);
    });
  });
}
