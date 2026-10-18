import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/navigation.dart';
import '../../data/review_annotation_notes.dart';
import '../../data/review_cache.dart';
import 'review_index.dart';
import 'review_viewer_page.dart';
import 'reviews_page.dart';

/// Opens `review:<edition>/<file>#<annotationId>` from a note.
///
/// The PDF is a cache: if it is absent, the user is offered the review list
/// instead of a generic "link missing" error.
Future<bool> openReviewLink(BuildContext context, String target) async {
  final body = target.substring('review:'.length);
  final hash = body.indexOf('#');
  final key = hash < 0 ? body : body.substring(0, hash);
  final annotationId = hash < 0 ? '' : body.substring(hash + 1);
  final slash = key.indexOf('/');
  final file = slash < 0 ? key : key.substring(slash + 1);
  final entry = reviewEntryForFile(file);
  if (entry == null) return false;

  final notes = AppScope.of(context).notes;
  var page = 1;
  if (notes != null && annotationId.isNotEmpty) {
    final annotations = await ReviewAnnotationNotes.load(
      notes,
      entry.file,
      reviewTitle: entry.title,
    );
    for (final annotation in annotations) {
      if (annotation.id == annotationId) {
        page = annotation.pageNumber;
        break;
      }
    }
  }

  final cache = await ReviewCache.open();
  final local = cache.fileFor(entry.file);
  if (!await local.exists()) {
    if (!context.mounted) return true;
    final strings = AppScope.of(context).strings;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.reviewNotCached),
        action: SnackBarAction(
          label: strings.reviewsTitle,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ReviewsPage()),
            );
          },
        ),
      ),
    );
    return true;
  }
  if (!context.mounted) return true;
  await AppNav.push<void>(
    context,
    ReviewViewerPage(
      title: entry.title,
      path: local.path,
      officialUrl: entry.url,
      initialPage: page,
    ),
  );
  return true;
}
