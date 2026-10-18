import 'models.dart';

enum InclusionFilter { any, yes, no, unknown }

enum LimitFilter { any, point, upper, lower, range, exclusion }

/// Series-level measurement filters. A measurement is returned as a complete
/// group when at least one of its value rows satisfies every active filter;
/// all sibling values are still shown and the matching cells are highlighted.
class MeasurementFilter {
  const MeasurementFilter({
    this.average = InclusionFilter.any,
    this.fit = InclusionFilter.any,
    this.limit = LimitFilter.any,
    this.changebarOnly = false,
  });

  final InclusionFilter average;
  final InclusionFilter fit;
  final LimitFilter limit;
  final bool changebarOnly;

  bool get isEmpty =>
      average == InclusionFilter.any &&
      fit == InclusionFilter.any &&
      limit == LimitFilter.any &&
      !changebarOnly;

  bool matchesValue(MeasurementValue value) {
    if (average != InclusionFilter.any &&
        !_matchesInclusion(value.usedInAverage, average)) {
      return false;
    }
    if (fit != InclusionFilter.any && !_matchesInclusion(value.usedInFit, fit)) {
      return false;
    }
    return _matchesLimit(value.limitType, limit);
  }

  bool matchesMeasurement(Measurement measurement, List<MeasurementValue> values) {
    if (changebarOnly && !measurement.changebar) return false;
    if (average == InclusionFilter.any &&
        fit == InclusionFilter.any &&
        limit == LimitFilter.any) {
      return true;
    }
    return values.any(matchesValue);
  }

  static bool _matchesInclusion(bool? actual, InclusionFilter filter) {
    return switch (filter) {
      InclusionFilter.any => true,
      InclusionFilter.yes => actual == true,
      InclusionFilter.no => actual == false,
      InclusionFilter.unknown => actual == null,
    };
  }

  static bool _matchesLimit(String? actual, LimitFilter filter) {
    return switch (filter) {
      LimitFilter.any => true,
      LimitFilter.point => actual == null || actual.isEmpty,
      LimitFilter.upper => actual == 'U',
      LimitFilter.lower => actual == 'L',
      LimitFilter.range => actual == 'R',
      LimitFilter.exclusion => actual == 'X',
    };
  }

  MeasurementFilter copyWith({
    InclusionFilter? average,
    InclusionFilter? fit,
    LimitFilter? limit,
    bool? changebarOnly,
  }) =>
      MeasurementFilter(
        average: average ?? this.average,
        fit: fit ?? this.fit,
        limit: limit ?? this.limit,
        changebarOnly: changebarOnly ?? this.changebarOnly,
      );
}
