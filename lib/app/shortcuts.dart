import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Commands that can be triggered from anywhere in the app shell.
///
/// The ids are persisted in the user store; never rename them without a
/// migration. Defaults are intentionally platform-aware (Command on macOS,
/// Control elsewhere), while a recorded binding can use any modifiers.
enum AppShortcutCommand {
  search('search'),
  favorites('favorites'),
  notes('notes'),
  settings('settings'),
  newNote('new_note'),
  back('back'),
  forward('forward');

  const AppShortcutCommand(this.id);

  final String id;

  static AppShortcutCommand? fromId(String id) {
    for (final command in values) {
      if (command.id == id) return command;
    }
    return null;
  }
}

/// A serializable key combination.
///
/// [keyId] is [LogicalKeyboardKey.keyId], so the binding remains stable across
/// labels/locales. Stored values look like `meta+control+49`.
class AppShortcutBinding {
  const AppShortcutBinding({
    required this.keyId,
    this.meta = false,
    this.control = false,
    this.alt = false,
    this.shift = false,
  });

  final int keyId;
  final bool meta;
  final bool control;
  final bool alt;
  final bool shift;

  bool get hasModifier => meta || control || alt || shift;

  /// Whether the combination may be bound to an app command.
  ///
  /// Command/Control always may. With only Alt or Shift, a printable key would
  /// be taken away from every text field (Shift+Z is a capital Z, Option+key
  /// types a symbol), so only keys that print nothing (arrows, function keys;
  /// their ids lie above the Unicode range) qualify.
  bool get isUsable =>
      meta || control || ((alt || shift) && keyId > _lastUnicodeKeyId);

  static const int _lastUnicodeKeyId = 0x10ffff;

  SingleActivator get activator => SingleActivator(
    LogicalKeyboardKey(keyId),
    meta: meta,
    control: control,
    alt: alt,
    shift: shift,
  );

  String encode() => [
    if (meta) 'meta',
    if (control) 'control',
    if (alt) 'alt',
    if (shift) 'shift',
    '$keyId',
  ].join('+');

  static AppShortcutBinding? decode(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split('+');
    if (parts.isEmpty) return null;
    final keyId = int.tryParse(parts.last);
    if (keyId == null) return null;
    final modifiers = parts.take(parts.length - 1).toSet();
    if (modifiers.any(
      (m) => m != 'meta' && m != 'control' && m != 'alt' && m != 'shift',
    )) {
      return null;
    }
    final binding = AppShortcutBinding(
      keyId: keyId,
      meta: modifiers.contains('meta'),
      control: modifiers.contains('control'),
      alt: modifiers.contains('alt'),
      shift: modifiers.contains('shift'),
    );
    // A stored binding that would swallow typing (a settings file or backup
    // from elsewhere) is ignored, and the default applies.
    return binding.isUsable ? binding : null;
  }

  bool sameAs(AppShortcutBinding other) => encode() == other.encode();

  @override
  bool operator ==(Object other) =>
      other is AppShortcutBinding && encode() == other.encode();

  @override
  int get hashCode => encode().hashCode;

  /// Human-readable label, e.g. `⌘1` or `Ctrl+Shift+N`.
  String label({bool? macOS}) {
    final isMac = macOS ?? defaultTargetPlatform == TargetPlatform.macOS;
    final key = LogicalKeyboardKey(keyId);
    final keyText = _keyLabel(key);
    if (isMac) {
      return [
        if (control) '⌃',
        if (alt) '⌥',
        if (shift) '⇧',
        if (meta) '⌘',
        keyText,
      ].join();
    }
    return [
      if (control) 'Ctrl',
      if (alt) 'Alt',
      if (shift) 'Shift',
      if (meta) 'Meta',
      keyText,
    ].join('+');
  }

  static String _keyLabel(LogicalKeyboardKey key) {
    const special = <int, String>{
      32: 'Space',
      44: ',',
      46: '.',
      47: '/',
      59: ';',
      61: '=',
      91: '[',
      93: ']',
      96: '`',
      45: '-',
      39: "'",
    };
    final fixed = special[key.keyId];
    if (fixed != null) return fixed;
    final label = key.keyLabel;
    if (label.isNotEmpty && label != 'Unidentified') return label;
    return switch (key) {
      LogicalKeyboardKey.arrowLeft => '←',
      LogicalKeyboardKey.arrowRight => '→',
      LogicalKeyboardKey.arrowUp => '↑',
      LogicalKeyboardKey.arrowDown => '↓',
      LogicalKeyboardKey.escape => 'Esc',
      LogicalKeyboardKey.enter => 'Return',
      LogicalKeyboardKey.tab => 'Tab',
      LogicalKeyboardKey.backspace => '⌫',
      LogicalKeyboardKey.delete => '⌦',
      _ => 'Key ${key.keyId}',
    };
  }
}

/// Platform-aware defaults for the app shell.
abstract final class AppShortcuts {
  static bool get isMacOS => defaultTargetPlatform == TargetPlatform.macOS;

  static AppShortcutBinding _primary(int keyId) =>
      AppShortcutBinding(keyId: keyId, meta: isMacOS, control: !isMacOS);

  static List<AppShortcutBinding> defaultsFor(AppShortcutCommand command) {
    switch (command) {
      case AppShortcutCommand.search:
        return [_primary(LogicalKeyboardKey.digit1.keyId)];
      case AppShortcutCommand.favorites:
        return [_primary(LogicalKeyboardKey.digit2.keyId)];
      case AppShortcutCommand.notes:
        return [_primary(LogicalKeyboardKey.digit3.keyId)];
      case AppShortcutCommand.settings:
        // Preserve both historical settings shortcuts as defaults.
        return [
          _primary(LogicalKeyboardKey.comma.keyId),
          _primary(LogicalKeyboardKey.digit4.keyId),
        ];
      case AppShortcutCommand.newNote:
        return [_primary(LogicalKeyboardKey.keyN.keyId)];
      case AppShortcutCommand.back:
        return [
          _primary(LogicalKeyboardKey.bracketLeft.keyId),
          AppShortcutBinding(
            keyId: LogicalKeyboardKey.arrowLeft.keyId,
            alt: true,
          ),
        ];
      case AppShortcutCommand.forward:
        return [
          _primary(LogicalKeyboardKey.bracketRight.keyId),
          AppShortcutBinding(
            keyId: LogicalKeyboardKey.arrowRight.keyId,
            alt: true,
          ),
        ];
    }
  }

  static AppShortcutBinding primaryFor(int keyId) => _primary(keyId);
}
