import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// Small Zotero mark: a red Z on a quiet, theme-aware chip.
///
/// Material has no Zotero icon. A solid brand-red block is visually heavier
/// than the app's outlined controls, so the chip uses the palette surface and
/// divider while the letter keeps the brand color.
class ZoteroIcon extends StatelessWidget {
  const ZoteroIcon({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final red = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFF8A93)
        : const Color(0xFFB42318);
    return Semantics(
      label: 'Zotero',
      image: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.surfaceAlt,
          borderRadius: BorderRadius.circular(size * 0.22),
          border: Border.all(color: palette.divider),
        ),
        child: Text(
          'Z',
          textHeightBehavior: const TextHeightBehavior(
            applyHeightToFirstAscent: false,
            applyHeightToLastDescent: false,
          ),
          style: TextStyle(
            color: red,
            fontSize: size * 0.72,
            fontWeight: FontWeight.w700,
            height: 1,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
