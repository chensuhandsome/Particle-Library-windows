import 'errors.dart';

/// Expected identity of the bundled snapshot. These values come from the
/// design documents and the measured file under `assets/`.
abstract final class SnapshotContract {
  static const String assetName = 'assets/pdgall-2026.0.sqlite';
  static const String fileName = 'pdgall-2026.0.sqlite';
  static const String expectedSha256 =
      'c82dab0c0a7c5264f23508066cabb8df9eacc1dbfc83c8d20fade6053394ba8a';
  static const String expectedSchemaVersion = '0.3';
  static const String expectedEdition = '2026';
  static const int expectedSizeBytes = 67457024;

  /// Every business table with the columns the application reads.
  ///
  /// A missing table/column is an unsupported schema, not an empty dataset.
  static const Map<String, Set<String>> requiredSchema = {
    'pdgdata': {
      'id', 'pdgid_id', 'pdgid', 'edition', 'value_type', 'in_summary_table',
      'confidence_level', 'limit_type', 'comment', 'value', 'value_text',
      'error_positive', 'error_negative', 'scale_factor', 'unit_text',
      'display_value_text', 'display_power_of_ten', 'display_in_percent', 'sort',
    },
    'pdgdecay': {
      'id', 'pdgid_id', 'pdgid', 'pdgitem_id', 'name', 'is_outgoing',
      'multiplier', 'subdecay_id', 'sort',
    },
    'pdgdoc': {
      'id', 'table_name', 'column_name', 'value', 'indicator', 'description',
      'comment',
    },
    'pdgfootnote': {'id', 'pdgid', 'text', 'footnote_index', 'changebar'},
    'pdgid': {
      'id', 'pdgid', 'parent_id', 'parent_pdgid', 'description', 'mode_number',
      'data_type', 'flags', 'year_added', 'sort',
    },
    'pdgid_map': {'id', 'source_id', 'source', 'target_id', 'target', 'type', 'sort'},
    'pdginfo': {'id', 'name', 'value'},
    'pdgitem': {'id', 'name', 'item_type'},
    'pdgitem_map': {'id', 'pdgitem_id', 'name', 'target_id', 'sort'},
    'pdgmeasurement': {
      'id', 'pdgid_id', 'pdgid', 'pdgreference_id', 'event_count',
      'confidence_level', 'place', 'technique', 'charge', 'changebar',
      'comment', 'sort',
    },
    'pdgmeasurement_footnote': {
      'id', 'pdgmeasurement_id', 'pdgfootnote_id',
    },
    'pdgmeasurement_values': {
      'id', 'pdgmeasurement_id', 'column_name', 'value_text', 'unit_text',
      'display_value_text', 'display_power_of_ten', 'display_in_percent',
      'limit_type', 'used_in_average', 'used_in_fit', 'value',
      'error_positive', 'error_negative', 'stat_error_positive',
      'stat_error_negative', 'syst_error_positive', 'syst_error_negative', 'sort',
    },
    'pdgparticle': {
      'id', 'pdgid_id', 'pdgid', 'pdgitem_id', 'name', 'cc_type', 'mcid',
      'charge', 'quantum_i', 'quantum_g', 'quantum_j', 'quantum_p', 'quantum_c',
    },
    'pdgreference': {
      'id', 'document_id', 'publication_name', 'publication_year', 'doi',
      'inspire_id', 'title',
    },
    'pdgtext': {'id', 'pdgid_id', 'pdgid', 'text', 'type', 'sort'},
  };

  static AppException schemaError(String detail) =>
      AppException(AppErrorCode.unsupportedSchema,
          '当前数据库不符合已支持的 pdgall schema。', detail: detail);
}
