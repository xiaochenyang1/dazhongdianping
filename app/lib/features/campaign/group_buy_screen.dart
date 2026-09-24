import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/campaign/campaign_repository.dart';
import 'package:flutter/material.dart';

class GroupBuyScreen extends StatefulWidget {
  const GroupBuyScreen({super.key, required this.repository});

  final CampaignRepository repository;

  @override
  State<GroupBuyScreen> createState() => _GroupBuyScreenState();
}

class _GroupBuyScreenState extends State<GroupBuyScreen> {
  late Future<List<GroupBuyCampaign>> _campaigns;
  final _teamId = TextEditingController();

  @override
  void initState() {
    super.initState();
    _campaigns = widget.repository.groupBuy();
  }

  @override
  void dispose() {
    _teamId.dispose();
    super.dispose();
  }

  Future<void> _open(GroupBuyCampaign campaign) async {
    final id = await widget.repository.openTeam(campaign.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('#$id')));
  }

  Future<void> _join() async {
    final id = int.tryParse(_teamId.text.trim()) ?? 0;
    if (id == 0) return;
    await widget.repository.joinTeam(id);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.groupBuyTitle)),
      body: FutureBuilder<List<GroupBuyCampaign>>(
        future: _campaigns,
        builder: (context, snapshot) {
          final campaigns = snapshot.data ?? const <GroupBuyCampaign>[];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: TextField(controller: _teamId, decoration: const InputDecoration(labelText: 'teamId'))),
                  TextButton(onPressed: _join, child: Text(strings.groupBuyJoin)),
                ],
              ),
              for (final campaign in campaigns)
                ListTile(
                  key: Key('groupbuy-${campaign.id}'),
                  title: Text(campaign.title),
                  subtitle: Text('${campaign.groupPrice} / ${campaign.groupSize}'),
                  trailing: TextButton(onPressed: () => _open(campaign), child: Text(strings.groupBuyOpen)),
                ),
            ],
          );
        },
      ),
    );
  }
}
