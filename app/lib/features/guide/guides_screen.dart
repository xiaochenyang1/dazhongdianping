import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/guide/guide_repository.dart';
import 'package:flutter/material.dart';

class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key, required this.repository});

  final GuideRepository repository;

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  late Future<List<GuideArticle>> _guides;

  @override
  void initState() {
    super.initState();
    _guides = widget.repository.load();
  }

  Future<void> _open(GuideArticle guide) async {
    final detail = await widget.repository.detail(guide.id);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(detail.title)),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(detail.summary),
            for (final section in detail.sections) ...[
              const SizedBox(height: 12),
              Text(section.heading, style: Theme.of(context).textTheme.titleMedium),
              Text(section.body),
            ],
          ],
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.guidesTitle)),
      body: FutureBuilder<List<GuideArticle>>(
        future: _guides,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text(strings.guidesLoadFailed(snapshot.error!)));
          final guides = snapshot.data ?? const <GuideArticle>[];
          if (snapshot.connectionState == ConnectionState.done && guides.isEmpty) {
            return Center(child: Text(strings.guidesEmpty));
          }
          return ListView(
            children: [
              for (final guide in guides)
                ListTile(
                  key: Key('guide-${guide.id}'),
                  title: Text(guide.title),
                  subtitle: Text(guide.summary),
                  onTap: () => _open(guide),
                ),
            ],
          );
        },
      ),
    );
  }
}
