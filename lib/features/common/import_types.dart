import 'package:file_selector/file_selector.dart';

// File filters for the "open a file to import" pickers.
//
// Each group names its files in every form the platforms read: desktop uses
// `extensions`, Android turns extensions and `mimeTypes` into a MIME filter,
// and iOS reads only `uniformTypeIdentifiers` — its plugin throws before the
// picker opens when a group has none, so an extensions-only group makes the
// import button silently do nothing there.

/// A full backup (zip) or a notes-only export (json).
const fullBackupImportType = XTypeGroup(
  label: 'Particle Library backup',
  extensions: ['zip', 'json'],
  mimeTypes: [
    'application/zip',
    'application/x-zip-compressed',
    'application/json',
  ],
  uniformTypeIdentifiers: ['com.pkware.zip-archive', 'public.json'],
);

/// A notes export (json).
const notesJsonImportType = XTypeGroup(
  label: 'Particle Library notes',
  extensions: ['json'],
  mimeTypes: ['application/json'],
  uniformTypeIdentifiers: ['public.json'],
);
