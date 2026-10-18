/// Failure modes of the local notes database.
///
/// The notes database is deliberately separate from both the read-only PDG
/// snapshot and `user_store.json`. A failure is reported through one of these
/// codes instead of being collapsed into an empty list, so callers (and P1 UI)
/// can distinguish "no notes" from "the notes database is unavailable".
enum NotesErrorCode {
  /// The database file/directory cannot be opened or written.
  unavailable,

  /// SQLite integrity checks failed, or the file is not a database.
  ///
  /// The file is never deleted, truncated or recreated in this case.
  corrupt,

  /// The database has a newer `user_version` or an unexpected schema.
  ///
  /// Existing data is left untouched; the store refuses to open it.
  unsupportedSchema,

  /// Invalid arguments supplied by the caller.
  invalidInput,

  /// The requested note does not exist (or is soft-deleted where an active
  /// note is required).
  notFound,

  /// A write was based on an older revision than the stored note.
  conflict,

  /// A write transaction failed.
  writeFailed,

  /// `VACUUM INTO` or backup verification failed.
  backupFailed,
}

/// Typed exception thrown by [NotesStore] operations.
class NotesException implements Exception {
  const NotesException(this.code, this.message, {this.cause});

  final NotesErrorCode code;
  final String message;

  /// Underlying `SqliteException`, `FileSystemException`, etc. for logs only.
  final Object? cause;

  /// Whether this exception reports on-disk corruption. Callers must not
  /// attempt to "repair" by deleting the database.
  bool get isCorruption => code == NotesErrorCode.corrupt;

  @override
  String toString() =>
      'NotesException(${code.name}): $message'
      '${cause == null ? '' : ' — $cause'}';
}
