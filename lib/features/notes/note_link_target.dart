import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_scope.dart';
import '../../app/navigation.dart';
import 'note_editor.dart';
import '../reviews/review_link.dart';

/// Resolves every internal link scheme used by notes in one place.
///
/// Returns true when a page/note was opened (or an external URL launched), and
/// false when the target is missing, so callers can show one consistent
/// "unresolved link" message. This is the single opener for Markdown links,
/// anchor chips and link-preview buttons.
Future<bool> openNoteLinkTarget(BuildContext context, String target) async {
  final scope = AppScope.of(context);
  if (target.startsWith('pdgid:')) {
    final pdgid = target.substring(6).trim();
    if (pdgid.isEmpty) return false;
    await AppNav.openPdgid(context, pdgid);
    return true;
  }
  if (target.startsWith('measurement:')) {
    final key = target.substring('measurement:'.length);
    final pdgid = key.split(':').first.trim();
    if (pdgid.isEmpty) return false;
    await AppNav.openPdgid(context, pdgid);
    return true;
  }
  if (target.startsWith('reference:')) {
    if (target.startsWith('reference:doc:')) {
      final documentId = target.substring('reference:doc:'.length);
      final reference = await scope.database.referenceByDocumentId(documentId);
      if (!context.mounted) return false;
      if (reference != null) {
        await AppNav.openReference(context, reference.id);
        return true;
      }
      // Legacy notes stored the local pdgreference.id as a document id.
      final localId = int.tryParse(documentId);
      if (localId != null &&
          await scope.database.referenceById(localId) != null) {
        if (!context.mounted) return false;
        await AppNav.openReference(context, localId);
        return true;
      }
      return false;
    }
    if (target.startsWith('reference:doi:')) {
      final doi = target.substring('reference:doi:'.length);
      final references = await scope.database.referencesByDoi(doi);
      if (!context.mounted || references.isEmpty) return false;
      await AppNav.openReference(context, references.first.id);
      return true;
    }
    return false;
  }
  if (target.startsWith('review:')) {
    return openReviewLink(context, target);
  }
  if (target.startsWith('note:')) {
    final uuid = target.substring('note:'.length);
    final note = await scope.notes?.noteByUuid(uuid);
    if (!context.mounted || note == null) return false;
    await AppNav.push<void>(context, NoteEditorPage(note: note));
    return true;
  }
  final uri = Uri.tryParse(target);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}

/// Only these targets have a rich local preview. Other schemes (note,
/// measurement, external URLs) open directly and must not be handed to the
/// sidebar preview, which would show a dead "missing" state.
bool supportsNoteLinkPreview(String target) =>
    target.startsWith('pdgid:') || target.startsWith('reference:');
