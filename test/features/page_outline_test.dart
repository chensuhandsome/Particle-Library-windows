import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/features/common/page_outline.dart';

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
}
