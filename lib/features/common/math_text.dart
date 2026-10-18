import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../app/app_theme.dart';
import '../../domain/latex.dart';
import '../../domain/models.dart';

/// Renders a PDG ASCII particle name as typeset mathematics.
///
/// The raw spelling is always the accessibility label and the fallback. A name
/// that the conservative converter cannot parse is shown as selectable text,
/// never altered.
class ParticleSymbol extends StatelessWidget {
  const ParticleSymbol(
    this.name, {
    super.key,
    this.style,
    this.fontSize,
    this.color,
    this.maxLines,
    this.textAlign,
  });

  final String name;
  final TextStyle? style;
  final double? fontSize;
  final Color? color;
  final int? maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final resolved =
        (style ?? Theme.of(context).textTheme.titleMedium ?? const TextStyle())
            .copyWith(
              fontSize: fontSize ?? style?.fontSize,
              color: color ?? style?.color ?? palette.textPrimary,
            );
    final latex = particleNameToLatex(name);
    if (latex == null) {
      return Semantics(
        label: name,
        child: Text(
          name,
          style: resolved,
          maxLines: maxLines,
          overflow: maxLines == null ? null : TextOverflow.ellipsis,
          textAlign: textAlign,
        ),
      );
    }
    return Semantics(
      label: name,
      child: ExcludeSemantics(
        child: Math.tex(
          latex,
          mathStyle: MathStyle.text,
          textStyle: resolved,
          onErrorFallback: (_) =>
              Text(name, style: resolved, maxLines: maxLines),
        ),
      ),
    );
  }
}

/// Ordered source tokens of a decay, typeset as one sequence.
class DecayEquation extends StatelessWidget {
  const DecayEquation(
    this.tokens, {
    super.key,
    required this.fallback,
    this.fontSize = 18,
    this.maxWidth,
  });

  final List<DecayToken> tokens;
  final String fallback;
  final double fontSize;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textStyle = Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontSize: fontSize, color: palette.textPrimary);
    final latex = decayTokensToLatex(tokens);
    final content = latex.isEmpty
        ? SelectableText(fallback, style: textStyle)
        : Math.tex(
            latex,
            mathStyle: MathStyle.text,
            textStyle: textStyle,
            onErrorFallback: (_) => SelectableText(fallback, style: textStyle),
          );
    final semantics = tokens
        .map((token) {
          final prefix = token.multiplier > 1 ? '${token.multiplier} x ' : '';
          return '$prefix${token.name}';
        })
        .join(tokenArrowSeparator(tokens));
    return Semantics(
      label: semantics.isEmpty ? fallback : semantics,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          constraints: maxWidth == null
              ? null
              : BoxConstraints(maxWidth: maxWidth!),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: content,
          ),
        ),
      ),
    );
  }
}

String tokenArrowSeparator(List<DecayToken> tokens) =>
    tokens.any((token) => token.name.contains('-->')) ? ' ; ' : ' ';

/// Units can contain the PDG's `**` exponent spelling. Only such units are sent
/// to the math renderer; plain units keep the system UI font.
class UnitLabel extends StatelessWidget {
  const UnitLabel(this.unit, {super.key, this.style});

  final String unit;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (unit.isEmpty) return const SizedBox.shrink();
    final palette = context.palette;
    final resolved =
        (style ?? Theme.of(context).textTheme.bodySmall ?? const TextStyle())
            .copyWith(color: palette.textSecondary);
    if (!unit.contains('**') && !unit.contains('^')) {
      return Text(unit, style: resolved);
    }
    final latex = _unitLatex(unit);
    return Math.tex(
      latex,
      mathStyle: MathStyle.text,
      textStyle: resolved,
      onErrorFallback: (_) => Text(unit, style: resolved),
    );
  }

  static String _unitLatex(String unit) {
    var text = unit
        .replaceAll('hbar', r'\hbar ')
        .replaceAll('**-1/2', r'^{-1/2}')
        .replaceAll('**1/2', r'^{1/2}')
        .replaceAll('**-1', r'^{-1}')
        .replaceAll('**-2', r'^{-2}')
        .replaceAll('**2', r'^{2}')
        .replaceAll('**3', r'^{3}')
        .replaceAll('**', r'^')
        .replaceAll('*', r'\cdot ');
    text = text.replaceAll('%', r'\%');
    return '\\mathrm{$text}';
  }
}

/// A small inline formula for definitions and titles.
class FormulaLabel extends StatelessWidget {
  const FormulaLabel(this.latex, {super.key, this.style, this.fallback});

  final String latex;
  final TextStyle? style;
  final String? fallback;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final resolved =
        (style ?? Theme.of(context).textTheme.titleMedium ?? const TextStyle())
            .copyWith(color: palette.textPrimary);
    return Math.tex(
      latex,
      mathStyle: MathStyle.text,
      textStyle: resolved,
      onErrorFallback: (_) => Text(fallback ?? latex, style: resolved),
    );
  }
}

/// Renders a source string that mixes prose with `$...$` TeX, as used by the
/// PDG reference titles. Math segments go through the same conservative
/// renderer; if a segment fails to parse the original characters are shown.
class LatexMixedText extends StatelessWidget {
  const LatexMixedText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final base =
        (style ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
            .copyWith(color: style?.color ?? palette.textPrimary);
    if (!text.contains(r'$')) {
      return Semantics(
        label: text,
        child: Text(
          text,
          style: base,
          maxLines: maxLines,
          overflow: maxLines == null ? TextOverflow.clip : overflow,
        ),
      );
    }
    final spans = <InlineSpan>[];
    final buffer = StringBuffer();
    var index = 0;
    while (index < text.length) {
      final char = text[index];
      if (char == r'\$') {
        buffer.write(r'$');
        index++;
        continue;
      }
      if (char == r'$') {
        final end = text.indexOf(r'$', index + 1);
        if (end < 0) {
          buffer.write(text.substring(index));
          index = text.length;
          continue;
        }
        if (buffer.isNotEmpty) {
          spans.add(TextSpan(text: buffer.toString()));
          buffer.clear();
        }
        final math = text.substring(index + 1, end);
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Math.tex(
              math,
              mathStyle: MathStyle.text,
              textStyle: base,
              onErrorFallback: (_) => Text(r'$' + math + r'$', style: base),
            ),
          ),
        );
        index = end + 1;
        continue;
      }
      buffer.write(char);
      index++;
    }
    if (buffer.isNotEmpty) spans.add(TextSpan(text: buffer.toString()));
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: Text.rich(
          TextSpan(children: spans),
          style: base,
          maxLines: maxLines,
          overflow: maxLines == null ? TextOverflow.clip : overflow,
        ),
      ),
    );
  }
}
