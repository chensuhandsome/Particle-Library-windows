/// Local user-notes storage (schema v1).
///
/// Import this library from UI/features:
///
/// ```dart
/// import 'package:pdgapp/notes/notes.dart';
///
/// final store = await NotesStore.open();
/// final note = await store.create(
///   title: 'D0 lifetime',
///   bodyMarkdown: 'See the **D0** entry.',
///   anchors: [NoteAnchorInput.pdgid('S032M', snapshotHash: hash, targetLabel: 'D0')],
///   tags: ['lifetime'],
/// );
/// ```
library;

export 'note_markdown.dart';
export 'notes_exception.dart';
export 'notes_models.dart';
export 'notes_store.dart';
