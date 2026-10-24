import 'dart:math' as math;

import 'package:flutter/material.dart';

class _HostedPanel {
  _HostedPanel(this.entry, this.overlay);

  final OverlayEntry entry;
  final OverlayState overlay;

  /// Whether [entry] is currently inserted in [overlay]. Tracked here because
  /// `OverlayEntry.mounted` only says whether the entry's widget has been
  /// built: it is false for a frame after `insert` and still true for a frame
  /// after `remove`, so it cannot decide whether `remove` is safe.
  bool inserted = true;
}

/// Tracks the floating panels currently inserted in overlays so a modal
/// dialog can hide them (they sit above route overlays) and restore them.
class FloatingPanelHost {
  static final List<_HostedPanel> _active = [];

  /// Registers [entry]; call it immediately before inserting it in [overlay].
  static void register(OverlayEntry entry, OverlayState overlay) {
    _active.add(_HostedPanel(entry, overlay));
  }

  static void unregister(OverlayEntry entry) {
    _active.removeWhere((panel) => identical(panel.entry, entry));
  }

  /// Whether [entry] is still registered (shown, or hidden by [suspendAll]).
  static bool isOpen(OverlayEntry entry) =>
      _active.any((panel) => identical(panel.entry, entry));

  static void suspendAll() {
    for (final panel in List.of(_active)) {
      if (!panel.inserted) continue;
      panel.entry.remove();
      panel.inserted = false;
    }
  }

  static void resumeAll() {
    for (final panel in List.of(_active)) {
      if (panel.inserted || !panel.overlay.mounted) continue;
      panel.overlay.insert(panel.entry);
      panel.inserted = true;
    }
  }

  static void closeAll() {
    for (final panel in List.of(_active)) {
      if (panel.inserted) panel.entry.remove();
    }
    _active.clear();
  }

  /// Forgets [entry] and takes it out of its overlay if it is still there.
  ///
  /// [closeAll] and [suspendAll] remove entries without telling the widget that
  /// opened them, so an owner can be left holding an entry that is already out
  /// of the overlay. Removing such an entry again throws, which in a `dispose`
  /// would skip everything after it.
  static void dismiss(OverlayEntry entry) {
    for (final panel in List.of(_active)) {
      if (!identical(panel.entry, entry)) continue;
      if (panel.inserted) entry.remove();
      _active.remove(panel);
    }
  }
}

/// Non-modal, draggable and resizable panel rendered in an [Overlay].
///
/// Unlike a dialog it has no barrier: the page below stays interactive, which
/// is what the notes editor needs for a PDG lookup window that can sit next to
/// the text while the user keeps typing.
class FloatingPanel extends StatefulWidget {
  const FloatingPanel({
    super.key,
    required this.title,
    required this.child,
    required this.initialRect,
    this.minSize = const Size(320, 240),
    this.maxSize,
    this.onClose,
    this.onBack,
  });

  final String title;
  final Widget child;
  final Rect initialRect;
  final Size minSize;
  final Size? maxSize;
  final VoidCallback? onClose;
  final VoidCallback? onBack;

  @override
  State<FloatingPanel> createState() => _FloatingPanelState();
}

class _FloatingPanelState extends State<FloatingPanel> {
  late Rect _rect = widget.initialRect;

  Rect _clamp(Rect rect) {
    final media = MediaQuery.sizeOf(context);
    final maxWidth = widget.maxSize?.width ?? media.width - 16;
    final maxHeight = widget.maxSize?.height ?? media.height - 16;
    final width = rect.width
        .clamp(widget.minSize.width, math.max(widget.minSize.width, maxWidth))
        .toDouble();
    final height = rect.height
        .clamp(
          widget.minSize.height,
          math.max(widget.minSize.height, maxHeight),
        )
        .toDouble();
    final left = rect.left
        .clamp(8.0, math.max(8.0, media.width - width - 8))
        .toDouble();
    final top = rect.top
        .clamp(8.0, math.max(8.0, media.height - height - 8))
        .toDouble();
    return Rect.fromLTWH(left, top, width, height);
  }

  void _move(Offset delta) {
    setState(() => _rect = _clamp(_rect.shift(delta)));
  }

  void _resize(Offset delta) {
    setState(() {
      _rect = _clamp(
        Rect.fromLTWH(
          _rect.left,
          _rect.top,
          _rect.width + delta.dx,
          _rect.height + delta.dy,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;
    return Positioned.fromRect(
      rect: _clamp(_rect),
      child: Material(
        elevation: 18,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        color: palette.surface,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      const SizedBox(width: 6),
                      if (widget.onBack != null)
                        IconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .backButtonTooltip,
                          onPressed: widget.onBack,
                          icon: const Icon(Icons.arrow_back, size: 18),
                        )
                      else
                        const SizedBox(width: 6),
                      const Icon(Icons.drag_indicator, size: 16),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanUpdate: (details) => _move(details.delta),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: widget.child),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeDownRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) => _resize(details.delta),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.open_in_full,
                      size: 12,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
