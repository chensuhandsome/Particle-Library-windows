import 'package:flutter/widgets.dart';

/// Tells pages whether AppShell is currently hiding its global chrome.
///
/// A nested [PageScaffold] normally suppresses its own back button because the
/// shell supplies one. When the shell is immersive, the page must supply the
/// back affordance itself.
class ChromeVisibilityScope extends InheritedWidget {
  const ChromeVisibilityScope({
    super.key,
    required this.hidden,
    required super.child,
  });

  final bool hidden;

  static bool isHidden(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<ChromeVisibilityScope>()
            ?.hidden ??
        false;
  }

  @override
  bool updateShouldNotify(ChromeVisibilityScope oldWidget) =>
      oldWidget.hidden != hidden;
}
