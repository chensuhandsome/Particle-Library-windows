import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/app/navigation.dart';

Widget _navigator(NavigationController controller) {
  return NavigationScope(
    controller: controller,
    child: Navigator(
      key: controller.navigatorKey,
      observers: <NavigatorObserver>[controller],
      onGenerateRoute: (settings) => MaterialPageRoute<void>(
        settings: settings,
        builder: controller.rootBuilder,
      ),
    ),
  );
}

void main() {
  testWidgets('controller keeps back and forward history', (tester) async {
    final hub = NavigationHub();
    final controller = NavigationController(
      hub: hub,
      rootBuilder: (_) => const Text('root'),
    );
    addTearDown(() {
      controller.dispose();
      hub.dispose();
    });

    await tester.pumpWidget(MaterialApp(home: _navigator(controller)));
    expect(find.text('root'), findsOneWidget);

    controller.push<void>(const Text('page'));
    await tester.pumpAndSettle();
    expect(find.text('page'), findsOneWidget);
    expect(controller.canGoBack, isTrue);
    expect(controller.canGoForward, isFalse);

    controller.back();
    await tester.pumpAndSettle();
    expect(find.text('root'), findsOneWidget);
    expect(controller.canGoBack, isFalse);
    expect(controller.canGoForward, isTrue);

    controller.forward();
    await tester.pumpAndSettle();
    expect(find.text('page'), findsOneWidget);
    expect(controller.canGoBack, isTrue);
    expect(controller.canGoForward, isFalse);
  });

  testWidgets('hub prefers tab pages and remembers the stack to redo', (
    tester,
  ) async {
    final hub = NavigationHub();
    final tab = NavigationController(
      hub: hub,
      rootBuilder: (_) => const Text('tab-root'),
    );
    final detail = NavigationController(
      hub: hub,
      rootBuilder: (_) => const Text('detail-root'),
    );
    hub.registerTab('search', tab);
    hub.registerDetail('search', detail);
    addTearDown(() {
      tab.dispose();
      detail.dispose();
      hub.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            Expanded(child: _navigator(tab)),
            Expanded(child: _navigator(detail)),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    tab.push<void>(const Text('tab-page'));
    await tester.pumpAndSettle();
    expect(hub.backController, same(tab));

    detail.push<void>(const Text('detail-page'));
    await tester.pumpAndSettle();
    // A page pushed over the whole tab is topmost.
    expect(hub.backController, same(tab));

    tab.back();
    await tester.pumpAndSettle();
    expect(find.text('tab-root'), findsOneWidget);
    expect(hub.backController, same(detail));
    // The just-popped tab page is the forward target even though the detail
    // pane still has a back stack.
    expect(hub.forwardController, same(tab));

    hub.setActiveTab('favorites');
    expect(hub.canGoForward, isFalse);
    hub.setActiveTab('search');
    expect(hub.canGoForward, isTrue);

    hub.forward();
    await tester.pumpAndSettle();
    expect(find.text('tab-page'), findsOneWidget);
    expect(hub.canGoForward, isFalse);
  });

  testWidgets('resetToRoot clears both directions', (tester) async {
    final hub = NavigationHub();
    final controller = NavigationController(
      hub: hub,
      rootBuilder: (_) => const Text('root'),
    );
    addTearDown(() {
      controller.dispose();
      hub.dispose();
    });

    await tester.pumpWidget(MaterialApp(home: _navigator(controller)));
    controller.push<void>(const Text('page'));
    await tester.pumpAndSettle();
    controller.back();
    await tester.pumpAndSettle();
    expect(controller.canGoForward, isTrue);

    controller.resetToRoot();
    await tester.pumpAndSettle();
    expect(controller.canGoBack, isFalse);
    expect(controller.canGoForward, isFalse);
    expect(find.text('root'), findsOneWidget);
  });

  testWidgets('a new push clears forward history in every stack', (
    tester,
  ) async {
    final hub = NavigationHub();
    final tab = NavigationController(
      hub: hub,
      rootBuilder: (_) => const Text('tab-root'),
    );
    final detail = NavigationController(
      hub: hub,
      rootBuilder: (_) => const Text('detail-root'),
    );
    hub.registerTab('search', tab);
    hub.registerDetail('search', detail);
    addTearDown(() {
      tab.dispose();
      detail.dispose();
      hub.dispose();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Row(
          children: [
            Expanded(child: _navigator(tab)),
            Expanded(child: _navigator(detail)),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    tab.push<void>(const Text('tab-page'));
    await tester.pumpAndSettle();
    tab.back();
    await tester.pumpAndSettle();
    expect(tab.canGoForward, isTrue);

    detail.push<void>(const Text('detail-page'));
    await tester.pumpAndSettle();
    expect(tab.canGoForward, isFalse);
    expect(hub.canGoForward, isFalse);
  });

  testWidgets('rootBack exposes a root-level back action', (tester) async {
    final hub = NavigationHub();
    final controller = NavigationController(
      hub: hub,
      rootBuilder: (_) => const Text('root'),
    );
    addTearDown(() {
      controller.dispose();
      hub.dispose();
    });

    await tester.pumpWidget(MaterialApp(home: _navigator(controller)));
    var called = 0;
    controller.rootBack = () => called++;
    await tester.pump();
    expect(controller.canGoBack, isTrue);
    controller.back();
    expect(called, 1);
    expect(find.text('root'), findsOneWidget);

    controller.rootBack = null;
    await tester.pump();
    expect(controller.canGoBack, isFalse);
  });
}
