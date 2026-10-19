import 'package:flutter_test/flutter_test.dart';
import 'package:pdgapp/features/notes/notes_entity.dart';
import 'package:pdgapp/notes/notes.dart';

void main() {
  test('review anchors open the highlighted PDF page target', () {
    final anchor = NoteAnchor(
      id: 'a',
      noteId: 'n',
      targetKind: NoteTargetKinds.review,
      targetKey: '2026/rpp2026-rev-qcd.pdf',
      snapshotHash: '',
      targetLabel: 'Quantum chromodynamics · p.12',
      status: NoteAnchorStatus.exact,
      context: const {'annotationId': 'anno-1'},
      createdAt: DateTime.utc(2026),
    );
    expect(noteAnchorTarget(anchor), 'review:2026/rpp2026-rev-qcd.pdf#anno-1');
  });
}
