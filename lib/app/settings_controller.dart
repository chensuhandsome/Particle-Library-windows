import 'package:flutter/material.dart';

import '../domain/labels.dart';
import '../user/user_store.dart';
import 'app_strings.dart';
import 'shortcuts.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this.store, {Locale? systemLocale})
    : _settings = store.settings,
      _systemLocale = systemLocale ?? const Locale('en');

  final UserStore store;
  AppSettings _settings;
  Locale _systemLocale;

  AppSettings get settings => _settings;
  Locale get systemLocale => _systemLocale;

  void updateSystemLocale(Locale locale) {
    if (_systemLocale == locale) return;
    _systemLocale = locale;
    notifyListeners();
  }

  TextLang get language {
    if (_settings.locale == 'zh') return TextLang.zh;
    if (_settings.locale == 'en') return TextLang.en;
    return _systemLocale.languageCode == 'zh' ? TextLang.zh : TextLang.en;
  }

  AppStrings get strings => AppStrings(language);

  Locale get materialLocale => _settings.locale == 'zh'
      ? const Locale('zh')
      : _settings.locale == 'en'
      ? const Locale('en')
      : Locale(language == TextLang.zh ? 'zh' : 'en');

  ThemeMode get themeMode => switch (_settings.theme) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  double get textScale => _settings.textScale;
  bool get detailedMode => _settings.detailedMode;
  String get sidebarMode => _settings.sidebarMode;
  String get noteLinkMode => _settings.noteLinkMode;
  bool get autoUpdateZoteroIndex => _settings.autoUpdateZoteroIndex;
  bool get zoteroEnabled => _settings.zoteroEnabled;

  void reloadFromStore() {
    _settings = store.settings;
    notifyListeners();
  }

  Future<void> setSidebarMode(String value) async {
    final normalized = value == 'always' || value == 'off' ? value : 'auto';
    if (_settings.sidebarMode == normalized) return;
    _settings = _settings.copyWith(sidebarMode: normalized);
    notifyListeners();
    await store.setSettings(_settings);
  }

  Future<void> setNoteLinkMode(String value) async {
    final normalized = value == 'sidebar' ? 'sidebar' : 'page';
    if (_settings.noteLinkMode == normalized) return;
    _settings = _settings.copyWith(noteLinkMode: normalized);
    notifyListeners();
    await store.setSettings(_settings);
  }

  Future<void> setAutoUpdateZoteroIndex(bool value) async {
    if (_settings.autoUpdateZoteroIndex == value) return;
    _settings = _settings.copyWith(autoUpdateZoteroIndex: value);
    notifyListeners();
    await store.setSettings(_settings);
  }

  /// Effective bindings for [command]: the user override if present, the
  /// platform defaults otherwise, or an empty list when the command is off.
  List<AppShortcutBinding> shortcutBindings(AppShortcutCommand command) {
    final raw = _settings.shortcuts[command.id];
    if (raw == null) return AppShortcuts.defaultsFor(command);
    if (raw == 'off') return const <AppShortcutBinding>[];
    final decoded = AppShortcutBinding.decode(raw);
    return decoded == null
        ? AppShortcuts.defaultsFor(command)
        : <AppShortcutBinding>[decoded];
  }

  bool shortcutIsCustom(AppShortcutCommand command) =>
      _settings.shortcuts.containsKey(command.id);

  bool shortcutIsDisabled(AppShortcutCommand command) =>
      _settings.shortcuts[command.id] == 'off';

  Future<void> setShortcut(
    AppShortcutCommand command,
    AppShortcutBinding? binding,
  ) async {
    final next = Map<String, String>.from(_settings.shortcuts);
    next[command.id] = binding?.encode() ?? 'off';
    _settings = _settings.copyWith(shortcuts: next);
    notifyListeners();
    await store.setSettings(_settings);
  }

  Future<void> resetShortcut(AppShortcutCommand command) async {
    if (!_settings.shortcuts.containsKey(command.id)) return;
    final next = Map<String, String>.from(_settings.shortcuts)
      ..remove(command.id);
    _settings = _settings.copyWith(shortcuts: next);
    notifyListeners();
    await store.setSettings(_settings);
  }

  Future<void> resetAllShortcuts() async {
    if (_settings.shortcuts.isEmpty) return;
    _settings = _settings.copyWith(shortcuts: const <String, String>{});
    notifyListeners();
    await store.setSettings(_settings);
  }

  Future<void> setZoteroEnabled(bool value) async {
    if (_settings.zoteroEnabled == value) return;
    _settings = _settings.copyWith(zoteroEnabled: value);
    notifyListeners();
    await store.setSettings(_settings);
  }

  Future<void> setDetailedMode(bool value) async {
    if (_settings.detailedMode == value) return;
    _settings = _settings.copyWith(detailedMode: value);
    notifyListeners();
    await store.setSettings(_settings);
  }

  Future<void> setTheme(String theme) async {
    if (_settings.theme == theme) return;
    _settings = _settings.copyWith(theme: theme);
    notifyListeners();
    await store.setSettings(_settings);
  }

  Future<void> setLocale(String locale) async {
    if (_settings.locale == locale) return;
    _settings = _settings.copyWith(locale: locale);
    notifyListeners();
    await store.setSettings(_settings);
  }

  Future<void> setTextScale(double scale) async {
    if ((_settings.textScale - scale).abs() < 0.001) return;
    _settings = _settings.copyWith(textScale: scale);
    notifyListeners();
    await store.setSettings(_settings);
  }

  /// Records the local day of the last successful automatic update check.
  Future<void> markUpdateChecked(String date) async {
    if (_settings.lastUpdateCheck == date) return;
    _settings = _settings.copyWith(lastUpdateCheck: date);
    notifyListeners();
    await store.setSettings(_settings);
  }
}
