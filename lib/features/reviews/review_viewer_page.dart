import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_scope.dart';
import '../../app/app_strings.dart';
import '../../app/app_theme.dart';
import '../../data/review_annotations.dart';

class ReviewViewerPage extends StatefulWidget {
  const ReviewViewerPage({
    super.key,
    required this.title,
    required this.path,
    required this.officialUrl,
  });

  final String title;
  final String path;
  final String officialUrl;

  @override
  State<ReviewViewerPage> createState() => _ReviewViewerPageState();
}

class _ReviewViewerPageState extends State<ReviewViewerPage> {
  final PdfViewerController _controller = PdfViewerController();
  ReviewAnnotationStore? _store;
  List<ReviewAnnotation> _annotations = const <ReviewAnnotation>[];
  bool _showAnnotations = true;
  bool _saving = false;
  bool _addingHighlight = false;
  String _highlightColor = 'yellow';
  Future<void> _saveChain = Future<void>.value();
  late final Future<void> _ready;

  String get _fileName {
    final segments = Uri.file(widget.path).pathSegments;
    for (final segment in segments.reversed) {
      if (segment.trim().isNotEmpty) return segment;
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _ready = _loadAnnotations();
  }

  Future<void> _loadAnnotations() async {
    try {
      final store = await ReviewAnnotationStore.open();
      final annotations = await store.load();
      if (!mounted) return;
      setState(() {
        _store = store;
        final known = {for (final a in _annotations) a.id};
        _annotations = [
          for (final annotation in annotations)
            if (annotation.fileName == _fileName && known.add(annotation.id))
              annotation,
          ..._annotations,
        ];
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _persist() {
    final store = _store;
    if (store == null) return Future<void>.value();
    final snapshot = List<ReviewAnnotation>.of(_annotations);
    final next = _saveChain.then((_) async {
      if (!mounted) return;
      setState(() => _saving = true);
      try {
        final all = await store.load();
        final merged = [
          for (final annotation in all)
            if (annotation.fileName != _fileName) annotation,
          ...snapshot,
        ];
        await store.save(merged);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppScope.of(context).strings.notesSaveFailed}: $error',
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    });
    _saveChain = next.catchError((_) {});
    return next;
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.officialUrl);
    if (uri == null || uri.scheme != 'https') return;
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppScope.of(context).strings.reviewsOpenFailed),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppScope.of(context).strings.reviewsOpenFailed)),
      );
    }
  }

  Future<void> _highlightSelection() async {
    await _ready;
    if (!mounted) return;
    if (!_controller.isReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppScope.of(context).strings.reviewPdfLoading)),
      );
      return;
    }
    if (_addingHighlight) return;
    final delegate = _controller.textSelectionDelegate;
    if (!delegate.hasSelectedText) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppScope.of(context).strings.reviewSelectText)),
      );
      return;
    }
    setState(() => _addingHighlight = true);
    try {
      final ranges = await delegate.getSelectedTextRanges();
      final rectsByPage = <int, List<Rect>>{};
      final textByPage = <int, String>{};
      for (final range in ranges) {
        final pageNumber = range.pageNumber;
        if (pageNumber < 1 || pageNumber > _controller.pageCount) continue;
        final page = _controller.pages[pageNumber - 1];
        if (page.width <= 0 || page.height <= 0) continue;
        for (final fragment in range.enumerateFragmentBoundingRects()) {
          // toRect applies page rotation and the PDF y-up -> Flutter y-down
          // conversion. Normalize the result so paint only needs pageRect.
          final rect = normalizePdfSelectionRect(fragment.bounds, page);
          if (rect.width <= 0 || rect.height <= 0) continue;
          rectsByPage.putIfAbsent(pageNumber, () => <Rect>[]).add(rect);
        }
        final pageText = range.text.trim();
        if (pageText.isNotEmpty) {
          textByPage[pageNumber] = [
            if (textByPage[pageNumber]?.isNotEmpty ?? false)
              textByPage[pageNumber]!,
            pageText,
          ].join(' ');
        }
      }
      if (!mounted || rectsByPage.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppScope.of(context).strings.reviewSelectText),
            ),
          );
        }
        return;
      }
      final now = DateTime.now();
      final additions = <ReviewAnnotation>[];
      for (final entry in rectsByPage.entries) {
        additions.add(
          ReviewAnnotation(
            id: '${now.microsecondsSinceEpoch}-${entry.key}',
            fileName: _fileName,
            pageNumber: entry.key,
            rects: List.unmodifiable(entry.value),
            text: textByPage[entry.key] ?? '',
            note: '',
            color: _highlightColor,
            createdAt: now,
          ),
        );
      }
      setState(() => _annotations = [...additions, ..._annotations]);
      // Clear before awaiting the write: the pdfrx delegate is detached when
      // the viewer is disposed.
      await delegate.clearTextSelection();
      await _persist();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppScope.of(context).strings.reviewSelectText),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _addingHighlight = false);
    }
  }

  Future<void> _editNote(ReviewAnnotation annotation) async {
    await _ready;
    if (!mounted) return;
    final controller = TextEditingController(text: annotation.note);
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppScope.of(context).strings.reviewAnnotationNote),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: AppScope.of(context).strings.reviewAnnotationNoteHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppScope.of(context).strings.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: Text(AppScope.of(context).strings.commonSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note == null || !mounted) return;
    final index = _annotations.indexWhere((item) => item.id == annotation.id);
    if (index < 0) return;
    final previous = _annotations[index];
    setState(() {
      _annotations = [..._annotations];
      _annotations[index] = ReviewAnnotation(
        id: previous.id,
        fileName: previous.fileName,
        pageNumber: previous.pageNumber,
        rects: previous.rects,
        text: previous.text,
        note: note,
        color: previous.color,
        createdAt: previous.createdAt,
      );
    });
    await _persist();
  }

  Future<void> _deleteAnnotation(ReviewAnnotation annotation) async {
    await _ready;
    if (!mounted) return;
    setState(() {
      _annotations = [
        for (final item in _annotations)
          if (item.id != annotation.id) item,
      ];
    });
    await _persist();
  }

  void _customizePdfContextMenu(
    PdfViewerContextMenuBuilderParams params,
    List<ContextMenuButtonItem> items,
  ) {
    items.insert(
      0,
      ContextMenuButtonItem(
        label: AppScope.of(context).strings.reviewHighlight,
        onPressed: () {
          params.dismissContextMenu();
          unawaited(_highlightSelection());
        },
      ),
    );
  }

  Color _annotationColor(String name) => switch (name) {
    'green' => const Color(0xFF4CAF50),
    'pink' => const Color(0xFFE91E63),
    'blue' => const Color(0xFF2196F3),
    _ => const Color(0xFFFFC107),
  };

  void _paintAnnotations(Canvas canvas, Rect pageRect, PdfPage page) {
    for (final annotation in _annotations) {
      if (annotation.pageNumber != page.pageNumber) continue;
      final paint = Paint()
        ..color = _annotationColor(annotation.color).withValues(alpha: 0.38);
      for (final rect in annotation.rects) {
        canvas.drawRect(
          Rect.fromLTWH(
            pageRect.left + rect.left * pageRect.width,
            pageRect.top + rect.top * pageRect.height,
            rect.width * pageRect.width,
            rect.height * pageRect.height,
          ),
          paint,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final strings = AppScope.of(context).strings;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: strings.reviewHighlight,
            onPressed: _saving || _addingHighlight ? null : _highlightSelection,
            icon: Icon(
              Icons.highlight_alt,
              size: 19,
              color: _annotationColor(_highlightColor),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: strings.reviewHighlightColor,
            icon: Icon(
              Icons.palette_outlined,
              size: 19,
              color: _annotationColor(_highlightColor),
            ),
            onSelected: (color) => setState(() => _highlightColor = color),
            itemBuilder: (context) => [
              for (final color in const ['yellow', 'green', 'pink', 'blue'])
                PopupMenuItem(
                  value: color,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _annotationColor(color),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(strings.reviewHighlightColorName(color)),
                      if (color == _highlightColor) ...[
                        const Spacer(),
                        const Icon(Icons.check, size: 16),
                      ],
                    ],
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: strings.reviewAnnotationSidebar,
            onPressed: () =>
                setState(() => _showAnnotations = !_showAnnotations),
            icon: Badge.count(
              count: _annotations.length,
              isLabelVisible: _annotations.isNotEmpty,
              child: Icon(
                _showAnnotations
                    ? Icons.view_sidebar
                    : Icons.view_sidebar_outlined,
                size: 19,
              ),
            ),
          ),
          IconButton(
            tooltip: strings.reviewOpenOfficial,
            icon: const Icon(Icons.open_in_new, size: 19),
            onPressed: _openExternally,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final sidebarWidth = constraints.maxWidth >= 720
              ? 320.0
              : (constraints.maxWidth * 0.45).clamp(160.0, 320.0);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: PdfViewer.file(
                  widget.path,
                  controller: _controller,
                  params: PdfViewerParams(
                    pagePaintCallbacks: [_paintAnnotations],
                    textSelectionParams: const PdfTextSelectionParams(
                      enabled: true,
                    ),
                    customizeContextMenuItems: _customizePdfContextMenu,
                  ),
                ),
              ),
              if (_showAnnotations) ...[
                VerticalDivider(width: 1, color: palette.divider),
                SizedBox(
                  width: sidebarWidth,
                  child: _ReviewAnnotationSidebar(
                    annotations: _annotations,
                    palette: palette,
                    strings: strings,
                    onOpen: (annotation) {
                      if (!_controller.isReady) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(strings.reviewPdfLoading)),
                        );
                        return;
                      }
                      unawaited(
                        _controller.goToPage(pageNumber: annotation.pageNumber),
                      );
                    },
                    onEditNote: _editNote,
                    onDelete: _deleteAnnotation,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ReviewAnnotationSidebar extends StatelessWidget {
  const _ReviewAnnotationSidebar({
    required this.annotations,
    required this.palette,
    required this.strings,
    required this.onOpen,
    required this.onEditNote,
    required this.onDelete,
  });

  final List<ReviewAnnotation> annotations;
  final AppPalette palette;
  final AppStrings strings;
  final ValueChanged<ReviewAnnotation> onOpen;
  final ValueChanged<ReviewAnnotation> onEditNote;
  final ValueChanged<ReviewAnnotation> onDelete;

  @override
  Widget build(BuildContext context) {
    final ordered = [...annotations]
      ..sort((a, b) {
        final page = a.pageNumber.compareTo(b.pageNumber);
        return page != 0 ? page : a.createdAt.compareTo(b.createdAt);
      });
    return ColoredBox(
      color: palette.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.highlight_alt, size: 17),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    strings.reviewAnnotations,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${annotations.length}',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: palette.textSecondary),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: palette.divider),
          Expanded(
            child: ordered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        strings.reviewAnnotationEmpty,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: palette.textSecondary),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: ordered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final annotation = ordered[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => onOpen(annotation),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: palette.divider),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: switch (annotation.color) {
                                        'green' => const Color(0xFF4CAF50),
                                        'pink' => const Color(0xFFE91E63),
                                        'blue' => const Color(0xFF2196F3),
                                        _ => const Color(0xFFFFC107),
                                      },
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    strings.reviewAnnotationPage(
                                      annotation.pageNumber,
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: palette.textSecondary,
                                        ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    tooltip: strings.reviewAnnotationEdit,
                                    visualDensity: VisualDensity.compact,
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                    padding: EdgeInsets.zero,
                                    onPressed: () => onEditNote(annotation),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 15,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: strings.commonDelete,
                                    visualDensity: VisualDensity.compact,
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                    padding: EdgeInsets.zero,
                                    onPressed: () => onDelete(annotation),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                annotation.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (annotation.note.trim().isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  annotation.note,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: palette.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
