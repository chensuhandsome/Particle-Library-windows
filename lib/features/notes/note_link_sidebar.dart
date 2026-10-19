import 'package:flutter/material.dart';

import 'note_link_target.dart';

import '../../app/app_scope.dart';
import '../../app/app_theme.dart';
import '../../domain/labels.dart';
import '../../domain/reference_title.dart';
import '../../domain/models.dart';
import '../common/async_view.dart';
import '../common/description_text.dart';

/// Preview of a link parsed from a note body, shown beside the note instead of
/// navigating away. The full page remains one click away.
class NoteLinkSidebar extends StatefulWidget {
  const NoteLinkSidebar({
    super.key,
    required this.target,
    required this.onClose,
    this.onOpenTarget,
  });

  /// Same target syntax as Markdown links: `pdgid:...`, `reference:doc:...`
  /// or `reference:doi:...`.
  final String target;
  final VoidCallback onClose;
  final Future<void> Function(String target)? onOpenTarget;

  @override
  State<NoteLinkSidebar> createState() => _NoteLinkSidebarState();
}

class _NoteLinkSidebarState extends State<NoteLinkSidebar> {
  late Future<NoteLinkPreview?> _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant NoteLinkSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) _future = _load();
  }

  Future<NoteLinkPreview?> _load() =>
      loadNoteLinkPreview(context, widget.target);

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    final palette = context.palette;
    return Container(
      color: palette.surfaceAlt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Insets.m, Insets.s, 4, 4),
            child: Row(
              children: [
                Icon(Icons.link, size: 16, color: palette.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    strings.notesLinkPreview,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: palette.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: strings.commonClose,
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, size: 17),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: palette.divider),
          Expanded(
            child: FutureBuilder<NoteLinkPreview?>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: LoadingPanel(compact: true));
                }
                final preview = snapshot.data;
                if (preview == null) {
                  return Padding(
                    padding: const EdgeInsets.all(Insets.m),
                    child: Text(
                      strings.notesLinkMissing,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(Insets.m),
                  children: [
                    Text(
                      preview.title,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview.subtitle,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: palette.textSecondary),
                    ),
                    const SizedBox(height: Insets.m),
                    DescriptionText(
                      preview.description,
                      selectable: true,
                      maxLines: 12,
                    ),
                    const SizedBox(height: Insets.m),
                    FilledButton.icon(
                      onPressed: () async {
                        if (widget.onOpenTarget != null) {
                          await widget.onOpenTarget!(widget.target);
                          return;
                        }
                        final opened = await openNoteLinkTarget(
                          context,
                          widget.target,
                        );
                        if (!opened && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(strings.notesLinkMissing)),
                          );
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: Text(strings.notesOpenPage),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum NoteLinkKind { pdgid, reference }

class NoteLinkPreview {
  const NoteLinkPreview({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.description,
    this.pdgid,
    this.referenceId,
  });

  final NoteLinkKind kind;
  final String title;
  final String subtitle;
  final String description;
  final String? pdgid;
  final int? referenceId;
}

Future<NoteLinkPreview?> loadNoteLinkPreview(
  BuildContext context,
  String target,
) async {
  final scope = AppScope.of(context);
  if (target.startsWith('pdgid:')) {
    final pdgid = target.substring(6);
    final entry = await scope.database.entryByPdgid(pdgid);
    if (entry == null) return null;
    final view = await scope.repository.loadEntry(entry);
    final own = view.texts
        .where((text) => text.pdgidId == view.entry.id)
        .map((text) => text.text)
        .where((text) => text.trim().isNotEmpty)
        .take(3)
        .join('\n\n');
    return NoteLinkPreview(
      kind: NoteLinkKind.pdgid,
      title: entry.description,
      subtitle:
          '${entry.pdgid} · ${dataTypeInfo(entry.dataType).label(scope.strings.lang)}',
      description: own.trim().isEmpty ? view.entry.description : own,
      pdgid: entry.pdgid,
    );
  }
  if (target.startsWith('reference:')) {
    Reference? reference;
    if (target.startsWith('reference:doc:')) {
      final documentId = target.substring('reference:doc:'.length);
      reference = await scope.database.referenceByDocumentId(documentId);
      if (reference == null) {
        final localId = int.tryParse(documentId);
        if (localId != null) {
          reference = await scope.database.referenceById(localId);
        }
      }
    } else if (target.startsWith('reference:doi:')) {
      final doi = target.substring('reference:doi:'.length);
      final refs = await scope.database.referencesByDoi(doi);
      if (refs.isNotEmpty) reference = refs.first;
    }
    if (reference == null) return null;
    return NoteLinkPreview(
      kind: NoteLinkKind.reference,
      title: cleanReferenceTitle(reference.displayTitle),
      subtitle: [
        reference.documentId,
        if (reference.publicationYear != null) '${reference.publicationYear}',
        if (reference.publicationName.isNotEmpty) reference.publicationName,
      ].join(' · '),
      description: [
        if (reference.doi.isNotEmpty) 'DOI ${reference.doi}',
        if (reference.inspireId.isNotEmpty) 'INSPIRE ${reference.inspireId}',
      ].join('\n'),
      referenceId: reference.id,
    );
  }
  return null;
}
