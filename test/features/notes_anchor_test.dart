import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/domain/models.dart';
import 'package:pdgapp/features/notes/notes_anchor.dart';
import 'package:pdgapp/notes/notes.dart';

Entry _entry({
  required int id,
  required String pdgid,
  required String description,
  int? parentId,
}) {
  return Entry(<String, Object?>{
    'id': id,
    'pdgid': pdgid,
    'description': description,
    'data_type': 'PART',
    'flags': '',
    'parent_id': parentId,
    'sort': 0,
  });
}

Reference _reference({
  required int id,
  required String documentId,
  String title = '',
  String doi = '',
}) {
  return Reference(<String, Object?>{
    'id': id,
    'document_id': documentId,
    'title': title,
    'doi': doi,
    'inspire_id': '',
    'publication_name': '',
    'publication_year': 2026,
  });
}

void main() {
  group('anchor label formatting', () {
    test('particle labels keep description and PDG identifier', () {
      expect(pdgidAnchorLabel('D0', 'S032M'), 'D0 (S032M)');
      expect(pdgidAnchorLabel('', 'S032M'), 'S032M');
      expect(pdgidAnchorLabel('D0', ''), 'D0');
      expect(pdgidAnchorLabel('  D0 ', ' S032M '), 'D0 (S032M)');
    });

    test('series labels include the parent description', () {
      final parent = _entry(id: 1, pdgid: 'M001', description: 'B0');
      final child = _entry(
        id: 2,
        pdgid: 'S043M',
        description: 'Mean life',
        parentId: 1,
      );
      expect(
        seriesAnchorLabel(child, parent: parent),
        'B0 › Mean life (S043M)',
      );
      expect(seriesAnchorLabel(child), 'Mean life (S043M)');
    });

    test('reference labels prefer title and always carry document_id', () {
      final reference = _reference(
        id: 7,
        documentId: 'RPP2026',
        title: 'Review of Particle Physics',
      );
      expect(
        referenceAnchorLabel(reference),
        'Review of Particle Physics (RPP2026)',
      );
      final untitled = _reference(id: 8, documentId: 'DOC8');
      expect(referenceAnchorLabel(untitled), 'DOC8');
    });
  });

  test('default titles keep the identifier first and stay within budget', () {
    final particle = defaultNoteTitle(
      label: 'a_0/Lambda**2, a_c/Lambda**2, a_n/Lambda**2, f(M,i)/Lambda**4 (S043AQC)',
      anchors: [NoteAnchorInput.pdgid('S043AQC', targetLabel: 'long particle')],
    );
    expect(particle, startsWith('S043AQC — '));
    expect(particle.runes.length, lessThanOrEqualTo(60));
    final reference = defaultNoteTitle(
      label: 'Determination of |Vcb| using B0 -> D*+ lepton neutrino decays with Belle II (ADACHI 2023J)',
      anchors: [NoteAnchorInput.referenceDoc('ADACHI 2023J')],
    );
    expect(reference, startsWith('ADACHI 2023J — '));
    expect(reference.runes.length, lessThanOrEqualTo(60));
    expect(
      defaultNoteTitle(
        label: 'D0 (S032M)',
        anchors: [NoteAnchorInput.pdgid('S032M')],
      ),
      'D0 (S032M)',
    );
  });

  test('particle context supplies one exact pdgid anchor and target', () {
    final entry = _entry(id: 1, pdgid: 'S032M', description: 'D0');
    final context = particleNotesContext(entry, snapshotHash: 'hash-1');

    expect(context.hasAnchor, isTrue);
    expect(context.label, 'D0 (S032M)');
    expect(context.anchors, hasLength(1));
    final anchor = context.anchors.single;
    expect(anchor.targetId, 'pdgid:S032M');
    expect(anchor.targetLabel, 'D0 (S032M)');
    expect(anchor.snapshotHash, 'hash-1');
    expect(anchor.status, NoteAnchorStatus.exact);
    expect(context.targets, hasLength(1));
    expect(context.targets.single.targetId, 'pdgid:S032M');
    expect(context.targets.single.snapshotHash, isNull);

    final empty = particleNotesContext(
      _entry(id: 2, pdgid: '', description: 'Anonymous'),
      snapshotHash: 'hash-1',
    );
    expect(empty.hasAnchor, isFalse);
    expect(empty.targets, isEmpty);
  });

  test('series context anchors the property PDGID with the parent label', () {
    final parent = _entry(id: 1, pdgid: 'M001', description: 'B0');
    final entry = _entry(
      id: 2,
      pdgid: 'S043M',
      description: 'Mean life',
      parentId: 1,
    );
    final context = seriesNotesContext(
      entry,
      parent: parent,
      snapshotHash: 'hash-2',
    );
    expect(context.label, 'B0 › Mean life (S043M)');
    expect(context.anchors.single.targetId, 'pdgid:S043M');
    expect(context.anchors.single.targetLabel, context.label);
    expect(context.targets.single.key, 'S043M');
  });

  test('reference context anchors DOI when present and queries both keys', () {
    final reference = _reference(
      id: 7,
      documentId: 'RPP2026',
      title: 'Review of Particle Physics',
      doi: '10.1103/PhysRevD.98.030001',
    );
    final context = referenceNotesContext(
      reference,
      snapshotHash: 'hash-3',
      displayTitle: 'RPP',
    );

    expect(context.label, 'RPP (RPP2026)');
    expect(context.anchors, hasLength(1));
    expect(
      context.anchors.single.targetId,
      'reference:doi:10.1103/physrevd.98.030001',
    );
    expect(context.anchors.single.snapshotHash, 'hash-3');
    expect(context.targets.map((target) => target.targetId).toList(), <String>[
      'reference:doi:10.1103/physrevd.98.030001',
      'reference:doc:RPP2026',
      'reference:doc:7',
    ]);
  });

  test('reference context falls back to document_id without a DOI', () {
    final reference = _reference(id: 8, documentId: 'DOC8', title: 'A paper');
    final context = referenceNotesContext(reference, snapshotHash: 'h');
    expect(context.anchors.single.targetId, 'reference:doc:DOC8');
    expect(context.targets, hasLength(2));
    expect(context.targets.first.targetId, 'reference:doc:DOC8');
    expect(context.targets.last.targetId, 'reference:doc:8');
  });
}
