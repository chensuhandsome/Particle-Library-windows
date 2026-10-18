import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/navigation.dart';
import 'description_text.dart';

/// A PDG description that turns exact local citation keys into links.
///
/// The snapshot has no author column; a citation is linked only when its
/// `AUTHOR YEAR` key is exactly a `pdgreference.document_id`. A close year is
/// deliberately not guessed, because it could open the wrong paper.
class CitationText extends StatefulWidget {
  const CitationText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.selectable = true,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow overflow;
  final bool selectable;

  @override
  State<CitationText> createState() => _CitationTextState();
}

class _CitationTextState extends State<CitationText> {
  static final RegExp _citationPattern = RegExp(
    r"\b[A-Z][A-Za-z0-9&.'’\-]*(?:\s+(?:AND|&|ET\s+AL\.?|[A-Z][A-Za-z0-9&.'’\-]*))*\s+(?:19|20)\d{2}[A-Z]?\b",
  );

  Map<String, int> _ids = const <String, int>{};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _resolve();
  }

  @override
  void didUpdateWidget(covariant CitationText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _resolve();
  }

  Future<void> _resolve() async {
    final candidates = <String>{
      for (final match in _citationPattern.allMatches(widget.text))
        match.group(0)!.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase(),
    };
    if (candidates.isEmpty) {
      if (mounted && _ids.isNotEmpty) setState(() => _ids = const {});
      return;
    }
    try {
      final ids = await AppScope.of(context).database
          .referenceIdsForCitationKeys(candidates);
      if (!mounted) return;
      setState(() => _ids = ids);
    } catch (_) {
      // Text remains readable without links.
    }
  }

  @override
  Widget build(BuildContext context) {
    return DescriptionText(
      widget.text,
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      selectable: widget.selectable,
      citationIds: _ids,
      onCitationTap: (id) => AppNav.openReference(context, id),
    );
  }
}
