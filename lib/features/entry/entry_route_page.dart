import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/app_theme.dart';
import '../../domain/labels.dart';
import '../../domain/models.dart';
import '../common/async_view.dart';
import '../common/page.dart';
import '../decay/mode_page.dart';
import '../entry/particle_page.dart';
import '../entry/topic_page.dart';
import '../series/series_page.dart';

class EntryRoutePage extends StatefulWidget {
  const EntryRoutePage({super.key, required this.pdgid});

  final String pdgid;

  @override
  State<EntryRoutePage> createState() => _EntryRoutePageState();
}

class _EntryRoutePageState extends State<EntryRoutePage> {
  late Future<({Entry entry, bool isSeries})> _future;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _future = _load();
  }

  Future<({Entry entry, bool isSeries})> _load() async {
    final repository = AppScope.of(context).repository;
    final entry = await repository.requireEntry(widget.pdgid);
    final isSeries = await repository.isPropertySeries(entry);
    return (entry: entry, isSeries: isSeries);
  }

  void _retry() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppScope.of(context).strings;
    return FutureBuilder<({Entry entry, bool isSeries})>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return PageScaffold(
            title: Text(widget.pdgid),
            subtitle: strings.commonLoading,
            body: const Center(child: LoadingPanel()),
          );
        }
        if (snapshot.hasError) {
          return PageScaffold(
            title: Text(widget.pdgid),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(Insets.l),
                child: ErrorPanel(error: snapshot.error!, onRetry: _retry),
              ),
            ),
          );
        }
        final data = snapshot.data!;
        final entry = data.entry;
        if (entry.dataType == 'PART') {
          return ParticlePage(entry: entry);
        }
        if (isDecayType(entry.dataType)) {
          return DecayModePage(entry: entry);
        }
        if (data.isSeries) {
          return SeriesPage(entry: entry);
        }
        return TopicPage(entry: entry);
      },
    );
  }
}
