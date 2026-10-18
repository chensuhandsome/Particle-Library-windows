/// Lossless row wrappers for the read-only PDG snapshot.
///
/// Every wrapper keeps the complete source row (`raw`) so that no column is
/// ever lost by the typed view. NULL, the empty string and numeric zero stay
/// distinguishable: getters return `null` only for SQL NULL.
library;

typedef RawRow = Map<String, Object?>;

int? asInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? asDouble(Object? value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String? asString(Object? value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

bool? asBoolOrNull(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == '1' || normalized == 'true') return true;
    if (normalized == '0' || normalized == 'false') return false;
  }
  return null;
}

bool asBool(Object? value) => asBoolOrNull(value) ?? false;

/// One source column, rendered for the raw-record inspector.
class RawField {
  const RawField(this.table, this.column, this.value);

  final String table;
  final String column;
  final Object? value;

  bool get isNull => value == null;
  bool get isEmptyString => value is String && (value as String).isEmpty;

  /// A faithful text form. NULL and the empty string are deliberately not
  /// rendered alike.
  String get displayText {
    if (value == null) return 'NULL';
    if (value is String) return value as String;
    if (value is bool) return (value as bool) ? '1' : '0';
    return value.toString();
  }

  String get qualifiedName => '$table.$column';
}

class SourceRef {
  const SourceRef({
    required this.snapshotHash,
    required this.table,
    required this.rowId,
  });

  final String snapshotHash;
  final String table;
  final int rowId;

  Map<String, Object?> toJson() => {
        'snapshot': snapshotHash,
        'table': table,
        'id': rowId,
      };
}

/// Snapshot metadata (`pdginfo`). Every key/value row is retained.
class SnapshotInfo {
  SnapshotInfo(Map<String, String?> entries) : _byName = Map.of(entries);

  final Map<String, String?> _byName;

  static SnapshotInfo fromRows(List<RawRow> rows) {
    final values = <String, String?>{};
    for (final row in rows) {
      final name = asString(row['name']);
      if (name != null) values[name] = asString(row['value']);
    }
    return SnapshotInfo(values);
  }

  String? get producer => _byName['producer'];
  String? get status => _byName['status'];
  String? get schemaVersion => _byName['schema_version'];
  String? get dataRelease => _byName['data_release'];
  String? get releaseTimestamp => _byName['data_release_timestamp'];
  String? get edition => _byName['edition'];
  String? get citation => _byName['citation'];
  String? get license => _byName['license'];
  String? get about => _byName['about'];
  String? get changebarStartDate => _byName['changebar_start_date'];

  Map<String, String?> get entries => Map.unmodifiable(_byName);

  List<RawField> get rawFields => [
        for (final entry in _byName.entries)
          RawField('pdginfo', entry.key, entry.value),
      ];
}

class Entry {
  const Entry(this.raw);

  final RawRow raw;

  int get id => asInt(raw['id'])!;
  String get pdgid => asString(raw['pdgid']) ?? '';
  int? get parentId => asInt(raw['parent_id']);
  String? get parentPdgid => asString(raw['parent_pdgid']);
  String get description => asString(raw['description']) ?? '';
  int? get modeNumber => asInt(raw['mode_number']);
  String get dataType => asString(raw['data_type']) ?? '';
  String get flags => asString(raw['flags']) ?? '';
  int? get yearAdded => asInt(raw['year_added']);
  int get sort => asInt(raw['sort']) ?? 0;

  bool get hasParent => parentId != null;

  List<RawField> get rawFields =>
      [for (final e in raw.entries) RawField('pdgid', e.key, e.value)];
}

class Particle {
  const Particle(this.raw);

  final RawRow raw;

  int get id => asInt(raw['id'])!;
  int get pdgidId => asInt(raw['pdgid_id'])!;
  String get pdgid => asString(raw['pdgid']) ?? '';
  int get pdgitemId => asInt(raw['pdgitem_id'])!;
  String get name => asString(raw['name']) ?? '';
  String? get ccType => asString(raw['cc_type']);
  int? get mcid => asInt(raw['mcid']);
  double? get charge => asDouble(raw['charge']);
  String? get quantumI => asString(raw['quantum_i']);
  String? get quantumG => asString(raw['quantum_g']);
  String? get quantumJ => asString(raw['quantum_j']);
  String? get quantumP => asString(raw['quantum_p']);
  String? get quantumC => asString(raw['quantum_c']);

  List<RawField> get rawFields =>
      [for (final e in raw.entries) RawField('pdgparticle', e.key, e.value)];
}

class ItemRecord {
  const ItemRecord(this.raw);

  final RawRow raw;

  int get id => asInt(raw['id'])!;
  String get name => asString(raw['name']) ?? '';
  String get itemType => asString(raw['item_type']) ?? '';

  List<RawField> get rawFields =>
      [for (final e in raw.entries) RawField('pdgitem', e.key, e.value)];
}

class ItemEdge {
  const ItemEdge(this.raw);

  final RawRow raw;

  int get id => asInt(raw['id'])!;
  int get pdgitemId => asInt(raw['pdgitem_id'])!;
  String get name => asString(raw['name']) ?? '';
  int get targetId => asInt(raw['target_id'])!;
  int get sort => asInt(raw['sort']) ?? 0;
}

class EntryEdge {
  const EntryEdge(this.raw);

  final RawRow raw;

  int get id => asInt(raw['id'])!;
  int get sourceId => asInt(raw['source_id'])!;
  String? get source => asString(raw['source']);
  int get targetId => asInt(raw['target_id'])!;
  String? get target => asString(raw['target']);
  String? get type => asString(raw['type']);
  int get sort => asInt(raw['sort']) ?? 0;
}

/// A `pdgdata` summary row, with every display field preserved.
class Summary {
  const Summary(this.raw);

  final RawRow raw;

  int get id => asInt(raw['id'])!;
  int get pdgidId => asInt(raw['pdgid_id'])!;
  String get pdgid => asString(raw['pdgid']) ?? '';
  String? get edition => asString(raw['edition']);
  String get valueType => asString(raw['value_type']) ?? '';
  bool get inSummaryTable => asBool(raw['in_summary_table']);
  double? get confidenceLevel => asDouble(raw['confidence_level']);
  String? get limitType => asString(raw['limit_type']);
  String? get comment => asString(raw['comment']);
  double? get value => asDouble(raw['value']);
  String? get valueText => asString(raw['value_text']);
  double? get errorPositive => asDouble(raw['error_positive']);
  double? get errorNegative => asDouble(raw['error_negative']);
  double? get scaleFactor => asDouble(raw['scale_factor']);
  String get unitText => asString(raw['unit_text']) ?? '';
  String get displayValueText => asString(raw['display_value_text']) ?? '';
  int get displayPowerOfTen => asInt(raw['display_power_of_ten']) ?? 0;
  bool get displayInPercent => asBool(raw['display_in_percent']);
  int? get sort => asInt(raw['sort']);

  List<RawField> get rawFields =>
      [for (final e in raw.entries) RawField('pdgdata', e.key, e.value)];
}

class Measurement {
  const Measurement(this.raw);

  final RawRow raw;

  int get id => asInt(raw['id'])!;
  int get pdgidId => asInt(raw['pdgid_id'])!;
  String get pdgid => asString(raw['pdgid']) ?? '';
  int get pdgreferenceId => asInt(raw['pdgreference_id'])!;
  String get eventCount => asString(raw['event_count']) ?? '';
  double? get confidenceLevel => asDouble(raw['confidence_level']);
  String get place => asString(raw['place']) ?? '';
  String get technique => asString(raw['technique']) ?? '';
  String get charge => asString(raw['charge']) ?? '';
  bool get changebar => asBool(raw['changebar']);
  String get comment => asString(raw['comment']) ?? '';
  int get sort => asInt(raw['sort']) ?? 0;

  List<RawField> get rawFields =>
      [for (final e in raw.entries) RawField('pdgmeasurement', e.key, e.value)];
}

class MeasurementValue {
  const MeasurementValue(this.raw);

  final RawRow raw;

  int get id => asInt(raw['id'])!;
  int get measurementId => asInt(raw['pdgmeasurement_id'])!;
  String get columnName => asString(raw['column_name']) ?? '';
  String get valueText => asString(raw['value_text']) ?? '';
  String get unitText => asString(raw['unit_text']) ?? '';
  String get displayValueText => asString(raw['display_value_text']) ?? '';
  int get displayPowerOfTen => asInt(raw['display_power_of_ten']) ?? 0;
  bool get displayInPercent => asBool(raw['display_in_percent']);
  String? get limitType => asString(raw['limit_type']);
  bool? get usedInAverage => asBoolOrNull(raw['used_in_average']);
  bool? get usedInFit => asBoolOrNull(raw['used_in_fit']);
  double? get value => asDouble(raw['value']);
  double? get errorPositive => asDouble(raw['error_positive']);
  double? get errorNegative => asDouble(raw['error_negative']);
  double? get statErrorPositive => asDouble(raw['stat_error_positive']);
  double? get statErrorNegative => asDouble(raw['stat_error_negative']);
  double? get systErrorPositive => asDouble(raw['syst_error_positive']);
  double? get systErrorNegative => asDouble(raw['syst_error_negative']);
  int get sort => asInt(raw['sort']) ?? 0;

  List<RawField> get rawFields => [
        for (final e in raw.entries)
          RawField('pdgmeasurement_values', e.key, e.value)
      ];
}

class Footnote {
  const Footnote(this.raw);

  final RawRow raw;

  int get id => asInt(raw['id'])!;
  String? get pdgid => asString(raw['pdgid']);
  String get text => asString(raw['text']) ?? '';
  int? get footnoteIndex => asInt(raw['footnote_index']);
  bool get changebar => asBool(raw['changebar']);

  List<RawField> get rawFields =>
      [for (final e in raw.entries) RawField('pdgfootnote', e.key, e.value)];
}

class Reference {
  const Reference(this.raw);

  final RawRow raw;

  int get id => asInt(raw['id'])!;
  String get documentId => (asString(raw['document_id']) ?? '').trim();
  String get publicationName => asString(raw['publication_name']) ?? '';
  int? get publicationYear => asInt(raw['publication_year']);
  String get doi => asString(raw['doi']) ?? '';
  String get inspireId => asString(raw['inspire_id']) ?? '';
  String get title => asString(raw['title']) ?? '';

  String get displayTitle => title.isEmpty ? documentId : title;

  List<RawField> get rawFields =>
      [for (final e in raw.entries) RawField('pdgreference', e.key, e.value)];
}

class SectionText {
  const SectionText(this.raw);

  final RawRow raw;

  int get id => asInt(raw['id'])!;
  int get pdgidId => asInt(raw['pdgid_id'])!;
  String get pdgid => asString(raw['pdgid']) ?? '';
  String get text => asString(raw['text']) ?? '';
  String get type => asString(raw['type']) ?? '';
  int get sort => asInt(raw['sort']) ?? 0;

  bool get isHeading => type == 'h';

  List<RawField> get rawFields =>
      [for (final e in raw.entries) RawField('pdgtext', e.key, e.value)];
}

class DecayToken {
  const DecayToken(this.raw);

  final RawRow raw;

  int get id => asInt(raw['id'])!;
  int get pdgidId => asInt(raw['pdgid_id'])!;
  String get pdgid => asString(raw['pdgid']) ?? '';
  int get pdgitemId => asInt(raw['pdgitem_id'])!;
  String get name => asString(raw['name']) ?? '';
  bool get isOutgoing => asBool(raw['is_outgoing']);
  int get multiplier => asInt(raw['multiplier']) ?? 1;
  int? get subdecayId => asInt(raw['subdecay_id']);
  int get sort => asInt(raw['sort']) ?? 0;

  /// Joined `pdgitem` columns, if the caller selected them.
  String get itemType => asString(raw['item_type']) ?? '';
  String? get itemName => asString(raw['item_name']);

  List<RawField> get rawFields => [
        RawField('pdgdecay', 'id', raw['id']),
        RawField('pdgdecay', 'pdgid_id', raw['pdgid_id']),
        RawField('pdgdecay', 'pdgid', raw['pdgid']),
        RawField('pdgdecay', 'pdgitem_id', raw['pdgitem_id']),
        RawField('pdgdecay', 'name', raw['name']),
        RawField('pdgdecay', 'is_outgoing', raw['is_outgoing']),
        RawField('pdgdecay', 'multiplier', raw['multiplier']),
        RawField('pdgdecay', 'subdecay_id', raw['subdecay_id']),
        RawField('pdgdecay', 'sort', raw['sort']),
        if (raw.containsKey('item_type'))
          RawField('pdgitem', 'item_type', raw['item_type']),
        if (raw.containsKey('item_name'))
          RawField('pdgitem', 'name', raw['item_name']),
      ];
}

class DocRecord {
  const DocRecord(this.raw);

  final RawRow raw;

  int get id => asInt(raw['id'])!;
  String get tableName => asString(raw['table_name']) ?? '';
  String get columnName => asString(raw['column_name']) ?? '';
  String? get value => asString(raw['value']);
  String get indicator => asString(raw['indicator']) ?? '';
  String get description => asString(raw['description']) ?? '';
  String? get comment => asString(raw['comment']);

  List<RawField> get rawFields =>
      [for (final e in raw.entries) RawField('pdgdoc', e.key, e.value)];
}

/// Values, footnotes and bibliographic record that belong to one measurement.
class MeasurementBundle {
  const MeasurementBundle({
    required this.measurement,
    required this.values,
    required this.footnotes,
    required this.reference,
  });

  final Measurement measurement;
  final List<MeasurementValue> values;
  final List<Footnote> footnotes;
  final Reference? reference;

  MeasurementValue? get primaryValue {
    for (final value in values) {
      final name = value.columnName.toUpperCase();
      if (name == 'VALUE') return value;
    }
    for (final value in values) {
      if (value.value != null || value.displayValueText.isNotEmpty) {
        return value;
      }
    }
    return values.isEmpty ? null : values.first;
  }
}

/// A page of measurements, always containing complete measurement groups.
class MeasurementPage {
  const MeasurementPage({
    required this.items,
    required this.cursor,
    required this.hasMore,
    required this.totalCount,
  });

  final List<MeasurementBundle> items;
  final MeasurementCursor? cursor;
  final bool hasMore;
  final int totalCount;
}

class MeasurementCursor {
  const MeasurementCursor({required this.seriesPdgid, required this.sort, required this.id});

  final String seriesPdgid;
  final int sort;
  final int id;
}

/// One related quantity target (`pdgid_map` edge resolved to `pdgid`).
class RelatedQuantity {
  const RelatedQuantity({
    required this.edge,
    required this.target,
    required this.summaryCount,
    required this.measurementCount,
  });

  final EntryEdge edge;
  final Entry target;
  final int summaryCount;
  final int measurementCount;
}

class ItemResolution {
  const ItemResolution({
    required this.item,
    required this.chain,
    required this.directParticles,
    required this.mappedParticles,
    required this.candidates,
    required this.listings,
  });

  final ItemRecord item;
  final List<ItemRecord> chain;
  final List<Particle> directParticles;
  final List<Particle> mappedParticles;
  final List<Particle> candidates;
  final Set<String> listings;

  bool get isResolved => candidates.isNotEmpty;
  bool get isGeneric => const {'G', 'B', 'I'}.contains(item.itemType);
  bool get isAmbiguous =>
      !isGeneric && (listings.length > 1 || candidates.length > 1);
  bool get isMapped => mappedParticles.isNotEmpty;
  bool get isInclusive => item.itemType == 'I';
  bool get isText => item.itemType == 'T';
}
