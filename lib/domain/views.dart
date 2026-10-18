import 'display.dart';
import 'labels.dart';
import 'models.dart';

class ParticleView {
  const ParticleView({
    required this.entry,
    required this.particles,
    required this.ancestors,
    required this.descendants,
    required this.summariesByEntry,
    required this.summaryCounts,
    required this.measurementCounts,
    required this.texts,
    required this.referenceCount,
    required this.currentEdition,
  });

  final Entry entry;
  final List<Particle> particles;
  final List<Entry> ancestors;
  final List<Entry> descendants;
  final Map<int, List<Summary>> summariesByEntry;
  final Map<int, int> summaryCounts;
  final Map<int, int> measurementCounts;
  final List<SectionText> texts;
  final int referenceCount;
  final String currentEdition;

  bool get hasIdentity => particles.isNotEmpty;

  List<Entry> get properties => descendants
      .where((row) =>
          row.id != entry.id &&
          !isDecayType(row.dataType) &&
          row.dataType != 'PART')
      .toList(growable: false);

  List<Entry> get decays => descendants
      .where((row) => isDecayType(row.dataType))
      .toList(growable: false);

  int get propertySeriesCount => properties
      .where((row) => (summaryCounts[row.id] ?? 0) > 0 || (measurementCounts[row.id] ?? 0) > 0)
      .length;

  int get decayCount => decays.length;

  bool get hasDecayStructureIssues => decays.any((row) {
        final summaries = summariesByEntry[row.id] ?? const <Summary>[];
        return summaries.isEmpty;
      });

  SummarySelection summaryFor(int entryId) =>
      selectBestSummary(summariesByEntry[entryId] ?? const []);

  int currentSummaryCount(int entryId) => summaryCounts[entryId] ?? 0;
  int measurementCount(int entryId) => measurementCounts[entryId] ?? 0;

  List<SectionText> textsFor(int entryId) =>
      texts.where((text) => text.pdgidId == entryId).toList(growable: false);

  Map<int, Entry> get byId => {
        for (final row in descendants) row.id: row,
      };

  Entry? parentOf(Entry row) {
    final parentId = row.parentId;
    if (parentId == null) return null;
    return byId[parentId];
  }

  List<Entry> sectionPathFor(Entry row) {
    final path = <Entry>[];
    Entry? current = row;
    var guard = 0;
    while (current != null && current.id != entry.id && guard < 20) {
      if (current.dataType == 'SEC') path.insert(0, current);
      current = parentOf(current);
      guard++;
    }
    return path;
  }

  List<Entry> childPropertiesOf(int parentId) => properties
      .where((row) => row.parentId == parentId)
      .toList(growable: false);

  List<Entry> childDecaysOf(int parentId) => decays
      .where((row) => row.parentId == parentId)
      .toList(growable: false);
}

class SeriesView {
  const SeriesView({
    required this.entry,
    required this.ancestors,
    required this.texts,
    required this.summaries,
    required this.currentSummaries,
    required this.footnotes,
    required this.relatedSources,
    required this.directMeasurementCount,
    required this.currentEdition,
    this.siblings = const [],
  });

  final Entry entry;
  final List<Entry> ancestors;
  final List<SectionText> texts;
  final List<Summary> summaries;
  final List<Summary> currentSummaries;
  final List<Footnote> footnotes;
  final List<RelatedQuantity> relatedSources;
  final int directMeasurementCount;
  final String currentEdition;
  final List<Entry> siblings;

  SummarySelection get selection => selectBestSummary(currentSummaries);

  List<String> get historyEditions {
    final seen = <String>[];
    for (final row in summaries) {
      final edition = row.edition;
      if (edition != null && !seen.contains(edition)) seen.add(edition);
    }
    return seen;
  }

  List<Summary> summariesForEdition(String edition) =>
      summaries.where((row) => row.edition == edition).toList(growable: false);

  bool get isBranchingRatio => entry.dataType == 'BR';
  bool get isDecayMode => isDecayType(entry.dataType);

  List<SectionText> get definitionTexts =>
      texts.where((text) => text.pdgidId == entry.id).toList(growable: false);
}

class ModeView {
  const ModeView({
    required this.entry,
    required this.ancestors,
    required this.texts,
    required this.tokens,
    required this.resolutions,
    required this.related,
    required this.children,
    required this.summaries,
    required this.currentSummaries,
    required this.footnotes,
    required this.directMeasurementCount,
    required this.currentEdition,
  });

  final Entry entry;
  final List<Entry> ancestors;
  final List<SectionText> texts;
  final List<DecayToken> tokens;
  final Map<int, ItemResolution> resolutions;
  final List<RelatedQuantity> related;
  final List<Entry> children;
  final List<Summary> summaries;
  final List<Summary> currentSummaries;
  final List<Footnote> footnotes;
  final int directMeasurementCount;
  final String currentEdition;

  bool get hasOutgoing => tokens.any((token) => token.isOutgoing);
  bool get hasIncoming => tokens.any((token) => !token.isOutgoing);
  bool get hasInclusive => tokens.any((token) => token.itemType == 'I');
  bool get hasTextTokens => tokens.any((token) => token.itemType == 'T');
  bool get hasArrowToken => tokens.any((token) => token.name.contains('-->'));

  int get arrowCount {
    final match = RegExp(r'-->').allMatches(entry.description).length;
    return match;
  }

  bool get isMultiStage => arrowCount > 1 || hasArrowToken;

  bool get hasStructureData => hasOutgoing;
  bool get isStructureIncomplete => !hasOutgoing;

  SummarySelection get selection => selectBestSummary(currentSummaries);

  List<RelatedQuantity> get relatedWithMeasurements =>
      related.where((row) => row.measurementCount > 0).toList(growable: false);

  List<SectionText> get definitionTexts {
    final fromAncestors = texts.where((text) => text.pdgidId != entry.id).toList();
    final own = texts.where((text) => text.pdgidId == entry.id).toList();
    return [...fromAncestors, ...own];
  }

  bool tokenResolved(DecayToken token) =>
      resolutions[token.pdgitemId]?.isResolved ?? false;
}

class EntryView {
  const EntryView({
    required this.entry,
    required this.ancestors,
    required this.particles,
    required this.children,
    required this.texts,
    required this.currentSummaries,
    required this.currentSummaryCount,
    required this.measurementCount,
    required this.currentEdition,
    this.summariesByEntry = const {},
  });

  final Entry entry;
  final List<Entry> ancestors;
  final List<Particle> particles;
  final List<Entry> children;
  final List<SectionText> texts;
  final List<Summary> currentSummaries;
  final int currentSummaryCount;
  final int measurementCount;
  final String currentEdition;
  final Map<int, List<Summary>> summariesByEntry;

  bool get hasIdentity => particles.isNotEmpty;
  SummarySelection selectionForChild(int entryId) =>
      selectBestSummary(summariesByEntry[entryId] ?? const []);
  SummarySelection get selection => selectBestSummary(currentSummaries);

  List<SectionText> get definitionTexts =>
      texts.where((text) => text.pdgidId == entry.id).toList(growable: false);
}
