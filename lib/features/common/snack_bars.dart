import 'package:flutter/material.dart';

/// One duration for every action snack bar, so undo stays predictable.
const Duration actionSnackBarDuration = Duration(seconds: 4);

/// Shows a snack bar with a single action and a fixed dismissal behavior.
///
/// Flutter defaults [SnackBar.persist] to `true` whenever the snack bar has an
/// action, which makes [SnackBar.duration] ineffective. Passing
/// `persist: false` explicitly is what makes the undo bar disappear on its
/// own. Keeping that decision here prevents call sites from drifting apart.
void showActionSnackBar(
  ScaffoldMessengerState messenger, {
  required String message,
  required String actionLabel,
  required VoidCallback onAction,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: actionSnackBarDuration,
        persist: false,
        showCloseIcon: false,
        action: SnackBarAction(label: actionLabel, onPressed: onAction),
      ),
    );
}

/// Shows an undo snack bar with the shared action-snack-bar behavior.
void showUndoSnackBar(
  ScaffoldMessengerState messenger, {
  required String message,
  required String undoLabel,
  required VoidCallback onUndo,
}) {
  showActionSnackBar(
    messenger,
    message: message,
    actionLabel: undoLabel,
    onAction: onUndo,
  );
}
