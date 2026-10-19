import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app_scope.dart';
import 'app_strings.dart';
import 'debug_hooks.dart';
import 'app_theme.dart';
import 'update_checker.dart';
import '../features/common/page.dart';
import '../features/common/ui.dart';
import '../features/catalog/catalog_page.dart';
import '../features/favorites/favorites_page.dart';
import '../features/home/home_page.dart';
import '../features/notes/notes_page.dart';
import '../features/settings/settings_page.dart';
import '../features/help/help_page.dart';
import '../features/reference/inspire_search_page.dart';
import '../features/reviews/reviews_page.dart';

/// Primary destinations plus Settings, which is opened from the macOS app menu.
///
/// Keeping the enum order authoritative means the IndexedStack, tabs and
/// shortcuts stay aligned. Settings deliberately has no tab of its own.
enum AppTab { search, favorites, notes, settings }

const Map<AppTab, Widget> _pages = <AppTab, Widget>{
  AppTab.search: HomePage(),
  AppTab.favorites: FavoritesPage(),
  AppTab.notes: NotesPage(),
  AppTab.settings: SettingsPage(),
};

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const MethodChannel _menuChannel = MethodChannel('pdg.menu');
  static const List<LogicalKeyboardKey> _tabKeys = <LogicalKeyboardKey>[
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
  ];

  int _index = AppTab.search.index;
  final List<bool> _built = [true, false, false, false];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _menuChannel.setMethodCallHandler(_handleMenuCall);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForUpdates());
    });
  }

  Future<void> _checkForUpdates() async {
    if (!UpdateChecker.isConfigured) return;
    final scope = AppScope.of(context);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (scope.store.settings.lastUpdateCheck == today) return;
    try {
      final update = await UpdateChecker.check();
      if (!mounted || update == null) return;
      await showUpdateAvailableDialog(
        context,
        AppScope.of(context).strings,
        update,
      );
    } catch (_) {
      // An update check must never block startup or show a network error.
    }
  }

  Future<void> _handleMenuCall(MethodCall call) async {
    if (!mounted) return;
    if (call.method == 'showHelp') {
      await Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const HelpPage()));
    } else if (call.method == 'showSettings') {
      _select(AppTab.settings.index);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    debugTabHook = _select;
  }

  @override
  void dispose() {
    _menuChannel.setMethodCallHandler(null);
    if (debugTabHook != null) debugTabHook = null;
    super.dispose();
  }

  void _select(int index) {
    if (!mounted) return;
    if (index < 0 || index >= AppTab.values.length) return;
    if (index == _index) return;
    setState(() {
      _index = index;
      _built[index] = true;
    });
  }

  Map<ShortcutActivator, VoidCallback> _shortcuts() {
    final bindings = <ShortcutActivator, VoidCallback>{};
    for (final tab in AppTab.values) {
      final key = _tabKeys[tab.index];
      bindings[SingleActivator(key, meta: true)] = () => _select(tab.index);
      bindings[SingleActivator(key, control: true)] = () => _select(tab.index);
    }
    bindings[const SingleActivator(
      LogicalKeyboardKey.comma,
      meta: true,
    )] = () =>
        _select(AppTab.settings.index);
    bindings[const SingleActivator(
      LogicalKeyboardKey.comma,
      control: true,
    )] = () =>
        _select(AppTab.settings.index);
    void newNote() {
      _select(AppTab.notes.index);
      AppScope.of(context).noteRequests.value++;
    }

    bindings[const SingleActivator(LogicalKeyboardKey.keyN, meta: true)] =
        newNote;
    bindings[const SingleActivator(LogicalKeyboardKey.keyN, control: true)] =
        newNote;
    return bindings;
  }

  List<_TabSpec> _tabSpecs(AppStrings strings) => <_TabSpec>[
    _TabSpec(
      tab: AppTab.search,
      label: strings.navQuery,
      icon: Icons.search,
      selectedIcon: Icons.search,
    ),
    _TabSpec(
      tab: AppTab.favorites,
      label: strings.navFavorites,
      icon: Icons.star_border,
      selectedIcon: Icons.star,
    ),
    _TabSpec(
      tab: AppTab.notes,
      label: strings.navNotes,
      icon: Icons.sticky_note_2_outlined,
      selectedIcon: Icons.sticky_note_2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final strings = scope.strings;
    final palette = context.palette;
    final specs = _tabSpecs(strings);
    return CallbackShortcuts(
      bindings: _shortcuts(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textScale = MediaQuery.textScalerOf(context).scale(1.0);
          // Four primary tabs need a little more room than the previous
          // three-tab layout before the compact NavigationBar takes over.
          final compact =
              constraints.maxWidth < 1000 * textScale.clamp(1.0, 1.3);
          return SelectionArea(
            child: Scaffold(
              backgroundColor: palette.background,
              body: Column(
                children: [
                  Material(
                    color: palette.surface,
                    child: SafeArea(
                      bottom: false,
                      child: Container(
                        height: compact ? 58 : 64,
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 12 : 20,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: palette.divider),
                          ),
                        ),
                        child: Row(
                          children: [
                            const BrandMark(size: 28),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    strings.appName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textScaler: MediaQuery.textScalerOf(context)
                                        .clamp(maxScaleFactor: 1.3),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                  ),
                                  if (!compact)
                                    Text(
                                      strings.appTagline,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textScaler: MediaQuery.textScalerOf(
                                        context,
                                      ).clamp(maxScaleFactor: 1.3),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: palette.textSecondary,
                                            fontSize: 11.5,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: Insets.m),
                            if (!compact)
                              IconButton(
                                tooltip: strings.navHome,
                                icon: const Icon(Icons.home_outlined, size: 20),
                                onPressed: () {
                                  AppScope.of(context).homeRequests.value++;
                                  _select(AppTab.search.index);
                                },
                              ),
                            if (!compact) ...[
                              const SizedBox(width: Insets.xxl),
                              for (final spec in specs)
                                _TopTab(
                                  label: spec.label,
                                  icon: spec.selectedIcon,
                                  selected: _index == spec.tab.index,
                                  onTap: () => _select(spec.tab.index),
                                ),
                            ],
                            const Spacer(),
                            if (!compact) ...[
                              IconButton(
                                tooltip: strings.catalogTitle,
                                icon: const Icon(
                                  Icons.account_tree_outlined,
                                  size: 19,
                                ),
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const CatalogPage(),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: strings.inspireSearchAction,
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const InspireSearchPage(),
                                  ),
                                ),
                                icon: SvgPicture.asset(
                                  'assets/brand/inspire.svg',
                                  width: 19,
                                  height: 19,
                                ),
                              ),
                              IconButton(
                                tooltip: strings.reviewsTitle,
                                icon: const Icon(
                                  Icons.menu_book_outlined,
                                  size: 19,
                                ),
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const ReviewsPage(),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: strings.settingsHelp,
                                icon: const Icon(Icons.help_outline, size: 19),
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const HelpPage(),
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: strings.navSettings,
                                icon: const Icon(Icons.tune, size: 19),
                                onPressed: () => _select(AppTab.settings.index),
                              ),
                              MetaChip(
                                'PDG ${scope.database.currentEdition}',
                                icon: Icons.data_object,
                                tone: BadgeTone.accent,
                                tooltip: strings.offlineLabel,
                              ),
                            ] else
                              PopupMenuButton<_CompactTopAction>(
                                tooltip: strings.moreActions,
                                onSelected: (action) {
                                  switch (action) {
                                    case _CompactTopAction.catalog:
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => const CatalogPage(),
                                        ),
                                      );
                                    case _CompactTopAction.inspire:
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const InspireSearchPage(),
                                        ),
                                      );
                                    case _CompactTopAction.reviews:
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => const ReviewsPage(),
                                        ),
                                      );
                                    case _CompactTopAction.help:
                                      Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => const HelpPage(),
                                        ),
                                      );
                                    case _CompactTopAction.settings:
                                      _select(AppTab.settings.index);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: _CompactTopAction.catalog,
                                    child: Text(strings.catalogTitle),
                                  ),
                                  PopupMenuItem(
                                    value: _CompactTopAction.inspire,
                                    child: Text(strings.inspireSearchAction),
                                  ),
                                  PopupMenuItem(
                                    value: _CompactTopAction.reviews,
                                    child: Text(strings.reviewsTitle),
                                  ),
                                  PopupMenuItem(
                                    value: _CompactTopAction.help,
                                    child: Text(strings.settingsHelp),
                                  ),
                                  PopupMenuItem(
                                    value: _CompactTopAction.settings,
                                    child: Text(strings.navSettings),
                                  ),
                                ],
                                icon: const Icon(Icons.more_vert, size: 20),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SafeArea(
                      top: false,
                      bottom: false,
                      child: IndexedStack(
                        index: _index,
                        children: <Widget>[
                          for (final tab in AppTab.values)
                            if (_built[tab.index])
                              _pages[tab]!
                            else
                              const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),
                  if (compact)
                    NavigationBar(
                      selectedIndex: _index,
                      onDestinationSelected: _select,
                      destinations: <NavigationDestination>[
                        for (final spec in specs)
                          NavigationDestination(
                            icon: Icon(spec.icon),
                            selectedIcon: Icon(spec.selectedIcon),
                            label: spec.label,
                          ),
                        NavigationDestination(
                          icon: const Icon(Icons.tune),
                          selectedIcon: const Icon(Icons.tune),
                          label: strings.navSettings,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.tab,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final AppTab tab;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _TopTab extends StatelessWidget {
  const _TopTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      selected: selected,
      button: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? palette.surfaceAlt : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? palette.divider : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: selected ? palette.primary : palette.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected ? palette.primary : palette.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _CompactTopAction { catalog, inspire, reviews, help, settings }
