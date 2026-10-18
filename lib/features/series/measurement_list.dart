import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_theme.dart';
import '../../domain/filters.dart';
import '../../domain/models.dart';
import '../common/async_view.dart';
import '../common/ui.dart';
import 'measurement_card.dart';

class MeasurementList extends StatefulWidget {
  const MeasurementList({
    super.key,
    required this.entry,
    this.initialFilter = const MeasurementFilter(),
    this.compact = false,
  });

  final Entry entry;
  final MeasurementFilter initialFilter;
  final bool compact;

  @override
  State<MeasurementList> createState() => _MeasurementListState();
}

class _MeasurementListState extends State<MeasurementList> {
  late MeasurementFilter _filter = widget.initialFilter;
  final List<MeasurementBundle> _items = [];
  MeasurementCursor? _cursor;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;
  int _total = 0;
  int _generation = 0;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _load(reset: true);
  }

  @override
  void didUpdateWidget(covariant MeasurementList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.id != widget.entry.id) {
      _load(reset: true);
    }
  }

  Future<void> _load({required bool reset}) async {
    final generation = ++_generation;
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _items.clear();
        _cursor = null;
        _hasMore = false;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final page = await AppScope.of(context).repository.measurements(
        widget.entry,
        cursor: reset ? null : _cursor,
        filter: _filter,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        if (reset) _items.clear();
        _items.addAll(page.items);
        _cursor = page.cursor;
        _hasMore = page.hasMore;
        _total = page.totalCount;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = error;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _setFilter(MeasurementFilter filter) {
    setState(() => _filter = filter);
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterBar(
          filter: _filter,
          onChanged: _setFilter,
          totalLabel: strings.measurementCount(_total),
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Insets.xl),
            child: Center(child: LoadingPanel()),
          )
        else if (_error != null && _items.isEmpty)
          ErrorPanel(error: _error!, onRetry: () => _load(reset: true))
        else if (_items.isEmpty)
          EmptyPanel(
            message: strings.seriesNoMeasurements,
            icon: Icons.table_rows_outlined,
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(Insets.l, 0, Insets.l, Insets.s),
            child: Row(
              children: [
                Text(
                  strings.showingMeasurements(_items.length, _total),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: palette.textSecondary),
                ),
                const Spacer(),
                if (_loadingMore)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          for (final bundle in _items)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.l,
                0,
                Insets.l,
                Insets.m,
              ),
              child: MeasurementCard(
                bundle: bundle,
                filter: _filter,
                showFilterHighlight: !_filter.isEmpty,
                compact: widget.compact,
                seriesLabel: widget.entry.description,
              ),
            ),
          if (_hasMore)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.l,
                0,
                Insets.l,
                Insets.l,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _loadingMore ? null : () => _load(reset: false),
                  icon: const Icon(Icons.expand_more, size: 18),
                  label: Text(strings.seriesLoadMore),
                ),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Insets.l,
                0,
                Insets.l,
                Insets.l,
              ),
              child: ErrorPanel(
                error: _error!,
                compact: true,
                onRetry: () => _load(reset: false),
              ),
            ),
        ],
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.onChanged,
    required this.totalLabel,
  });

  final MeasurementFilter filter;
  final ValueChanged<MeasurementFilter> onChanged;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final strings = scope.strings;
    final detailed = scope.settings.detailedMode;
    final palette = context.palette;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(Insets.l, 0, Insets.l, Insets.m),
      padding: const EdgeInsets.all(Insets.m),
      decoration: BoxDecoration(
        color: palette.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Insets.m,
            runSpacing: Insets.s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Dropdown<InclusionFilter>(
                label: strings.seriesFilterAverage,
                value: filter.average,
                options: const {
                  InclusionFilter.any: 'any',
                  InclusionFilter.yes: 'yes',
                  InclusionFilter.no: 'no',
                  InclusionFilter.unknown: 'unknown',
                },
                labelFor: (value) => switch (value) {
                  InclusionFilter.any => strings.seriesFilterAny,
                  InclusionFilter.yes => strings.seriesFilterYes,
                  InclusionFilter.no => strings.seriesFilterNo,
                  InclusionFilter.unknown => strings.seriesFilterUnknown,
                },
                onChanged: (value) =>
                    onChanged(filter.copyWith(average: value)),
              ),
              _Dropdown<InclusionFilter>(
                label: strings.seriesFilterFit,
                value: filter.fit,
                options: const {
                  InclusionFilter.any: 'any',
                  InclusionFilter.yes: 'yes',
                  InclusionFilter.no: 'no',
                  InclusionFilter.unknown: 'unknown',
                },
                labelFor: (value) => switch (value) {
                  InclusionFilter.any => strings.seriesFilterAny,
                  InclusionFilter.yes => strings.seriesFilterYes,
                  InclusionFilter.no => strings.seriesFilterNo,
                  InclusionFilter.unknown => strings.seriesFilterUnknown,
                },
                onChanged: (value) => onChanged(filter.copyWith(fit: value)),
              ),
              _Dropdown<LimitFilter>(
                label: strings.seriesFilterLimit,
                value: filter.limit,
                options: const {
                  LimitFilter.any: 'any',
                  LimitFilter.point: 'point',
                  LimitFilter.upper: 'upper',
                  LimitFilter.lower: 'lower',
                  LimitFilter.range: 'range',
                  LimitFilter.exclusion: 'exclusion',
                },
                labelFor: (value) => switch (value) {
                  LimitFilter.any => strings.seriesFilterAny,
                  LimitFilter.point => strings.seriesFilterPoint,
                  LimitFilter.upper => strings.seriesFilterUpper,
                  LimitFilter.lower => strings.seriesFilterLower,
                  LimitFilter.range => strings.seriesFilterRange,
                  LimitFilter.exclusion => strings.seriesFilterExclusion,
                },
                onChanged: (value) => onChanged(filter.copyWith(limit: value)),
              ),
              FilterChip(
                label: Text(strings.seriesFilterChanged),
                selected: filter.changebarOnly,
                onSelected: (value) =>
                    onChanged(filter.copyWith(changebarOnly: value)),
              ),
              Text(
                totalLabel,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: palette.textSecondary),
              ),
            ],
          ),
          if (detailed) ...[
            const SizedBox(height: 6),
            Text(
              strings.seriesFilterHint,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: palette.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final String Function(T) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 178,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isDense: true,
            isExpanded: true,
            items: [
              for (final option in options.keys)
                DropdownMenuItem<T>(
                  value: option,
                  child: Text(labelFor(option)),
                ),
            ],
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ),
      ),
    );
  }
}
