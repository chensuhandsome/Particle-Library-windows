import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_strings.dart';
import '../../app/error_text.dart';
import '../../app/navigation.dart';
import '../../notes/notes.dart';
import '../common/floating_panel.dart';
import 'note_editor.dart';
import 'notes_anchor.dart';
import 'notes_format.dart';

/// Last collection explicitly chosen in the capture sheet. This is an
/// in-memory convenience default, not a second source of collection truth.
abstract final class NoteCaptureDefaults {
  static String? lastCollectionId;
}

String selectedQuoteBlock(String text, String label) {
  final quote = text
      .trim()
      .split('\n')
      .map((line) => line.trim().isEmpty ? '>' : '> $line')
      .join('\n');
  return '$quote\n\n**${label.trim()}**';
}

Future<void> captureTextToNote(
  BuildContext context, {
  required String text,
  required List<NoteAnchorInput> anchors,
  required String label,
  bool anchorOnly = false,
  List<NoteTarget> lookupTargets = const <NoteTarget>[],
}) async {
  final scope = AppScope.of(context);
  final store = scope.notes;
  final strings = scope.strings;
  if (store == null || (!anchorOnly && text.trim().isEmpty)) return;

  final existing = <NoteRecord>[];
  final targets = <String, NoteTarget>{
    for (final target in lookupTargets)
      '${target.kind}\u0000${target.key}': target,
    for (final anchor in anchors)
      '${anchor.targetKind}\u0000${anchor.targetKey}': NoteTarget(
        kind: anchor.targetKind,
        key: anchor.targetKey,
      ),
  }.values;
  for (final target in targets) {
    existing.addAll(
      await store.notesForTarget(target.kind, target.key, limit: 8),
    );
  }
  final recent = await store.recent(limit: 30);
  final unique = <String, NoteRecord>{
    for (final note in [...existing, ...recent]) note.id: note,
  }.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  final collections = await store.collections();
  var initialCollectionId = NoteCaptureDefaults.lastCollectionId;
  if (!collections.any((collection) => collection.id == initialCollectionId)) {
    initialCollectionId = null;
  }

  if (!context.mounted) return;
  // The capture dialog is modal: hide floating lookup panels first, otherwise
  // they sit above the dialog (overlay entries) and cover part of it.
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  final dialogContext = rootNavigator.context;
  FloatingPanelHost.suspendAll();
  final choice = await showDialog<_CaptureChoice>(
    context: dialogContext,
    builder: (_) => _CaptureDialog(
      strings: strings,
      label: label,
      text: text,
      anchorOnly: anchorOnly,
      notes: unique,
      collections: collections,
      initialCollectionId: initialCollectionId,
    ),
  );
  if (choice == null) {
    FloatingPanelHost.resumeAll();
    return;
  }
  if (choice.openAfterSave) {
    FloatingPanelHost.closeAll();
  } else {
    FloatingPanelHost.resumeAll();
  }

  final collectionId = choice.collectionId;
  final sourceLines = <String>[];
  final seenSources = <String>{};
  for (final anchor in anchors) {
    final sourceLabel = anchor.targetLabel.trim().isEmpty
        ? label
        : anchor.targetLabel;
    final line =
        '[${strings.notesSourceLine(sourceLabel)}](${anchor.targetId})';
    if (seenSources.add(line)) sourceLines.add(line);
  }
  final quote = anchorOnly
      ? sourceLines.join('\n')
      : [
          selectedQuoteBlock(text, label),
          if (sourceLines.isNotEmpty) sourceLines.join('\n'),
        ].join('\n\n');
  final NoteRecord record;
  try {
    if (choice.existing != null) {
      final note = choice.existing!;
      final body = note.bodyMarkdown.trim().isEmpty
          ? quote
          : '${note.bodyMarkdown.trim()}\n\n$quote';
      final mergedByKey = <String, NoteAnchorInput>{};
      for (final anchor in note.anchors) {
        mergedByKey['${anchor.targetId}\u0000${anchor.snapshotHash}'] =
            NoteAnchorInput(
              targetKind: anchor.targetKind,
              targetKey: anchor.targetKey,
              snapshotHash: anchor.snapshotHash.isEmpty
                  ? null
                  : anchor.snapshotHash,
              targetLabel: anchor.targetLabel,
              status: anchor.status,
              context: anchor.context,
            );
      }
      for (final anchor in anchors) {
        final key = '${anchor.targetId}\u0000${anchor.snapshotHash ?? ''}';
        final existing = mergedByKey[key];
        if (existing != null && anchor.context == null) {
          // Keep an existing context when appending a plain source link.
          continue;
        }
        mergedByKey[key] = anchor;
      }
      final merged = mergedByKey.values.toList(growable: false);
      record = await store.update(
        note.id,
        bodyMarkdown: body,
        anchors: merged,
        expectedRevision: note.revision,
      );
      if (collectionId != null) {
        await store.addNoteToCollection(note.id, collectionId);
      }
    } else {
      record = await store.create(
        title: defaultNoteTitle(
          label: label,
          anchors: anchors,
          quote: anchorOnly ? '' : text,
        ),
        bodyMarkdown: quote,
        anchors: anchors,
        collectionIds: collectionId == null
            ? const <String>[]
            : <String>[collectionId],
      );
    }
    if (const bool.fromEnvironment('PDG_REVIEW_TRACE')) {
      debugPrint(
        'NOTE capture existing=${choice.existing?.id} saved=${record.id} '
        'bodyLen=${record.bodyMarkdown.length} rev=${record.revision} '
        'anchors=${record.anchors.length}',
      );
    }
    NoteCaptureDefaults.lastCollectionId = collectionId;
    scope.notesChanges.value++;
  } catch (error) {
    if (!dialogContext.mounted) return;
    ScaffoldMessenger.of(dialogContext).showSnackBar(
      SnackBar(
        content: Text(
          '${strings.notesSaveFailed}: ${errorText(error, strings)}',
        ),
      ),
    );
    return;
  }
  if (!dialogContext.mounted) return;
  if (choice.openAfterSave) {
    await AppNav.push<void>(dialogContext, NoteEditorPage(note: record));
  } else {
    ScaffoldMessenger.of(dialogContext)
        .showSnackBar(SnackBar(content: Text(strings.notesCaptured)));
  }
}

/// Adds an entity link to a note, letting the user append to an existing note
/// or create a new one instead of silently creating a note.
Future<void> addEntityToNote(
  BuildContext context, {
  required List<NoteAnchorInput> anchors,
  required String label,
  List<NoteTarget> lookupTargets = const <NoteTarget>[],
}) => captureTextToNote(
  context,
  text: '',
  anchors: anchors,
  label: label,
  anchorOnly: true,
  lookupTargets: lookupTargets,
);

class _CaptureDialog extends StatefulWidget {
  const _CaptureDialog({
    required this.strings,
    required this.label,
    required this.text,
    required this.anchorOnly,
    required this.notes,
    required this.collections,
    required this.initialCollectionId,
  });

  final AppStrings strings;
  final String label;
  final String text;
  final bool anchorOnly;
  final List<NoteRecord> notes;
  final List<NoteCollection> collections;
  final String? initialCollectionId;

  @override
  State<_CaptureDialog> createState() => _CaptureDialogState();
}

class _CaptureDialogState extends State<_CaptureDialog> {
  // The controller lives in the dialog's own state so it is disposed only once
  // the dialog has finished closing, not while its exit transition still draws
  // the text field.
  final TextEditingController _searchController = TextEditingController();
  late String? _collectionId = widget.initialCollectionId;

  // Tapping a note only selects it; Save and Save & open then act on the
  // selection, so the user still chooses whether to open the note.
  String? _selectedNoteId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _finish({NoteRecord? existing, bool openAfterSave = false}) {
    Navigator.of(context).pop(
      _CaptureChoice(
        existing: existing,
        openAfterSave: openAfterSave,
        collectionId: _collectionId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final theme = Theme.of(context);
    final query = _searchController.text.trim();
    final visible = query.isEmpty
        ? widget.notes.take(6).toList(growable: false)
        : widget.notes
              .where((note) => noteMatchesQuery(note, query))
              .take(8)
              .toList(growable: false);
    // A selection that the current search hides is not applied.
    NoteRecord? selectedNote;
    for (final note in visible) {
      if (note.id == _selectedNoteId) selectedNote = note;
    }
    final quoted = widget.text.trim();

    return AlertDialog(
      title: Text(strings.notesCaptureTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.label, style: theme.textTheme.labelLarge),
              if (!widget.anchorOnly) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    quoted.length > 600
                        ? '${quoted.substring(0, 600)}…'
                        : quoted,
                    maxLines: 7,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              if (widget.collections.isNotEmpty) ...[
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: strings.notesCollections,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _collectionId,
                      hint: Text(strings.notesNoCollections),
                      items: [
                        for (final collection in widget.collections)
                          DropdownMenuItem<String>(
                            value: collection.id,
                            child: Text(collection.name),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _collectionId = value),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                selectedNote == null
                    ? strings.notesCaptureAppendHint
                    : strings.notesCaptureAppendingTo(
                        noteDisplayTitle(selectedNote, strings),
                      ),
                style: theme.textTheme.bodySmall,
              ),
              if (widget.notes.isNotEmpty) ...[
                const SizedBox(height: 6),
                TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: strings.notesCaptureSearchHint,
                    prefixIcon: const Icon(Icons.search, size: 17),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: visible.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            strings.notesNoSearchResults,
                            style: theme.textTheme.bodySmall,
                          ),
                        )
                      // At most eight rows, so a Column is enough; a
                      // shrink-wrapped ListView cannot answer the dialog's
                      // intrinsic-size query and fails debug assertions.
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final note in visible)
                                _noteTile(
                                  note,
                                  selected: note.id == selectedNote?.id,
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.commonCancel),
        ),
        TextButton(
          onPressed: () => _finish(existing: selectedNote),
          child: Text(strings.notesCaptureSave),
        ),
        FilledButton.icon(
          onPressed: () => _finish(existing: selectedNote, openAfterSave: true),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: Text(strings.notesCaptureSaveAndOpen),
        ),
      ],
    );
  }

  Widget _noteTile(NoteRecord note, {required bool selected}) {
    final strings = widget.strings;
    final preview = noteBodyPreview(note);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      selected: selected,
      selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
      leading: const Icon(Icons.note_alt_outlined, size: 18),
      trailing: selected ? const Icon(Icons.check, size: 18) : null,
      title: Text(
        noteDisplayTitle(note, strings),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        preview.isEmpty
            ? [
                noteUpdatedLabel(note.updatedAt, strings),
                if (note.anchors.isNotEmpty)
                  anchorDisplayLabel(note.anchors.first),
              ].join(' · ')
            : preview,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => setState(() => _selectedNoteId = selected ? null : note.id),
    );
  }
}

class _CaptureChoice {
  const _CaptureChoice({
    this.existing,
    this.openAfterSave = false,
    this.collectionId,
  });

  final NoteRecord? existing;
  final bool openAfterSave;

  /// The collection picked in the dialog, if any.
  final String? collectionId;
}
