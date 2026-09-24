import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/campaign/campaign_repository.dart';
import 'package:flutter/material.dart';

class SeckillScreen extends StatefulWidget {
  const SeckillScreen({super.key, required this.repository});

  final CampaignRepository repository;

  @override
  State<SeckillScreen> createState() => _SeckillScreenState();
}

class _SeckillScreenState extends State<SeckillScreen> {
  late Future<List<SeckillEvent>> _events;

  @override
  void initState() {
    super.initState();
    _events = widget.repository.seckill();
  }

  Future<void> _claim(SeckillEvent event) async {
    await widget.repository.claim(event.id);
    final future = widget.repository.seckill();
    setState(() => _events = future);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.seckillTitle)),
      body: FutureBuilder<List<SeckillEvent>>(
        future: _events,
        builder: (context, snapshot) {
          final events = snapshot.data ?? const <SeckillEvent>[];
          if (snapshot.connectionState == ConnectionState.done && events.isEmpty) {
            return Center(child: Text(strings.seckillEmpty));
          }
          return ListView(
            children: [
              for (final event in events)
                ListTile(
                  key: Key('seckill-${event.id}'),
                  title: Text(event.title),
                  subtitle: Text('${event.seckillPrice}  ${event.sold}/${event.stock}'),
                  trailing: TextButton(onPressed: () => _claim(event), child: Text(strings.seckillClaim)),
                ),
            ],
          );
        },
      ),
    );
  }
}
