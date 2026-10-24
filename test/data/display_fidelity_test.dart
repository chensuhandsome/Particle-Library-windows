import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/data/sql_executor.dart';
import 'package:pdgapp/domain/display.dart';
import 'package:pdgapp/domain/models.dart';

/// The number a display string starts with, including its power of ten, or
/// null when the text is not a plain number (a range, a pole, a word).
double? leadingDisplayedValue(String text) {
  // A range is not one number (its stored value is not a bound), nor is a
  // pole or a word such as "seen".
  if (text.contains(' to ') ||
      text.contains('--') ||
      RegExp(r'i\s*\(').hasMatch(text) ||
      RegExp(r'[A-Za-z]{3}').hasMatch(text.split('×').first)) {
    return null;
  }
  final body = text.replaceFirst(RegExp(r'^[<>≤≥~\s(]+'), '');
  final match = RegExp(r'^[-+]?(\d+\.?\d*|\.\d+)').firstMatch(body);
  if (match == null) return null;
  final mantissa = double.parse(match.group(1)!);
  const digits = '⁰¹²³⁴⁵⁶⁷⁸⁹';
  final power = RegExp(r'×10([⁰¹²³⁴⁵⁶⁷⁸⁹⁻⁺]+)').allMatches(text).lastOrNull;
  if (power == null) return mantissa;
  var exponent = 0;
  var negative = false;
  for (final unit in power.group(1)!.split('')) {
    if (unit == '⁻') {
      negative = true;
    } else if (unit != '⁺') {
      exponent = exponent * 10 + digits.indexOf(unit);
    }
  }
  return mantissa * math.pow(10.0, negative ? -exponent : exponent);
}

void main() {
  late DirectSqlExecutor executor;

  setUpAll(() async {
    final snapshot = File('assets/pdgall-2026.0.sqlite');
    if (!snapshot.existsSync()) {
      fail(
        'Snapshot asset missing; this suite must run against the real pdgall file.',
      );
    }
    executor = await DirectSqlExecutor.open(snapshot.path);
  });

  tearDownAll(() async => executor.dispose());

  Future<Map<int, String>> textsFor(List<int> ids) async {
    final rows = await executor.select(
      'SELECT * FROM pdgdata WHERE id IN (${ids.join(',')})',
    );
    return {
      for (final row in rows)
        row['id']! as int: DisplayQuantity.fromSummary(Summary(row)).text,
    };
  }

  test(
    'limits that PDG stores with a wrong power of ten show the true value',
    () async {
      final texts = await textsFor([
        332843, // S003EDM electron EDM
        333573, // S066MGM neutrino magnetic moment
        335533, // K0S -> 3 pi0
        335535, // K0S -> e+ e-
        348188, // proton lifetime, n -> invisible
        348189, // proton lifetime, p p -> invisible
        351891, // S063R00
      ]);
      expect(texts[332843], '<4.1×10⁻³⁰ e cm');
      expect(texts[333573], '<6.4×10⁻¹² mu(B)');
      expect(texts[335533], '<2.6×10⁻⁸');
      expect(texts[335535], '<9×10⁻⁹');
      expect(texts[348188], '>6.×10²⁸ years');
      expect(texts[348189], '>11×10²⁸ years');
      expect(texts[351891], '<2.3×10⁻⁹');
    },
  );

  test('ranges show both bounds', () async {
    final texts = await textsFor([332898, 332899, 334097, 345479]);
    expect(texts[332898], '-1.85×10⁻¹⁷ to 6.1×10⁻¹⁸ e cm');
    expect(texts[332899], '-1.03×10⁻¹⁷ to 2.3×10⁻¹⁸ e cm');
    expect(texts[334097], '5×10⁻⁷ to 3.5×10⁻⁶');
    expect(texts[345479], '1.2×10⁻⁴ to 2.4×10⁻⁴');
  });

  test('asymmetric errors carry the power of ten as a group', () async {
    final texts = await textsFor([332546, 335632, 340766]);
    expect(texts[332546], '(3.51+0.23-0.25)×10⁻³');
    expect(texts[335632], '(0.09+.06-.04)×10⁻¹⁰');
    expect(texts[340766], '(0.3+.5-.4)×10⁻⁶');
  });

  test('every current-edition number is displayed at the scale of its stored value', () async {
    final rows = await executor.select(
      "SELECT * FROM pdgdata WHERE edition = '2026' AND value IS NOT NULL "
      'AND value != 0 AND display_in_percent = 0',
    );
    final wrong = <String>[];
    var checked = 0;
    for (final row in rows) {
      final summary = Summary(row);
      final text = DisplayQuantity.fromSummary(summary).text;
      final shown = leadingDisplayedValue(text);
      if (shown == null || shown == 0) continue;
      checked++;
      final stored = summary.value!.abs();
      if ((math.log(shown / stored) / math.ln10).abs() > 0.5) {
        wrong.add(
          '${summary.id} ${summary.pdgid} "${summary.valueText}" '
          'shows "$text" for value ${summary.value}',
        );
      }
    }
    expect(checked, greaterThan(10000));
    expect(wrong, isEmpty, reason: wrong.take(20).join('\n'));
  });
}
