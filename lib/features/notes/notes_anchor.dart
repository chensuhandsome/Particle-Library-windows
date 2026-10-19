import '../../domain/models.dart';
import '../../domain/reference_title.dart';
import '../../notes/notes.dart';

/// Everything a page needs to add and list notes for one entity.
///
/// [anchors] are used to create a note, while [targets] are used to query
/// backlinks. Reference pages expose more than one target because a note may
/// have been anchored either by DOI or by `document_id`; P1 creates exactly one
/// anchor (DOI when present, otherwise `document_id`).
class NotesEntityContext {
  const NotesEntityContext({
    required this.label,
    required this.anchors,
    required this.targets,
  });

  final String label;
  final List<NoteAnchorInput> anchors;
  final List<NoteTarget> targets;

  bool get hasAnchor => anchors.isNotEmpty;
}

/// Default title for a newly captured note.
///
/// Keeps the identifier first and caps the title at 60 runes so a long
/// reference/particle description cannot push the identifier out of the
/// Notes list (the full provenance stays in the anchor).
String defaultNoteTitle({
  required String label,
  Iterable<NoteAnchorInput> anchors = const <NoteAnchorInput>[],
  String quote = '',
}) {
  final clean = label.replaceAll(RegExp(r'\s+'), ' ').trim();
  final identifier = _firstIdentifier(anchors);
  if (identifier == null || identifier.isEmpty || clean.isEmpty) {
    return _truncateRunes(clean, 60);
  }
  if (clean.runes.length <= 60) {
    final cleanQuote = quote.replaceAll(RegExp(r'\s+'), ' ').trim();
    final room = 60 - clean.runes.length - 4;
    if (cleanQuote.isEmpty || room < 8) return clean;
    return '$clean “${_truncateRunes(cleanQuote, room)}”';
  }
  if (clean == identifier || clean == '($identifier)') return identifier;
  final suffix = RegExp(r'[\s(]+' + RegExp.escape(identifier) + r'\)?\s*$');
  final description = clean.replaceFirst(suffix, '').trim();
  if (description.isEmpty) return identifier;
  final prefix = '$identifier — ';
  final room = 60 - prefix.runes.length;
  final base = '$prefix${_truncateRunes(description, room)}';
  final cleanQuote = quote.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (cleanQuote.isEmpty || cleanQuote == description) return base;
  final quoteRoom = 60 - base.runes.length - 4;
  if (quoteRoom < 8) return base;
  return '$base “${_truncateRunes(cleanQuote, quoteRoom)}”';
}

String? _firstIdentifier(Iterable<NoteAnchorInput> anchors) {
  for (final anchor in anchors) {
    switch (anchor.targetKind) {
      case NoteTargetKinds.pdgid:
      case NoteTargetKinds.measurement:
        final value = anchor.targetKey.trim();
        if (value.isNotEmpty) return value;
      case NoteTargetKinds.reference:
        final key = anchor.targetKey.trim();
        final colon = key.indexOf(':');
        final value = colon < 0 ? key : key.substring(colon + 1);
        if (value.isNotEmpty) return value;
      case NoteTargetKinds.review:
        final file = anchor.targetKey.split('/').last;
        if (file.isNotEmpty) {
          return file.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
        }
    }
  }
  return null;
}

String _truncateRunes(String value, int maxRunes) {
  if (maxRunes <= 0) return '';
  final runes = value.runes.toList(growable: false);
  if (runes.length <= maxRunes) return value;
  return '${String.fromCharCodes(runes.take(maxRunes - 1))}…';
}

/// `D0 (S032M)`, or just the identifier when the description is empty.
String pdgidAnchorLabel(String description, String pdgid) {
  final trimmedDescription = description.trim();
  final trimmedPdgid = pdgid.trim();
  if (trimmedDescription.isEmpty) return trimmedPdgid;
  if (trimmedPdgid.isEmpty) return trimmedDescription;
  return '$trimmedDescription ($trimmedPdgid)';
}

/// Series/property labels keep the parent entry visible:
/// `B⁰ › Mean life (S043M)`.
String seriesAnchorLabel(Entry entry, {Entry? parent}) {
  final base = pdgidAnchorLabel(entry.description, entry.pdgid);
  final parentDescription = parent?.description.trim() ?? '';
  if (parentDescription.isEmpty) return base;
  return '$parentDescription › $base';
}

/// `Review of Particle Physics (RPP2026)`, falling back to whichever part is
/// available.
String referenceAnchorLabel(Reference reference, {String? displayTitle}) {
  final title = cleanReferenceTitle(displayTitle ?? reference.displayTitle)
      .trim();
  final documentId = reference.documentId.trim();
  if (title.isEmpty) return documentId;
  if (documentId.isEmpty) return title;
  if (title == documentId) return documentId;
  return '$title ($documentId)';
}

NotesEntityContext particleNotesContext(
  Entry entry, {
  required String snapshotHash,
}) {
  final pdgid = entry.pdgid.trim();
  return NotesEntityContext(
    label: pdgidAnchorLabel(entry.description, pdgid),
    anchors: pdgid.isEmpty
        ? const <NoteAnchorInput>[]
        : <NoteAnchorInput>[
            NoteAnchorInput.pdgid(
              pdgid,
              snapshotHash: snapshotHash,
              targetLabel: pdgidAnchorLabel(entry.description, pdgid),
            ),
          ],
    targets: pdgid.isEmpty
        ? const <NoteTarget>[]
        : <NoteTarget>[NoteTarget.pdgid(pdgid)],
  );
}

NotesEntityContext seriesNotesContext(
  Entry entry, {
  Entry? parent,
  required String snapshotHash,
}) {
  final pdgid = entry.pdgid.trim();
  final label = seriesAnchorLabel(entry, parent: parent);
  return NotesEntityContext(
    label: label,
    anchors: pdgid.isEmpty
        ? const <NoteAnchorInput>[]
        : <NoteAnchorInput>[
            NoteAnchorInput.pdgid(
              pdgid,
              snapshotHash: snapshotHash,
              targetLabel: label,
            ),
          ],
    targets: pdgid.isEmpty
        ? const <NoteTarget>[]
        : <NoteTarget>[NoteTarget.pdgid(pdgid)],
  );
}

NotesEntityContext referenceNotesContext(
  Reference reference, {
  required String snapshotHash,
  String? displayTitle,
}) {
  final doi = reference.doi.trim();
  final documentId = reference.documentId.trim();
  final label = referenceAnchorLabel(reference, displayTitle: displayTitle);
  final anchors = <NoteAnchorInput>[
    if (doi.isNotEmpty)
      NoteAnchorInput.referenceDoi(
        doi,
        snapshotHash: snapshotHash,
        targetLabel: label,
      )
    else if (documentId.isNotEmpty)
      NoteAnchorInput.referenceDoc(
        documentId,
        snapshotHash: snapshotHash,
        targetLabel: label,
      ),
  ];
  return NotesEntityContext(
    label: label,
    anchors: anchors,
    targets: <NoteTarget>[
      if (doi.isNotEmpty) NoteTarget.referenceDoi(doi),
      if (documentId.isNotEmpty) NoteTarget.referenceDoc(documentId),
      // Older builds mistakenly anchored by the local pdgreference.id. Keep
      // those notes visible in the page until a migration can rewrite them.
      if (reference.id > 0 && reference.id.toString() != documentId)
        NoteTarget.referenceDoc('${reference.id}'),
    ],
  );
}
