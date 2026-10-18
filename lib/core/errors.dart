/// Stable, user-visible error codes shared by the snapshot and query layers.
///
/// The design document forbids collapsing failures into empty lists: an empty
/// child list is a successful result, whereas a missing parent, an unsupported
/// schema and a failed query are distinct outcomes.
enum AppErrorCode {
  snapshotMissing,
  snapshotMismatch,
  unsupportedSchema,
  corruptDatabase,
  invalidInput,
  notFound,
  ambiguous,
  queryFailed,
  storageUnavailable;

  String get wireName => switch (this) {
        AppErrorCode.snapshotMissing => 'snapshotMissing',
        AppErrorCode.snapshotMismatch => 'snapshotMismatch',
        AppErrorCode.unsupportedSchema => 'unsupportedSchema',
        AppErrorCode.corruptDatabase => 'corruptDatabase',
        AppErrorCode.invalidInput => 'invalidInput',
        AppErrorCode.notFound => 'notFound',
        AppErrorCode.ambiguous => 'ambiguous',
        AppErrorCode.queryFailed => 'queryFailed',
        AppErrorCode.storageUnavailable => 'storageUnavailable',
      };
}

class AppException implements Exception {
  const AppException(this.code, this.message, {this.detail});

  final AppErrorCode code;
  final String message;
  final String? detail;

  @override
  String toString() =>
      'AppException(${code.wireName}): $message${detail == null ? '' : ' — $detail'}';
}

class NotFoundException extends AppException {
  const NotFoundException(String message)
      : super(AppErrorCode.notFound, message);
}
