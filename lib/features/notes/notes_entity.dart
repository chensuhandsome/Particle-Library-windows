import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_strings.dart';
import '../../app/app_theme.dart';
import '../../app/navigation.dart';
import '../../notes/notes.dart';
import '../common/ui.dart';
import 'note_capture.dart';
import 'note_editor.dart';
import 'note_link_target.dart';
import 'notes_format.dart';
import 'tag_tools.dart';

/// Opens the shared editor as a route, optionally prefilled with an entity's
/// anchors. Calling it with no anchors creates an unanchored note (used by the
/// Notes page itself).
Future<void> openNoteComposer(
  BuildContext context, {
  required List<NoteAnchorInput> anchors,
  List<String> initialCollectionIds = const <String>[],
}) {
  return AppNav.push<void>(
    context,
    NoteEditorPage(
      initialAnchors: anchors,
      initialCollectionIds: initialCollectionIds,
    ),
  );
}

/// Opens an existing note in the shared editor route.
Future<void> openNoteEditor(BuildContext context, NoteRecord note) =>
    AppNav.push<void>(context, NoteEditorPage(note: note));

String _anchorAddLabel(List<NoteAnchorInput> anchors, AppStrings strings) {
  for (final anchor in anchors) {
    final label = anchor.targetLabel.trim();
    if (label.isNotEmpty) return label;
  }
  return strings.notesTitle;
}

/// Loads notes for one or more targets, removing duplicates when a reference
/// page checks both its DOI and its document_id. Queries are per target (at
/// most two), never per note.
Future<List<NoteRecord>> loadNotesForTargets(
  NotesStore store,
  List<NoteTarget> targets, {
  int? limit,
}) async {
  final seen = <String>{};
  final notes = <NoteRecord>[];
  for (final target in targets) {
    final found = await store.notesForTarget(
      target.kind,
      target.key,
      limit: limit,
    );
    for (final note in found) {
      if (seen.add(note.id)) notes.add(note);
    }
  }
  notes.sort((a, b) {
    final byTime = b.updatedAt.compareTo(a.updatedAt);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  });
  if (limit != null && notes.length > limit) {
    return notes.sublist(0, limit);
  }
  return notes;
}

/// Batched backlink count for all targets of one entity.
///
/// P1 creates exactly one reference anchor per note (DOI preferred, otherwise
/// document_id), so summing the per-target counts does not double-count notes
/// written by this app.
Future<int> countNotesForTargets(
  NotesStore store,
  List<NoteTarget> targets,
) async {
  if (targets.isEmpty) return 0;
  return store.countDistinctForTargets(targets);
}

/// Compact app-bar action: add a note anchored to the current entity, with a
/// badge showing how many notes already point at it.
class EntityNotesButton extends StatefulWidget {
  const EntityNotesButton({
    super.key,
    required this.targets,
    required this.anchors,
  });

  final List<NoteTarget> targets;
  final List<NoteAnchorInput> anchors;

  @override
  State<EntityNotesButton> createState() => _EntityNotesButtonState();
}

class _EntityNotesButtonState extends State<EntityNotesButton> {
  NotesStore? _store;
  ValueNotifier<int>? _changes;
  int _count = 0;
  Object? _error;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);
    if (_initialized && identical(scope.notesChanges, _changes)) return;
    _initialized = true;
    _changes?.removeListener(_reload);
    _changes = scope.notesChanges..addListener(_reload);
    _store = scope.notes;
    _reload();
  }

  @override
  void dispose() {
    _changes?.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final store = _store;
    if (store == null) {
      if (mounted) {
        setState(() {
          _count = 0;
          _error = null;
        });
      }
      return;
    }
    try {
      final count = await countNotesForTargets(store, widget.targets);
      if (!mounted) return;
      setState(() {
        _count = count;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final strings = scope.strings;
    final unavailable = scope.notes == null;
    final disabled = unavailable || widget.anchors.isEmpty;
    final tooltip = unavailable
        ? strings.notesUnavailable
        : '${strings.notesAddToTarget} · ${strings.notesCount(_count)}';
    return IconButton(
      tooltip: tooltip,
      onPressed: disabled
          ? null
          : () => addEntityToNote(
              context,
              anchors: widget.anchors,
              label: _anchorAddLabel(widget.anchors, strings),
              lookupTargets: widget.targets,
            ),
      icon: Badge.count(
        count: _count,
        isLabelVisible: _count > 0,
        child: Icon(
          Icons.note_add_outlined,
          size: 20,
          color: _error != null ? context.palette.warning : null,
        ),
      ),
    );
  }
}

/// Backlinks block for particle, series/property and reference pages.
class EntityNotesSection extends StatefulWidget {
  const EntityNotesSection({
    super.key,
    required this.targets,
    required this.anchors,
    this.limit = 3,
  });

  final List<NoteTarget> targets;
  final List<NoteAnchorInput> anchors;
  final int limit;

  @override
  State<EntityNotesSection> createState() => _EntityNotesSectionState();
}

class _EntityNotesSectionState extends State<EntityNotesSection> {
  NotesStore? _store;
  ValueNotifier<int>? _changes;
  List<NoteRecord> _notes = const <NoteRecord>[];
  List<NoteRecord> _mentions = const <NoteRecord>[];
  int _count = 0;
  bool _loaded = false;
  Object? _error;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);
    if (_initialized && identical(scope.notesChanges, _changes)) return;
    _initialized = true;
    _changes?.removeListener(_reload);
    _changes = scope.notesChanges..addListener(_reload);
    _store = scope.notes;
    _reload();
  }

  @override
  void dispose() {
    _changes?.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final store = _store;
    if (store == null) {
      if (mounted) {
        setState(() {
          _notes = const <NoteRecord>[];
          _mentions = const <NoteRecord>[];
          _count = 0;
          _loaded = true;
          _error = null;
        });
      }
      return;
    }
    try {
      final notes = await loadNotesForTargets(
        store,
        widget.targets,
        limit: widget.limit,
      );
      final count = await countNotesForTargets(store, widget.targets);
      final mentions = await store.notesMentioningTargets(
        widget.targets,
        limit: 50,
      );
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _mentions = mentions;
        _count = count;
        _loaded = true;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loaded = true;
        _error = error;
      });
    }
  }

  Future<void> _showMentions() async {
    final store = _store;
    if (store == null) return;
    final strings = AppScope.of(context).strings;
    final all = await store.notesMentioningTargets(widget.targets, limit: 100);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.notesMentionedTitle),
        content: SizedBox(
          width: 520,
          child: all.isEmpty
              ? Text(strings.notesMentionedEmpty)
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 420),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final note in all)
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.link, size: 18),
                          title: Text(
                            noteDisplayTitle(note, strings),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            noteBodyPreview(note, maxLength: 120),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.of(dialogContext).pop();
                            openNoteEditor(context, note);
                          },
                        ),
                    ],
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.commonClose),
          ),
        ],
      ),
    );
  }

  Future<void> _showAllNotes() async {
    final store = _store;
    if (store == null) return;
    final strings = AppScope.of(context).strings;
    final all = await loadNotesForTargets(store, widget.targets, limit: 200);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.notesBacklinksTitle),
        content: SizedBox(
          width: 520,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final note in all)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.sticky_note_2_outlined, size: 18),
                    title: Text(
                      noteDisplayTitle(note, strings),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      noteBodyPreview(note, maxLength: 120),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      openNoteEditor(context, note);
                    },
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(strings.commonClose),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final strings = scope.strings;
    final palette = context.palette;
    final unavailable = scope.notes == null;
    final addButton = IconButton(
      tooltip: unavailable
          ? strings.notesUnavailable
          : strings.notesAddToTarget,
      onPressed: unavailable || widget.anchors.isEmpty
          ? null
          : () => addEntityToNote(
              context,
              anchors: widget.anchors,
              label: _anchorAddLabel(widget.anchors, strings),
            ),
      icon: const Icon(Icons.note_add_outlined, size: 18),
    );
    Widget child;
    if (unavailable) {
      child = Text(
        strings.notesUnavailable,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: palette.textSecondary),
      );
    } else if (!_loaded) {
      child = Text(
        strings.commonLoading,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: palette.textSecondary),
      );
    } else if (_error != null) {
      child = Text(
        '${strings.notesLoadFailed}: $_error',
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: palette.warning),
      );
    } else if (_notes.isEmpty) {
      child = Row(
        children: [
          Icon(
            Icons.sticky_note_2_outlined,
            size: 17,
            color: palette.textSecondary,
          ),
          const SizedBox(width: Insets.s),
          Expanded(
            child: Text(
              strings.notesEmptyForTarget,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: palette.textSecondary),
            ),
          ),
          TextButton(
            onPressed: unavailable || widget.anchors.isEmpty
                ? null
                : () => addEntityToNote(
                    context,
                    anchors: widget.anchors,
                    label: _anchorAddLabel(widget.anchors, strings),
                    lookupTargets: widget.targets,
                  ),
            child: Text(strings.notesAdd),
          ),
        ],
      );
    } else {
      child = Column(
        children: [
          for (var index = 0; index < _notes.length; index++) ...[
            if (index > 0)
              Divider(height: 1, color: palette.divider.withValues(alpha: 0.7)),
            _EntityNoteRow(note: _notes[index]),
          ],
        ],
      );
    }
    if (_mentions.isNotEmpty) {
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          child,
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _showMentions,
              icon: const Icon(Icons.link, size: 15),
              label: Text(
                '${strings.notesMentionedTitle} · ${_mentions.length}',
              ),
            ),
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.l),
      child: SectionCard(
        title: strings.notesTitle,
        subtitle: strings.notesCount(_count),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_count > _notes.length)
              TextButton(
                onPressed: _showAllNotes,
                child: Text(strings.notesViewAll),
              ),
            addButton,
          ],
        ),
        child: child,
      ),
    );
  }
}

class _EntityNoteRow extends StatelessWidget {
  const _EntityNoteRow({required this.note});

  final NoteRecord note;

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    final palette = context.palette;
    final preview = noteBodyPreview(note, maxLength: 140);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => openNoteEditor(context, note),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.xs,
          vertical: Insets.s,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.sticky_note_2_outlined,
                size: 16,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(width: Insets.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    noteDisplayTitle(note, strings),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    noteUpdatedLabel(note.updatedAt, strings),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: palette.textSecondary),
                  ),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: palette.textSecondary),
                    ),
                  ],
                  if (note.tagNames.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 3,
                      children: [
                        for (final tag in note.tagNames.take(4))
                          MetaChip(
                            tag,
                            onTap: () => showNotesForTag(
                              context,
                              store: AppScope.of(context).notes!,
                              strings: strings,
                              tag: tag,
                              onOpen: (note) => openNoteEditor(context, note),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 17),
          ],
        ),
      ),
    );
  }
}

/// Compact Notes card shown at the top of the context sidebar.
class SidebarNotesSection extends StatefulWidget {
  const SidebarNotesSection({
    super.key,
    required this.targets,
    required this.anchors,
    this.limit = 3,
  });

  final List<NoteTarget> targets;
  final List<NoteAnchorInput> anchors;
  final int limit;

  @override
  State<SidebarNotesSection> createState() => _SidebarNotesSectionState();
}

class _SidebarNotesSectionState extends State<SidebarNotesSection> {
  NotesStore? _store;
  ValueNotifier<int>? _changes;
  List<NoteRecord> _notes = const <NoteRecord>[];
  int _count = 0;
  bool _loaded = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);
    if (_initialized && identical(scope.notesChanges, _changes)) return;
    _initialized = true;
    _changes?.removeListener(_reload);
    _changes = scope.notesChanges..addListener(_reload);
    _store = scope.notes;
    _reload();
  }

  @override
  void dispose() {
    _changes?.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final store = _store;
    if (store == null) {
      if (mounted) {
        setState(() {
          _notes = const <NoteRecord>[];
          _count = 0;
          _loaded = true;
        });
      }
      return;
    }
    try {
      final notes = await loadNotesForTargets(
        store,
        widget.targets,
        limit: widget.limit,
      );
      final count = await countNotesForTargets(store, widget.targets);
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _count = count;
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final strings = scope.strings;
    final palette = context.palette;
    final unavailable = scope.notes == null;
    Widget body;
    if (unavailable) {
      body = _paddedText(context, strings.notesUnavailable);
    } else if (!_loaded) {
      body = _paddedText(context, strings.commonLoading);
    } else if (_notes.isEmpty) {
      body = _paddedText(context, strings.notesEmptyForTarget);
    } else {
      body = Column(
        children: [
          for (var index = 0; index < _notes.length; index++) ...[
            if (index > 0)
              Divider(height: 1, color: palette.divider.withValues(alpha: 0.7)),
            _sidebarNoteRow(context, _notes[index]),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  strings.notesTitle,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_count > 0)
                Text(
                  '$_count',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: palette.textSecondary),
                ),
              IconButton(
                tooltip: unavailable
                    ? strings.notesUnavailable
                    : strings.notesAddToTarget,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
                onPressed: unavailable || widget.anchors.isEmpty
                    ? null
                    : () => addEntityToNote(
                        context,
                        anchors: widget.anchors,
                        label: _anchorAddLabel(widget.anchors, strings),
                        lookupTargets: widget.targets,
                      ),
                icon: const Icon(Icons.add, size: 18),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: palette.divider),
          ),
          child: body,
        ),
      ],
    );
  }

  Widget _paddedText(BuildContext context, String text) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.all(Insets.s),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: palette.textSecondary),
      ),
    );
  }

  Widget _sidebarNoteRow(BuildContext context, NoteRecord note) {
    final strings = AppScope.of(context).strings;
    final palette = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => openNoteEditor(context, note),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              noteDisplayTitle(note, strings),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 1),
            Text(
              noteUpdatedLabel(note.updatedAt, strings),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: palette.textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the PDG target behind a saved note anchor.
Future<void> openNoteAnchor(BuildContext context, NoteAnchor anchor) async {
  final opened = await openNoteLinkTarget(context, anchor.targetId);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppScope.of(context).strings.notesLinkMissing)),
    );
  }
}
