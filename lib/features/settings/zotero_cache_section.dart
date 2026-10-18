import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_theme.dart';
import '../../data/zotero_cache.dart';
import '../common/ui.dart';

class ZoteroCacheSection extends StatefulWidget {
  const ZoteroCacheSection({super.key});

  @override
  State<ZoteroCacheSection> createState() => _ZoteroCacheSectionState();
}

class _ZoteroCacheSectionState extends State<ZoteroCacheSection> {
  ZoteroCacheIndex? _index;
  bool _loading = true;
  bool _building = false;
  int _fetched = 0;
  int _total = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final index = await ZoteroCacheIndex.load();
    if (!mounted) return;
    setState(() {
      _index = index;
      _loading = false;
    });
  }

  Future<void> _build() async {
    if (_building) return;
    setState(() {
      _building = true;
      _error = null;
      _fetched = 0;
      _total = 0;
    });
    try {
      final index = await ZoteroCacheBuilder.build(
        onProgress: (fetched, total) {
          if (!mounted) return;
          setState(() {
            _fetched = fetched;
            _total = total;
          });
        },
      );
      await index.save();
      if (!mounted) return;
      setState(() {
        _index = index;
        _building = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppScope.of(context).strings.settingsZoteroCacheDone),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _building = false;
        _error = '$error';
      });
    }
  }

  Future<void> _clear() async {
    final file = await ZoteroCacheIndex.defaultFile();
    if (await file.exists()) await file.delete();
    if (!mounted) return;
    setState(() => _index = null);
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Insets.l, 0, Insets.l, 0),
      child: SectionCard(
        title: strings.settingsZoteroCache,
        trailing: _building
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading)
              const LinearProgressIndicator(minHeight: 2)
            else if (_index == null)
              Text(
                strings.settingsZoteroCacheEmpty,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: palette.textSecondary),
              )
            else
              Text(
                strings.settingsZoteroCacheStatus(
                  _index!.indexedItems,
                  _formatDate(_index!.builtAt),
                ),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: palette.textSecondary),
              ),
            if (_building) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _total > 0 ? (_fetched / _total).clamp(0.0, 1.0) : null,
                minHeight: 3,
              ),
              const SizedBox(height: 4),
              Text(
                strings.settingsZoteroCacheBuilding(_fetched, _total),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: palette.textSecondary),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                '${strings.settingsZoteroCacheFailed}: $_error',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: palette.error),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                FilledButton.icon(
                  onPressed: _building || _loading ? null : _build,
                  icon: const Icon(Icons.sync, size: 16),
                  label: Text(
                    _index == null
                        ? strings.settingsZoteroCacheBuild
                        : strings.settingsZoteroCacheUpdate,
                  ),
                ),
                if (_index != null)
                  TextButton.icon(
                    onPressed: _building ? null : _clear,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: Text(strings.settingsZoteroCacheClear),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              strings.settingsZoteroCacheHint,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
