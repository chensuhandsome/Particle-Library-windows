# Notes P0/P1 implementation plan

Status: notes, collections and branding are implemented on `main`. Historical
feature branches are archived outside the current release line.

## Product decisions

- Name: **Particle Library**.
- Notes are local-only. The PDG snapshot is never written or attached.
- Notes/anchors live in a separate SQLite database, never in `user_store.json`.
- PDF annotations are app-side data and never modify official PDG PDFs.
  Highlights currently live in a separate JSON sidecar; unifying them with the
  notes DB is the next planned step (see the PDF-annotation design notes).
- No feature may require macOS-only APIs; Windows/Linux/Android must be able to
  reuse the notes storage and editor.

## P0 — storage foundation

- `ParticleDesk/user.db`, SQLite WAL, `synchronous=FULL`, foreign keys,
  busy timeout, `quick_check`.
- Transactional `user_version` migrations and `VACUUM INTO` backup.
- Tables: notes, note_anchors, note_tags, indices.
- Anchor keys are semantic and carry snapshot hash plus the frozen label.
- API: create/update/delete/recent/notesForTarget/countForTargets/search/
  unresolved/allForExport/close.
- CJK-safe substring search (LIKE fallback; no unicode61-only search).
- Unit tests for CRUD, anchors, tags, reopen, CJK search, migration.

## P1 — entity notes MVP

- Fourth primary destination: Search / Favorites / Notes / Settings.
- Global Notes page: list, search, recent, empty state; wide list+editor,
  narrow list→editor.
- Markdown note editor with title, body, tags, anchor chips, autosave and
  save-status. Math stays as Markdown source in P1; preview can follow.
- Context sidebar gets a `Context | Notes N` tab with a quick composer and
  recent notes for the current entity.
- Anchors: particle (`pdgid`), property/series (`pdgid` + label), reference
  (`reference:doi` / `reference:doc`).
- Add-note entry points on particle, series and reference pages; note counts.
- Backlinks: notes for the current entity, batched counts, no N+1.
- Notes scope in Home search is P1 stretch, not an acceptance blocker.
- Markdown export of a note and an all-notes JSON backup.
- Tests: storage integration, editor autosave/delete, anchor linking,
  CJK search, no writes to snapshot/PDF caches.

## Out of scope

- Measurement/value anchors (P2).
- PDF highlights/comments (P3).
- Block refs/transclusion, graph view, daily notes, sync, collaboration.
- External PDF annotation interoperability.

## Acceptance

1. Create a note on a particle, property/series and reference; reopen the app
   and find it from the entity and the global Notes page.
2. Search Chinese and English note text.
3. Anchors survive reopening; unresolved anchors are shown, never silently
   rebound.
4. Notes DB failure does not prevent PDG lookups.
5. `flutter test` and `flutter analyze` clean; release app launches with the
   new name/icon.
