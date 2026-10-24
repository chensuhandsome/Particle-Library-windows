import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/domain/display.dart';
import 'package:pdgapp/domain/labels.dart';
import 'package:pdgapp/domain/models.dart';

Summary summary({
  int id = 1,
  String display = '1.23',
  String? valueText = '1.23',
  String unit = '',
  int power = 0,
  bool percent = false,
  String? limit,
  String valueType = 'AC',
  bool inSummaryTable = false,
  double? value = 1.23,
}) {
  return Summary({
    'id': id,
    'pdgid_id': 1,
    'pdgid': 'S000',
    'edition': '2026',
    'value_type': valueType,
    'in_summary_table': inSummaryTable ? 1 : 0,
    'confidence_level': null,
    'limit_type': limit,
    'comment': null,
    'value': value,
    'value_text': valueText,
    'error_positive': null,
    'error_negative': null,
    'scale_factor': null,
    'unit_text': unit,
    'display_value_text': display,
    'display_power_of_ten': power,
    'display_in_percent': percent ? 1 : 0,
    'sort': id,
  });
}

void main() {
  test('a truncated complex pole keeps the imaginary part', () {
    final quantity = DisplayQuantity.fromSummary(
      summary(
        display: '3874.75+-0.10',
        valueText: '(3874.75+-0.10) - i (0.024+0.001-0.007)',
        unit: 'MeV',
        value: null,
      ),
    );
    // The full pole is shown verbatim: never truncate to the real part.
    expect(quantity.numberText, '(3874.75 ± 0.10) - i (0.024+0.001-0.007)');
    expect(displayNumberNeedsMath(quantity.numberText), isTrue);
  });

  test('percent display does not stack the implied -2 power again', () {
    final quantity = DisplayQuantity.fromSummary(
      summary(
        display: '3.936+-0.030',
        power: -2,
        percent: true,
        value: 0.03936,
      ),
    );
    expect(quantity.text, '3.936 ± 0.030%');
    expect(quantity.text.contains('10'), isFalse);
  });

  test('percent stored as unit % is not doubled', () {
    final quantity = DisplayQuantity.fromSummary(
      summary(
        display: '12.5',
        valueText: '12.5',
        value: 12.5,
        unit: '%',
        percent: false,
      ),
    );
    expect(quantity.text, '12.5 %');
  });

  test('large power is restored once from the display fields', () {
    final quantity = DisplayQuantity.fromSummary(
      summary(
        display: '>14000',
        valueText: '> 14000 E30',
        unit: 'years',
        power: 30,
        limit: 'U',
        value: 1.4e34,
      ),
    );
    expect(quantity.text, '>14000×10³⁰ years');
    expect(quantity.isLimit, isTrue);
  });

  test('negative signed display keeps the ± conversion', () {
    final quantity = DisplayQuantity.fromSummary(
      summary(display: '1864.84+-0.04', unit: 'MeV'),
    );
    expect(quantity.text, '1864.84 ± 0.04 MeV');
  });

  test('best summary follows the strict official rule', () {
    final one = selectBestSummary([summary(id: 1)]);
    expect(one.preferred?.id, 1);

    final multipleOneTable = selectBestSummary([
      summary(id: 1, inSummaryTable: true, valueType: 'FC'),
      summary(id: 2, inSummaryTable: false, valueType: 'AC'),
    ]);
    expect(multipleOneTable.preferred?.id, 1);
    expect(multipleOneTable.isAmbiguous, isFalse);

    final multipleNoTable = selectBestSummary([
      summary(id: 1, valueType: 'FC'),
      summary(id: 2, valueType: 'AC'),
    ]);
    expect(multipleNoTable.preferred, isNull);
    expect(multipleNoTable.isAmbiguous, isTrue);
    expect(multipleNoTable.candidates.length, 2);

    final multipleTables = selectBestSummary([
      summary(id: 1, inSummaryTable: true),
      summary(id: 2, inSummaryTable: true),
    ]);
    expect(multipleTables.preferred, isNull);
    expect(multipleTables.candidates.length, 2);
  });

  test('summary value_type and measurement inclusion flags stay distinct', () {
    expect(valueTypeLabel('FC', TextLang.zh), contains('拟合'));
    expect(valueTypeLabel('FC', TextLang.zh), isNot(contains('用于')));
    expect(valueTypeLabel('AC', TextLang.zh), contains('平均'));
    expect(valueTypeShortLabel('AC', TextLang.en), 'PDG Average');
    expect(valueTypeShortLabel('FC', TextLang.en), 'PDG Fit');
    expect(valueTypeShortLabel('AC', TextLang.zh), contains('平均'));
    expect(valueTypeShortLabel('FC', TextLang.zh), contains('拟合'));
    expect(inclusionLabel(true, 'fit', TextLang.zh), contains('fit 标志'));
    expect(
      inclusionLabel(true, 'fit', TextLang.zh),
      isNot(contains('OUR FIT')),
    );
    expect(
      inclusionLabel(false, 'average', TextLang.zh),
      contains('average 标志'),
    );
    expect(inclusionLabel(null, 'average', TextLang.zh), contains('未注明'));
  });

  test('embedded and header exponents are combined', () {
    final lifetime = DisplayQuantity.fromSummary(
      summary(
        display: '(1637+-4)E-3',
        valueText: '(1637+-4)E-3',
        unit: 's',
        power: -12,
        value: 1.637e-12,
      ),
    );
    expect(lifetime.text, '(1637 ± 4)×10⁻¹⁵ s');
    expect(
      displayNumberLatex(lifetime.numberText),
      r'(1637 \pm 4)\times 10^{-15}',
    );

    final old = DisplayQuantity.fromSummary(
      summary(
        display: '(222.0+-2.0)E-2',
        valueText: '(222.0+-2.0)E-2',
        power: -6,
        value: 2.22e-6,
      ),
    );
    expect(old.text, '(222.0 ± 2.0)×10⁻⁸');
  });

  test('power of ten wraps a multi-term value', () {
    final quantity = DisplayQuantity.fromSummary(
      summary(
        display: '10.89+-0.01+-0.08',
        valueText: '(10.89+-0.01+-0.08) E-2',
        power: -2,
        value: 0.1089,
      ),
    );
    expect(quantity.text, '(10.89 ± 0.01 ± 0.08)×10⁻²');
    expect(
      displayNumberLatex(quantity.numberText),
      r'(10.89 \pm 0.01 \pm 0.08)\times 10^{-2}',
    );
  });

  test('unit already in number is not repeated', () {
    final quantity = DisplayQuantity.fromSummary(
      summary(
        display: 'none 1-9 GeV',
        valueText: 'none 1-9 GeV',
        unit: 'GeV',
        value: null,
      ),
    );
    expect(quantity.text, 'none 1-9 GeV');
  });

  test('E exponents become times ten', () {
    expect(displayNumberNeedsMath('(9 ± 5)E-5'), isTrue);
    expect(displayNumberLatex('(9 ± 5)E-5'), r'(9 \pm 5)\times 10^{-5}');
    final quantity = DisplayQuantity.fromSummary(
      summary(display: '(9+-5)E-5', valueText: '(9+-5)E-5', value: 9e-5),
    );
    expect(quantity.text, '(9 ± 5)×10⁻⁵');
  });

  test('a pole without parentheses keeps the full value', () {
    final quantity = DisplayQuantity.fromSummary(
      summary(
        display: '517- i 240',
        valueText: '517- i 240',
        unit: 'MeV',
        value: null,
      ),
    );
    expect(quantity.numberText, '517- i 240');
    expect(displayNumberNeedsMath(quantity.numberText), isTrue);
  });

  test('complex values and units get readable math', () {
    expect(displayNumberNeedsMath('5.3 +0.9-0.7'), isTrue);
    expect(displayNumberLatex('5.3 +0.9-0.7'), r'5.3\;{}^{+0.9}_{-0.7}');
    expect(
      displayNumberLatex('(445 ± 25)- i(278 +22-18)'),
      r'(445 \pm 25) - i\,(278\;{}^{+22}_{-18})',
    );
    expect(prettyUnit('GeV**-1'), 'GeV⁻¹');
    expect(prettyUnit('MeV/c**2'), 'MeV/c²');
    expect(displayNumberNeedsMath('1864.84 ± 0.04'), isFalse);
  });

  test('confidence levels keep meaningful decimals', () {
    expect(formatConfidence(90), '90');
    expect(formatConfidence(99.85), '99.85');
    expect(formatConfidence(97.6999969482422), '97.7');
    expect(formatConfidence(100), '100');
  });

  test('raw NULL and raw zero are distinct', () {
    expect(rawNumber(null), 'NULL');
    expect(rawNumber(0), '0');
    expect(rawNumber(0.0), '0');
  });
  group('stored power of ten that contradicts the value', () {
    String show({
      required String display,
      required String valueText,
      required double? value,
      required int power,
      String unit = '',
      String? limit,
      bool percent = false,
    }) => DisplayQuantity.fromSummary(
      summary(
        display: display,
        valueText: valueText,
        value: value,
        power: power,
        unit: unit,
        limit: limit,
        percent: percent,
      ),
    ).text;

    // Rows of the 2026 snapshot. value_text and value agree with each other
    // and with the literature; the stored display_power_of_ten does not.
    test('electron EDM limit is below 4.1e-30, not 4.1e-28 (S003EDM)', () {
      expect(
        show(
          display: '<4.1',
          valueText: '< 4.1 E-30',
          value: 4.1e-30,
          power: -28,
          unit: 'e cm',
          limit: 'U',
        ),
        '<4.1×10⁻³⁰ e cm',
      );
    });

    test('K0S -> e+ e- limit is below 9e-9, not 9e-7 (S012R12)', () {
      expect(
        show(
          display: '<9',
          valueText: '<9 E-9',
          value: 8.999366225449357e-09,
          power: -7,
          limit: 'U',
        ),
        '<9×10⁻⁹',
      );
    });

    test('lifetime limits keep their exponent of 28 (S016T77, S016T76)', () {
      expect(
        show(
          display: '>6.',
          valueText: '>6. E28',
          value: 6.0e28,
          power: 30,
          unit: 'years',
          limit: 'L',
        ),
        '>6.×10²⁸ years',
      );
      expect(
        show(
          display: '>11',
          valueText: '> 11 E28',
          value: 1.1e29,
          power: 30,
          unit: 'years',
          limit: 'L',
        ),
        '>11×10²⁸ years',
      );
    });

    test('a limit stored without any power is not given one (Q007R00)', () {
      expect(
        show(
          display: '<0.00019',
          valueText: '<0.00019',
          value: 0.00019,
          power: -4,
          limit: 'U',
        ),
        '<0.00019',
      );
    });

    test('a consistent row keeps its stored power', () {
      expect(
        show(
          display: '<4.1',
          valueText: '< 4.1 E-30',
          value: 4.1e-30,
          power: -30,
          unit: 'e cm',
          limit: 'U',
        ),
        '<4.1×10⁻³⁰ e cm',
      );
    });

    test('it is not applied when value and value_text disagree', () {
      // Neither can be trusted over the other: the stored power is kept.
      expect(
        show(
          display: '1.0',
          valueText: '1.E-20',
          value: 1.0,
          power: 0,
        ),
        '1.0',
      );
    });

    test('a display text with its own exponent states its own scale', () {
      expect(
        show(
          display: '(14.42+-0.66)E11',
          valueText: '1.442+-0.066',
          value: 1.442,
          power: 0,
        ),
        '(14.42 ± 0.66)×10¹¹',
      );
    });

    test('percent rows are not rescaled', () {
      expect(
        show(
          display: '12.5+-0.3',
          valueText: '0.125+-0.003',
          value: 0.125,
          power: -2,
          percent: true,
        ),
        '12.5 ± 0.3%',
      );
    });
  });

  group('ranges', () {
    test('both bounds are shown when the display text holds only one', () {
      final text = DisplayQuantity.fromSummary(
        summary(
          display: '-1.85',
          valueText: '-1.85E-17 to 6.1E-18',
          value: -6.5e-18,
          power: -16,
          unit: 'e cm',
          limit: 'R',
        ),
      ).text;
      expect(text, '-1.85×10⁻¹⁷ to 6.1×10⁻¹⁸ e cm');
    });

    test('a range already shown in full is untouched', () {
      final text = DisplayQuantity.fromSummary(
        summary(
          display: '400 to 800',
          valueText: '400 to 800',
          value: 600,
          limit: 'R',
        ),
      ).text;
      expect(text, '400 to 800');
    });
  });

  group('the power of ten applies to the whole value', () {
    test('asymmetric errors are parenthesised', () {
      final text = DisplayQuantity.fromSummary(
        summary(
          display: '3.51+0.23-0.25',
          valueText: '0.00351+0.00023-0.00025',
          value: 0.00351,
          power: -3,
        ),
      ).text;
      expect(text, '(3.51+0.23-0.25)×10⁻³');
    });

    test('errors with a leading dot are parenthesised too', () {
      final text = DisplayQuantity.fromSummary(
        summary(
          display: '0.09+.06-.04',
          valueText: '(9+6-4)E-12',
          value: 8.7e-12,
          power: -10,
        ),
      ).text;
      expect(text, '(0.09+.06-.04)×10⁻¹⁰');
    });

    test('symmetric errors keep their parentheses', () {
      final text = DisplayQuantity.fromSummary(
        summary(
          display: '3.5+-0.4',
          valueText: '0.0035+-0.0004',
          value: 0.0035,
          power: -3,
        ),
      ).text;
      expect(text, '(3.5 ± 0.4)×10⁻³');
    });

    test('a leading limit symbol stays outside the parentheses', () {
      final text = DisplayQuantity.fromSummary(
        summary(
          display: '> 16 - 24',
          valueText: '(> 16 - 24) E21',
          value: null,
          power: 21,
          unit: 'yr',
          limit: 'L',
        ),
      ).text;
      expect(text, '> (16 - 24)×10²¹ yr');
    });

    test('a value whose bounds carry their own exponents is left alone', () {
      final text = DisplayQuantity.fromSummary(
        summary(
          display: '<3 E-5 - 6 E-3',
          valueText: '<3 E-5 - 6 E-3',
          value: null,
          power: 0,
        ),
      ).text;
      expect(text, '<3×10⁻⁵ - 6×10⁻³');
    });
  });

  group('qualitative values', () {
    for (final word in ['seen', 'not seen']) {
      test('"$word" takes neither a power of ten nor a percent sign', () {
        expect(
          DisplayQuantity.fromSummary(
            summary(display: word, valueText: word, value: null, power: -3),
          ).text,
          word,
        );
        expect(
          DisplayQuantity.fromSummary(
            summary(
              display: word,
              valueText: word,
              value: null,
              power: -2,
              percent: true,
            ),
          ).text,
          word,
        );
      });
    }

    test('an approximate limit keeps its exponent', () {
      expect(
        DisplayQuantity.fromSummary(
          summary(display: '<~E-9', valueText: '<~E-9', value: null, power: 0),
        ).text,
        '<~×10⁻⁹',
      );
    });
  });
}
