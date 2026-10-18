import 'package:flutter/material.dart';

/// Debug-only hooks used by the VM-service bridge and the screenshot harness.
/// They are set by real pages and are inert unless `kDebugMode` is on.
typedef DebugSearchHook = void Function(String query);
typedef DebugIntHook = void Function(int index);
typedef DebugStringHook = void Function(String value);

DebugSearchHook? debugSearchHook;
DebugIntHook? debugTabHook;
DebugStringHook? debugThemeHook;
VoidCallback? debugTrendHook;
typedef DebugJsonHook = String Function();
DebugJsonHook? debugStateHook;

Route<T> debugRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );
}
