import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pdgapp/app/app_scope.dart';
import 'package:pdgapp/app/app_theme.dart';
import 'package:pdgapp/app/bootstrap.dart';
import 'package:pdgapp/core/app_paths.dart';
import 'package:pdgapp/core/contract.dart';
import 'package:pdgapp/data/pdg_notes.dart';
import 'package:pdgapp/data/review_cache.dart';
import 'package:pdgapp/data/snapshot_store.dart';
import 'package:pdgapp/features/reviews/region_export.dart';
import 'package:pdgapp/features/reviews/review_viewer_page.dart';
import 'package:pdgapp/notes/notes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Windows first install, offline search, native PDF pages and restart',
    (tester) async {
      final parent = await Directory(
        '${(await getTemporaryDirectory()).path}/particle-native-tests',
      ).create(recursive: true);
      final sandbox = await parent.createTemp('windows-smoke-');
      final previousPaths = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _IsolatedPaths(sandbox.path);
      resetAppSupportDirectoryCache();
      PdgNotes.resetCache();
      final services = await AppBootstrap.load();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 300));
        await services.reviewSearch?.dispose();
        await services.notes?.close();
        await services.database.executor.dispose();
        PathProviderPlatform.instance = previousPaths;
        resetAppSupportDirectoryCache();
        PdgNotes.resetCache();
        expect(sandbox.parent.absolute.path, parent.absolute.path);
        await sandbox.delete(recursive: true);
      });
      expect(services.copiedFromBundle, isTrue);
      expect(services.snapshotHash, SnapshotContract.expectedSha256);
      expect((await SnapshotStore().prepare()).copiedFromBundle, isFalse);
      expect(services.notesError, isNull);
      expect(services.notes, isNotNull);
      expect((await PdgNotes.forPdgid('M252'))?.summary, contains('two poles'));
      expect(AppTheme.light().textTheme.bodyMedium?.fontFamily, 'Segoe UI');
      expect(AppFonts.monospaceFamily, 'Consolas');
      await services.settings.setLocale('en');

      final search = services.reviewSearch!;
      final manifest = jsonDecode(
        await rootBundle.loadString('assets/review_sources_2026.json'),
      ) as Map<String, dynamic>;
      final sources = {
        for (final raw in manifest['sources'] as List)
          (raw as Map<String, dynamic>)['file'] as String: raw,
      };
      final cache = await ReviewCache.open();
      final gates = [
        ('CG coefficients', 'rpp2026-rev-clebsch-gordan-coefs.pdf', 1),
        ('hadronic cross sections', 'rpp2026-rev-cross-section-plots.pdf', 5),
        (
          'average hadron multiplicities',
          'rpp2026-rev-cross-section-plots.pdf',
          2,
        ),
      ];
      for (final (query, file, physicalPage) in gates) {
        final result = await search.search(query);
        expect(result.degraded, isFalse);
        expect(result.hits.first.file, file);
        expect(result.hits.first.page, physicalPage);
        final source = sources[file]!;
        var receivedBytes = 0;
        final pdf = await cache.download(
          fileName: file,
          url: source['url'] as String,
          onProgress: (received, _) => receivedBytes = received,
        );
        final bytes = await pdf.readAsBytes();
        expect(sha256.convert(bytes).toString(), source['sha256']);
        expect(bytes.length, greaterThan(0));
        // A cached review opens even when the URL cannot be contacted.
        expect(
          (await cache.download(
            fileName: file,
            url: 'https://127.0.0.1:1/offline',
          )).path,
          pdf.path,
        );
        debugPrint(
          'WINDOWS gate "$query" -> $file p$physicalPage; '
          'download progress=$receivedBytes bytes',
        );
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(query),
            theme: AppTheme.light(),
            home: AppScope(
              services: services,
              child: ReviewViewerPage(
                title: result.hits.first.title,
                path: pdf.path,
                officialUrl: source['url'] as String,
                initialPage: physicalPage,
              ),
            ),
          ),
        );
        PdfViewerController? controller;
        for (var attempt = 0; attempt < 300; attempt++) {
          await tester.pump(const Duration(milliseconds: 50));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          if (find.byType(PdfViewer).evaluate().isEmpty) continue;
          controller = tester
              .widget<PdfViewer>(find.byType(PdfViewer))
              .controller;
          if (controller?.isReady == true &&
              controller!.pageNumber == physicalPage) {
            break;
          }
        }
        expect(controller?.isReady, isTrue);
        // Let native page metrics and the late reader layout finish before
        // checking the requested physical page.
        for (var frame = 0; frame < 10; frame++) {
          await tester.pump(const Duration(milliseconds: 50));
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
        }
        expect(controller!.pageNumber, physicalPage);
        final page = await controller.pages[physicalPage - 1].ensureLoaded();
        final image = await page.render(width: 256, height: 256);
        expect(image, isNotNull);
        final bitmap = await image!.createImage();
        final png = await bitmap.toByteData(format: ui.ImageByteFormat.png);
        bitmap.dispose();
        image.dispose();
        expect(png, isNotNull);
        final paths = regionExportPaths(
          '${sandbox.path}/region $physicalPage.MD',
        );
        await File(paths.image).writeAsBytes(png!.buffer.asUint8List());
        await File(paths.markdown).writeAsString(
          regionMarkdown(
            imageName: File(paths.image).uri.pathSegments.last,
            comment: query,
          ),
        );
        expect(paths.markdown, endsWith('.MD'));
        expect(await File(paths.markdown).readAsString(), contains(query));
        expect(await File(paths.image).length(), greaterThan(100));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 300));
      }
      final index = File(
        '${sandbox.path}/support/ParticleDesk/review_index/2026/'
        'review_index.sqlite',
      );
      expect(await index.length(), 15003648);
      final note = await services.notes!.create(
        title: 'Windows persistence',
        bodyMarkdown: 'A native note after an upstream update.',
      );
      final notesPath = services.notes!.storagePath;
      await services.notes!.close();
      final reopened = await NotesStore.open(overridePath: notesPath);
      try {
        expect(
          (await reopened.noteByUuid(note.uuid))?.bodyMarkdown,
          contains('upstream update'),
        );
      } finally {
        await reopened.close();
      }
      // Search again using the already staged index, with no network operation.
      expect((await search.search('CG coefficients')).hits.first.page, 1);
      debugPrint(
        'WINDOWS first-install, FTS5, native PDF gates, exports and '
        'note restart checks passed.',
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
    skip: !Platform.isWindows,
  );
}

class _IsolatedPaths extends PathProviderPlatform {
  _IsolatedPaths(this.root);
  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => '$root/support';

  @override
  Future<String?> getTemporaryPath() async => root;
}
