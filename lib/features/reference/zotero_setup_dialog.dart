import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_strings.dart';
import '../../data/zotero_inspire_api.dart';

const String zoteroInspireReleasePage =
    'https://github.com/fkguo/zotero-inspire/releases/latest';

enum ZoteroSetupReason { missing, tooOld }

ZoteroSetupReason zoteroSetupReasonFor(ZoteroInspireStatus status) {
  return status.available
      ? ZoteroSetupReason.tooOld
      : ZoteroSetupReason.missing;
}

/// Explains why direct Zotero adding is unavailable and offers the release page.
///
/// Returns true when the caller should copy BibTeX instead.
Future<bool> showZoteroInspireSetupDialog(
  BuildContext context, {
  required AppStrings strings,
  required ZoteroSetupReason reason,
  String? currentVersion,
  bool zoteroRunning = true,
  bool offerBibtex = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      final body = reason == ZoteroSetupReason.tooOld
          ? strings.zoteroInspireSetupTooOld(currentVersion ?? '?')
          : strings.zoteroInspireSetupMissing;
      return AlertDialog(
        title: Text(strings.zoteroInspireSetupTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(body),
              if (!zoteroRunning) ...[
                const SizedBox(height: 8),
                Text(
                  strings.zoteroInspireSetupNotRunning,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                strings.zoteroInspireSetupHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          if (offerBibtex)
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(strings.zoteroInspireCopyBibtex),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.commonCancel),
          ),
          FilledButton.icon(
            onPressed: () async {
              final uri = Uri.parse(zoteroInspireReleasePage);
              final launched = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (!context.mounted) return;
              if (!launched) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.zoteroInspireSetupTitle)),
                );
                return;
              }
              Navigator.of(context).pop(false);
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: Text(strings.zoteroInspireOpenRelease),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
