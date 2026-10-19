import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../domain/models.dart';
import '../../domain/reference_title.dart';
import '../../user/user_store.dart';
import 'snack_bars.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.favorite,
    this.showLabel = false,
  });

  final Favorite favorite;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final store = scope.store;
    final strings = scope.strings;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final active = store.isFavorite(favorite.key);
        final label = active ? strings.favoritesRemove : strings.favoritesAdd;
        if (showLabel) {
          return TextButton.icon(
            onPressed: () => _toggle(context, active),
            icon: Icon(active ? Icons.star : Icons.star_border, size: 18),
            label: Text(label),
          );
        }
        return IconButton(
          tooltip: label,
          icon: Icon(
            active ? Icons.star : Icons.star_border,
            size: 20,
            color: active ? Theme.of(context).colorScheme.primary : null,
          ),
          onPressed: () => _toggle(context, active),
        );
      },
    );
  }

  Future<void> _toggle(BuildContext context, bool wasActive) async {
    final scope = AppScope.of(context);
    final strings = scope.strings;
    final added = await scope.store.toggleFavorite(favorite);
    if (!context.mounted) return;
    showUndoSnackBar(
      ScaffoldMessenger.of(context),
      message: added ? strings.favoritesAdded : strings.favoritesRemoved,
      undoLabel: strings.favoritesUndo,
      onUndo: () => scope.store.toggleFavorite(favorite),
    );
  }
}

Favorite entryFavorite({
  required Entry entry,
  required String snapshotHash,
  String? title,
  String? subtitle,
}) {
  return Favorite(
    kind: FavoriteKind.entry,
    title: title ?? entry.description,
    subtitle: subtitle ?? entry.pdgid,
    snapshotHash: snapshotHash,
    createdAt: DateTime.now(),
    pdgid: entry.pdgid,
  );
}

Favorite referenceFavorite({
  required Reference reference,
  required String snapshotHash,
}) {
  return Favorite(
    kind: FavoriteKind.reference,
    title: cleanReferenceTitle(reference.displayTitle),
    subtitle: [
      reference.documentId,
      if (reference.publicationYear != null) '${reference.publicationYear}',
    ].join(' · '),
    snapshotHash: snapshotHash,
    createdAt: DateTime.now(),
    referenceId: reference.id,
  );
}
