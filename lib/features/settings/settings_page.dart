import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_scope.dart';
import '../../app/app_theme.dart';
import 'zotero_cache_section.dart';
import '../../data/pdg_database.dart';
import '../../domain/labels.dart';
import '../common/page.dart';
import '../common/raw_fields.dart';
import '../common/ui.dart';
import '../help/help_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<SnapshotStats> _statsFuture;
  Future<List<TableStat>>? _tablesFuture;
  bool _backingUpNotes = false;
  bool _showTables = false;
  bool _showCodes = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _statsFuture = AppScope.of(context).database.snapshotStats();
  }

  Future<void> _backupNotes() async {
    final notes = AppScope.of(context).notes;
    if (notes == null || _backingUpNotes) return;
    final strings = AppScope.of(context).strings;
    setState(() => _backingUpNotes = true);
    try {
      final dbPath = notes.storagePath;
      final parent = Directory(dbPath).parent;
      final backups = Directory('${parent.path}/backups');
      if (!await backups.exists()) await backups.create(recursive: true);
      final stamp = DateTime.now().toIso8601String().replaceAll(
        RegExp(r'[:.]'),
        '-',
      );
      final destination = File('${backups.path}/notes-$stamp.db');
      await notes.backupTo(destination.path);
      final existing =
          backups
              .listSync()
              .whereType<File>()
              .where((file) => file.path.endsWith('.db'))
              .toList()
            ..sort(
              (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
            );
      for (final old in existing.skip(5)) {
        try {
          await old.delete();
        } catch (_) {}
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${strings.settingsNotesBackupDone}: ${destination.path}',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${strings.settingsNotesBackupFailed}: $error')),
      );
    } finally {
      if (mounted) setState(() => _backingUpNotes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final strings = scope.strings;
    final settings = scope.settings;
    final info = scope.database.info;
    final palette = context.palette;
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.only(bottom: Insets.xxl),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.l,
                Insets.l,
                Insets.l,
                Insets.s,
              ),
              child: Text(
                strings.settingsTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            if (scope.store.recoveryWarning != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Insets.l,
                  0,
                  Insets.l,
                  Insets.s,
                ),
                child: MetaChip(
                  scope.store.recoveryWarning!,
                  tone: BadgeTone.warning,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.l),
              child: SectionCard(
                title: strings.settingsAppearance,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SettingRow(
                      label: strings.settingsTheme,
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: 'system',
                            label: Text(strings.settingsThemeSystem),
                          ),
                          ButtonSegment(
                            value: 'light',
                            label: Text(strings.settingsThemeLight),
                          ),
                          ButtonSegment(
                            value: 'dark',
                            label: Text(strings.settingsThemeDark),
                          ),
                        ],
                        selected: {settings.settings.theme},
                        onSelectionChanged: (value) =>
                            settings.setTheme(value.first),
                      ),
                    ),
                    _SettingRow(
                      label: strings.settingsLanguage,
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: 'system',
                            label: Text(strings.settingsLanguageSystem),
                          ),
                          ButtonSegment(
                            value: 'zh',
                            label: Text(strings.settingsLanguageZh),
                          ),
                          ButtonSegment(
                            value: 'en',
                            label: Text(strings.settingsLanguageEn),
                          ),
                        ],
                        selected: {settings.settings.locale},
                        onSelectionChanged: (value) =>
                            settings.setLocale(value.first),
                      ),
                    ),
                    _SettingRow(
                      label: strings.settingsTextSize,
                      child: SegmentedButton<double>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: 1.0,
                            label: Text(strings.settingsTextSizeStandard),
                          ),
                          ButtonSegment(
                            value: 1.15,
                            label: Text(strings.settingsTextSizeLarge),
                          ),
                          ButtonSegment(
                            value: 1.3,
                            label: Text(strings.settingsTextSizeLargest),
                          ),
                        ],
                        selected: {settings.settings.textScale},
                        onSelectionChanged: (value) =>
                            settings.setTextScale(value.first),
                      ),
                    ),
                    Text(
                      strings.settingsTextSizeHint,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: palette.textSecondary),
                    ),
                    const SizedBox(height: Insets.s),
                    _SettingRow(
                      label: strings.settingsDetailedMode,
                      child: Switch(
                        value: settings.detailedMode,
                        onChanged: (value) => settings.setDetailedMode(value),
                      ),
                    ),
                    Text(
                      strings.settingsDetailedModeHint,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: palette.textSecondary),
                    ),
                    const SizedBox(height: Insets.s),
                    _SettingRow(
                      label: strings.settingsSidebarMode,
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: 'auto',
                            label: Text(strings.settingsSidebarAuto),
                          ),
                          ButtonSegment(
                            value: 'always',
                            label: Text(strings.settingsSidebarAlways),
                          ),
                          ButtonSegment(
                            value: 'off',
                            label: Text(strings.settingsSidebarOff),
                          ),
                        ],
                        selected: {settings.sidebarMode},
                        onSelectionChanged: (value) =>
                            settings.setSidebarMode(value.first),
                      ),
                    ),
                    Text(
                      strings.settingsSidebarHint,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: palette.textSecondary),
                    ),
                    const SizedBox(height: Insets.s),
                    _SettingRow(
                      label: strings.settingsNoteLinkMode,
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: 'page',
                            label: Text(strings.settingsNoteLinkPage),
                          ),
                          ButtonSegment(
                            value: 'sidebar',
                            label: Text(strings.settingsNoteLinkSidebar),
                          ),
                        ],
                        selected: {settings.noteLinkMode},
                        onSelectionChanged: (value) =>
                            settings.setNoteLinkMode(value.first),
                      ),
                    ),
                    Text(
                      strings.settingsNoteLinkHint,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Insets.m),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.l),
              child: SectionCard(
                title: strings.settingsHelp,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const HelpPage()),
                    ),
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: Text(strings.helpTitle),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Insets.m),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.l),
              child: SectionCard(
                title: strings.settingsData,
                trailing: IconButton(
                  tooltip: strings.settingsCopyHash,
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  onPressed: () => copyText(context, scope.snapshotHash),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DataField(
                      label: strings.settingsSnapshotVersion,
                      value: 'PDG ${info.edition ?? ''}',
                    ),
                    DataField(
                      label: strings.settingsSchema,
                      value: info.schemaVersion ?? '',
                      monospace: true,
                    ),
                    DataField(
                      label: strings.settingsRelease,
                      value: info.releaseTimestamp ?? '',
                      monospace: false,
                    ),
                    DataField(
                      label: strings.settingsHash,
                      value: scope.snapshotHash,
                      monospace: true,
                    ),
                    DataField(
                      label: strings.settingsAppVersion,
                      value: '0.1.0',
                      monospace: true,
                    ),
                    DataField(
                      label: strings.commonSource,
                      value: info.producer ?? '',
                      monospace: false,
                    ),
                    DataField(
                      label: 'license',
                      value: info.license ?? '',
                      monospace: false,
                    ),
                    if (info.citation != null)
                      DataField(
                        label: 'citation',
                        value: plainCitation(info.citation),
                        monospace: false,
                      ),
                    const SizedBox(height: Insets.s),
                    RawFieldsPanel(fields: info.rawFields, title: 'pdginfo'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Insets.m),
            const ZoteroCacheSection(),
            const SizedBox(height: Insets.m),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.l),
              child: SectionCard(
                title: strings.settingsStorage,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DataField(
                      label: strings.settingsSnapshotFile,
                      value: _fileName(scope.services.snapshotPath),
                      monospace: true,
                    ),
                    DataField(
                      label: 'user store',
                      value: _fileName(scope.store.storagePath ?? '—'),
                      monospace: true,
                    ),
                    if (scope.notes != null) ...[
                      const SizedBox(height: Insets.s),
                      OutlinedButton.icon(
                        onPressed: _backingUpNotes ? null : _backupNotes,
                        icon: const Icon(Icons.archive_outlined, size: 17),
                        label: Text(strings.settingsNotesBackup),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        strings.settingsNotesBackupHint,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: palette.textSecondary),
                      ),
                    ],
                    DataField(
                      label: strings.settingsClearRecents,
                      value: '${scope.store.recents.length}',
                    ),
                    DataField(
                      label: strings.favoritesTitle,
                      value: '${scope.store.favorites.length}',
                    ),
                    const SizedBox(height: Insets.s),
                    Text(
                      strings.settingsStorageHint,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: palette.textSecondary),
                    ),
                    const SizedBox(height: Insets.s),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            content: Text(strings.settingsClearRecentsConfirm),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(strings.commonCancel),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(strings.commonConfirm),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await scope.store.clearRecents();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(strings.settingsClearRecentsDone),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_sweep_outlined, size: 17),
                      label: Text(strings.settingsClearRecents),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Insets.m),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.l),
              child: SectionCard(
                title: strings.settingsTableStats,
                trailing: TextButton(
                  onPressed: () {
                    setState(() {
                      _showTables = !_showTables;
                      if (_showTables) {
                        _tablesFuture ??= AppScope.of(context).database
                            .tableStats();
                      }
                    });
                  },
                  child: Text(
                    _showTables
                        ? strings.commonShowLess
                        : strings.commonShowMore,
                  ),
                ),
                child: FutureBuilder<SnapshotStats>(
                  future: _statsFuture,
                  builder: (context, snapshot) {
                    final stats = snapshot.data;
                    if (stats == null) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(Insets.m),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: Insets.l,
                          runSpacing: Insets.s,
                          children: [
                            _Stat(
                              label: strings.entriesLabel,
                              value: stats.entries,
                            ),
                            _Stat(
                              label: strings.summariesLabel,
                              value: stats.currentSummaries,
                            ),
                            _Stat(
                              label: 'all pdgdata',
                              value: stats.allSummaries,
                            ),
                            _Stat(
                              label: strings.referencesLabel,
                              value: stats.references,
                            ),
                          ],
                        ),
                        if (_showTables) ...[
                          const SizedBox(height: Insets.m),
                          FutureBuilder<List<TableStat>>(
                            future: _tablesFuture,
                            builder: (context, snapshot) {
                              final tables = snapshot.data;
                              if (tables == null) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(Insets.s),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children: [
                                  for (final table in tables)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              table.table,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontFamily: 'Menlo',
                                                  ),
                                            ),
                                          ),
                                          Text(
                                            '${table.rows}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: Insets.m),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.l),
              child: SectionCard(
                title: strings.codeTableTitle,
                subtitle: strings.codeTableHint,
                trailing: TextButton(
                  onPressed: () => setState(() => _showCodes = !_showCodes),
                  child: Text(
                    _showCodes
                        ? strings.commonShowLess
                        : strings.commonShowMore,
                  ),
                ),
                child: _showCodes
                    ? Column(
                        children: [
                          for (final doc in scope.database.allDocs)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                      '${doc.tableName}.${doc.columnName}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontFamily: 'Menlo',
                                            fontSize: 11,
                                          ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 64,
                                    child: Text(
                                      doc.value ?? 'NULL',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      [
                                        if (doc.indicator.isNotEmpty)
                                          doc.indicator,
                                        doc.description,
                                      ].join(' — '),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      )
                    : Text(
                        '${scope.database.allDocs.length} ${strings.commonCount} · ${strings.codeTableHint}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: palette.textSecondary),
                      ),
              ),
            ),
            const SizedBox(height: Insets.m),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.l),
              child: SectionCard(
                title: strings.settingsAbout,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.settingsAboutText),
                    const SizedBox(height: Insets.s),
                    Text(
                      strings.settingsCoverageText,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: palette.textSecondary),
                    ),
                    const SizedBox(height: Insets.m),
                    Wrap(
                      spacing: Insets.s,
                      runSpacing: Insets.s,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _launch(
                            context,
                            'https://pdgapi.lbl.gov/doc/schema.html',
                          ),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: Text(strings.settingsPdgApi),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _launch(
                            context,
                            'https://creativecommons.org/licenses/by/4.0/',
                          ),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: Text(strings.settingsLicenseLink),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Insets.m),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.l),
              child: Text(
                '${strings.commonSnapshot}: ${scope.snapshotHash}',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: palette.textSecondary),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launch(BuildContext context, String url) async {
    final strings = AppScope.of(context).strings;
    try {
      final uri = Uri.parse(url);
      if (uri.scheme != 'https') return;
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(strings.commonError)));
      }
    }
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: context.palette.textSecondary),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(scrollDirection: Axis.horizontal, child: child),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: palette.textSecondary),
        ),
      ],
    );
  }
}

String _fileName(String path) {
  if (path == '—' || path.isEmpty) return '—';
  final normalized = path.replaceAll('\\', '/');
  final index = normalized.lastIndexOf('/');
  return index < 0 ? normalized : normalized.substring(index + 1);
}
