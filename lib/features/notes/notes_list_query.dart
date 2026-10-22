import '../../notes/notes.dart';
import 'notes_format.dart';

/// Upper bound on how many rows one list refresh may read while it looks for a
/// full page of notes that survive the in-memory filters.
const int _maxScan = 5000;

/// Loads one page of the notes list for the current filters.
///
/// The store can filter by tags, by a text query, by collection or by "unfiled",
/// but not by several of these together. The remaining filters are applied
/// here, after the read. Cutting the read at [pageSize] first would drop notes:
/// with 80 notes tagged "kaon" and a query that only the oldest one matches,
/// the first 50 are read, none matches, and the list shows no results. So the
/// read widens until a full page of survivors is found or the rows run out.
///
/// The result has at most [pageSize] notes; a result of exactly [pageSize]
/// tells the caller that "load more" may have something to load.
Future<List<NoteRecord>> loadNoteList(
  NotesStore store, {
  required int pageSize,
  List<String> tags = const <String>[],
  String query = '',
  String? collectionId,
  bool unfiledScope = false,
}) async {
  final trimmed = query.trim();

  Future<List<NoteRecord>> read(int limit) {
    if (tags.isNotEmpty) {
      return store.notesByTags(tags, collectionId: collectionId, limit: limit);
    }
    if (trimmed.isEmpty) {
      if (unfiledScope) return store.unfiled(limit: limit);
      if (collectionId == null) return store.recent(limit: limit);
      return store.notesInCollection(collectionId, limit: limit);
    }
    return store.search(trimmed, limit: limit, collectionId: collectionId);
  }

  List<NoteRecord> filter(List<NoteRecord> notes) {
    var result = notes;
    if (unfiledScope) {
      result = result.where((note) => note.collections.isEmpty).toList();
    }
    if (tags.isNotEmpty && trimmed.isNotEmpty) {
      result = result.where((note) => noteMatchesQuery(note, trimmed)).toList();
    }
    return result;
  }

  final filtered = unfiledScope || (tags.isNotEmpty && trimmed.isNotEmpty);
  var limit = pageSize;
  while (true) {
    final rows = await read(limit);
    final notes = filter(rows);
    final exhausted = rows.length < limit;
    if (!filtered ||
        notes.length >= pageSize ||
        exhausted ||
        limit >= _maxScan) {
      return notes.length > pageSize ? notes.sublist(0, pageSize) : notes;
    }
    limit = limit * 4 > _maxScan ? _maxScan : limit * 4;
  }
}
