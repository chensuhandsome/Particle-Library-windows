import '../../domain/models.dart';
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
  final title = (displayTitle ?? reference.displayTitle).trim();
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
