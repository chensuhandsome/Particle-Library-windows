import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/app/shortcuts.dart';
import 'package:pdgapp/user/user_store.dart';

void main() {
  test('shortcut bindings round-trip through the persisted encoding', () {
    const binding = AppShortcutBinding(keyId: 49, meta: true, shift: true);
    final decoded = AppShortcutBinding.decode(binding.encode());
    expect(decoded, isNotNull);
    expect(decoded!.encode(), binding.encode());
    expect(decoded.meta, isTrue);
    expect(decoded.shift, isTrue);
    expect(decoded.control, isFalse);
    expect(decoded.alt, isFalse);
  });

  test('invalid persisted bindings are ignored', () {
    expect(AppShortcutBinding.decode('meta+not-a-key'), isNull);
    expect(AppShortcutBinding.decode('hyper+49'), isNull);
    expect(AppShortcutBinding.decode(''), isNull);
  });

  test('shortcut overrides survive settings JSON', () {
    const settings = AppSettings(
      shortcuts: {'search': 'meta+49', 'back': 'off'},
    );
    final restored = AppSettings.fromJson(settings.toJson());
    expect(restored.shortcuts['search'], 'meta+49');
    expect(restored.shortcuts['back'], 'off');
  });

  test('defaults keep the historical tab and back/forward keys', () {
    final search = AppShortcuts.defaultsFor(AppShortcutCommand.search).single;
    final back = AppShortcuts.defaultsFor(AppShortcutCommand.back);
    final forward = AppShortcuts.defaultsFor(AppShortcutCommand.forward);
    final activator = search.activator;
    expect(activator.trigger, LogicalKeyboardKey.digit1);
    expect(activator.meta, AppShortcuts.isMacOS);
    expect(activator.control, !AppShortcuts.isMacOS);
    expect(back, hasLength(2));
    expect(back.last.alt, isTrue);
    expect(back.last.keyId, LogicalKeyboardKey.arrowLeft.keyId);
    expect(forward, hasLength(2));
    expect(forward.last.keyId, LogicalKeyboardKey.arrowRight.keyId);
  });

  test('settings defaults include comma and the old digit-4 shortcut', () {
    final defaults = AppShortcuts.defaultsFor(AppShortcutCommand.settings);
    expect(defaults, hasLength(2));
    expect(defaults.first.keyId, LogicalKeyboardKey.comma.keyId);
    expect(defaults.last.keyId, LogicalKeyboardKey.digit4.keyId);
  });
  group('combinations that would take typing away', () {
    final z = LogicalKeyboardKey.keyZ.keyId;
    final left = LogicalKeyboardKey.arrowLeft.keyId;
    final f5 = LogicalKeyboardKey.f5.keyId;

    test('Shift or Alt with a letter is not usable', () {
      expect(AppShortcutBinding(keyId: z, shift: true).isUsable, isFalse);
      expect(AppShortcutBinding(keyId: z, alt: true).isUsable, isFalse);
      expect(AppShortcutBinding(keyId: z).isUsable, isFalse);
    });

    test('Command or Control with a letter is usable', () {
      expect(AppShortcutBinding(keyId: z, meta: true).isUsable, isTrue);
      expect(AppShortcutBinding(keyId: z, control: true).isUsable, isTrue);
      expect(
        AppShortcutBinding(keyId: z, control: true, shift: true).isUsable,
        isTrue,
      );
    });

    test('Alt or Shift with an arrow or function key is usable', () {
      expect(AppShortcutBinding(keyId: left, alt: true).isUsable, isTrue);
      expect(AppShortcutBinding(keyId: f5, shift: true).isUsable, isTrue);
    });

    test('the defaults are all usable', () {
      for (final command in AppShortcutCommand.values) {
        for (final binding in AppShortcuts.defaultsFor(command)) {
          expect(binding.isUsable, isTrue, reason: '$command ${binding.label()}');
        }
      }
    });

    test('a stored binding that would swallow typing is ignored', () {
      expect(AppShortcutBinding.decode('shift.$z'), isNull);
      expect(AppShortcutBinding.decode('shift+$z'), isNull);
      expect(AppShortcutBinding.decode('alt+$z'), isNull);
      expect(AppShortcutBinding.decode('alt+$left'), isNotNull);
      expect(AppShortcutBinding.decode('meta+$z'), isNotNull);
    });
  });
}
