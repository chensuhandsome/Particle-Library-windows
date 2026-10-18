import '../../domain/display.dart';
import '../../domain/models.dart';

/// One numeric point in a plot.
class PlotPoint {
  const PlotPoint({
    required this.x,
    required this.xLabel,
    required this.y,
    required this.summary,
    this.errorPlus,
    this.errorMinus,
    this.current = false,
  });

  final double x;
  final String xLabel;
  final double y;
  final Summary summary;
  final double? errorPlus;
  final double? errorMinus;
  final bool current;
}

/// A named series; a trend has one, a multi-particle comparison can have many.
class PlotSeries {
  const PlotSeries({
    required this.label,
    required this.unit,
    required this.points,
  });

  final String label;
  final String unit;
  final List<PlotPoint> points;
}

/// A chart-ready set of series plus the rows that could not be plotted.
class PlotData {
  const PlotData({
    required this.series,
    this.skippedAmbiguous = 0,
    this.skippedLimits = 0,
    this.skippedMissing = 0,
    this.unitMismatch = false,
  });

  final List<PlotSeries> series;
  final int skippedAmbiguous;
  final int skippedLimits;
  final int skippedMissing;
  final bool unitMismatch;

  bool get hasTrend =>
      series.isNotEmpty && series.first.points.length >= 2 && !unitMismatch;

  List<PlotPoint> get points =>
      series.isEmpty ? const <PlotPoint>[] : series.first.points;
}

/// Builds a trend from the pdgdata history rows of one series.
///
/// For every edition exactly one unambiguous summary is plotted. Rows with
/// limits, no numeric value, or fewer/more than one detached summary are not
/// silently mixed into the trend.
PlotData buildEditionTrend(
  List<Summary> summaries, {
  required String label,
  String? currentEdition,
}) {
  final byEdition = <String, List<Summary>>{};
  for (final row in summaries) {
    final edition = row.edition;
    if (edition == null || edition.isEmpty) continue;
    byEdition.putIfAbsent(edition, () => []).add(row);
  }
  final editions = byEdition.keys.toList()
    ..sort((a, b) {
      final ai = int.tryParse(a);
      final bi = int.tryParse(b);
      if (ai != null && bi != null) return ai.compareTo(bi);
      return a.compareTo(b);
    });

  final points = <PlotPoint>[];
  var skippedAmbiguous = 0;
  var skippedLimits = 0;
  var skippedMissing = 0;
  final units = <String>{};
  for (final edition in editions) {
    final rows = byEdition[edition]!;
    final selection = selectBestSummary(rows);
    final summary = selection.preferred;
    if (summary == null) {
      skippedAmbiguous++;
      continue;
    }
    if (summary.limitType != null) {
      skippedLimits++;
      continue;
    }
    final year = int.tryParse(edition);
    final value = summary.value;
    if (year == null || value == null || !value.isFinite) {
      skippedMissing++;
      continue;
    }
    final percent = summary.displayInPercent;
    final scale = percent ? 100.0 : 1.0;
    final plotValue = value * scale;
    final unit = percent ? '%' : summary.unitText.trim();
    if (unit.isNotEmpty) units.add(unit);
    final plus = summary.errorPositive;
    final minus = summary.errorNegative;
    points.add(PlotPoint(
      x: year.toDouble(),
      xLabel: edition,
      y: plotValue,
      summary: summary,
      errorPlus:
          plus != null && plus.isFinite && plus > 0 ? plus * scale : null,
      errorMinus:
          minus != null && minus.isFinite && minus > 0 ? minus * scale : null,
      current: edition == currentEdition,
    ));
  }

  final unitMismatch = units.length > 1;
  final unit = units.length == 1 ? units.first : (units.isEmpty ? '' : '');
  final series = points.isEmpty || unitMismatch
      ? const <PlotSeries>[]
      : <PlotSeries>[
          PlotSeries(label: label, unit: unit, points: List.unmodifiable(points)),
        ];
  return PlotData(
    series: series,
    skippedAmbiguous: skippedAmbiguous,
    skippedLimits: skippedLimits,
    skippedMissing: skippedMissing,
    unitMismatch: unitMismatch,
  );
}
