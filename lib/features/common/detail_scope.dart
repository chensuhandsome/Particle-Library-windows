import 'package:flutter/material.dart';

class DetailNavigatorScope extends InheritedWidget {
  const DetailNavigatorScope({
    super.key,
    required this.navigatorKey,
    required super.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;

  static DetailNavigatorScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DetailNavigatorScope>();

  @override
  bool updateShouldNotify(DetailNavigatorScope oldWidget) =>
      oldWidget.navigatorKey != navigatorKey;
}
