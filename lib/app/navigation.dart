import 'package:flutter/material.dart';

import '../features/common/detail_scope.dart';
import '../features/entry/entry_route_page.dart';
import '../features/reference/reference_page.dart';

class AppNav {
  static NavigatorState _navigatorOf(BuildContext context) {
    final scope = DetailNavigatorScope.maybeOf(context);
    final nested = scope?.navigatorKey.currentState;
    if (nested != null) return nested;
    return Navigator.of(context);
  }

  static Future<T?> push<T>(BuildContext context, Widget page) {
    return _navigatorOf(context).push<T>(
      MaterialPageRoute<T>(builder: (_) => page),
    );
  }

  static Future<T?> replaceAll<T>(BuildContext context, Widget page) {
    return _navigatorOf(context).pushAndRemoveUntil<T>(
      MaterialPageRoute<T>(builder: (_) => page),
      (route) => route.isFirst,
    );
  }

  static Future<void> openPdgid(BuildContext context, String pdgid) async {
    await push(context, EntryRoutePage(pdgid: pdgid));
  }

  static Future<void> openReference(BuildContext context, int referenceId) async {
    await push(context, ReferencePage(referenceId: referenceId));
  }
}
