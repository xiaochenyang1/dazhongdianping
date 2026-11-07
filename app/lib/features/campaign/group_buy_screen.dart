import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/campaign/campaign_repository.dart';
import 'package:dazhongdianping_app/features/trade/order_detail_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_error_localizer.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';

class GroupBuyScreen extends StatefulWidget {
  const GroupBuyScreen({
    super.key,
    required this.repository,
    this.thirdPartyConfig = const ThirdPartyConfig(),
  });

  final CampaignRepository repository;
  final ThirdPartyConfig thirdPartyConfig;

  @override
  State<GroupBuyScreen> createState() => _GroupBuyScreenState();
}

class _GroupBuyScreenState extends State<GroupBuyScreen> {
  late Future<List<GroupBuyCampaign>> _campaigns;
  final _teamId = TextEditingController();
  int? _actingId;
  bool _joining = false;
  String? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _campaigns = widget.repository.groupBuy();
  }

  @override
  void didUpdateWidget(covariant GroupBuyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _generation++;
      _actingId = null;
      _joining = false;
      _error = null;
      _campaigns = widget.repository.groupBuy();
    }
  }

  @override
  void dispose() {
    _generation++;
    _teamId.dispose();
    super.dispose();
  }

  void _reload() => setState(() {
    _error = null;
    _campaigns = widget.repository.groupBuy();
  });

  Future<void> _open(GroupBuyCampaign campaign) async {
    if (_actingId != null || _joining) return;
    final generation = _generation;
    setState(() {
      _actingId = campaign.id;
      _error = null;
    });
    try {
      final result = await widget.repository.openTeam(campaign.id);
      if (!mounted || generation != _generation) return;
      await _openOrder(result.order);
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(
          () =>
              _error = localizeTradeError(AppLocalizations.of(context), error),
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _actingId = null);
      }
    }
  }

  Future<void> _join() async {
    if (_actingId != null || _joining) return;
    final id = int.tryParse(_teamId.text.trim()) ?? 0;
    if (id <= 0) return;
    final generation = _generation;
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      final result = await widget.repository.joinTeam(id);
      if (!mounted || generation != _generation) return;
      await _openOrder(result.order);
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(
          () =>
              _error = localizeTradeError(AppLocalizations.of(context), error),
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _joining = false);
      }
    }
  }

  Future<void> _openOrder(TradeOrder order) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailScreen(
          repository: TradeRepository(widget.repository.api),
          orderId: order.id,
          initialOrder: order,
          thirdPartyConfig: widget.thirdPartyConfig,
        ),
      ),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.groupBuyTitle)),
      body: FutureBuilder<List<GroupBuyCampaign>>(
        future: _campaigns,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings.groupBuyLoadFailed),
                  TextButton(
                    key: const Key('groupbuy-retry'),
                    onPressed: _reload,
                    child: Text(strings.retry),
                  ),
                ],
              ),
            );
          }
          final campaigns = snapshot.data ?? const <GroupBuyCampaign>[];
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(strings.groupBuyRules),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('groupbuy-team-id'),
                      controller: _teamId,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: strings.groupBuyTeamId,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    key: const Key('groupbuy-join'),
                    onPressed: _actingId != null || _joining ? null : _join,
                    child: Text(
                      _joining ? strings.groupBuyJoining : strings.groupBuyJoin,
                    ),
                  ),
                ],
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _error!,
                    key: const Key('groupbuy-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (campaigns.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(strings.groupBuyEmpty),
                ),
              for (final campaign in campaigns)
                Card(
                  child: ListTile(
                    key: Key('groupbuy-${campaign.id}'),
                    title: Text(campaign.title),
                    subtitle: Text(
                      '${formatMoney(campaign.groupPrice, campaign.currency, locale: strings.tag)} · ${strings.groupBuySize(campaign.groupSize)}',
                    ),
                    trailing: TextButton(
                      key: Key('groupbuy-open-${campaign.id}'),
                      onPressed: _actingId != null || _joining
                          ? null
                          : () => _open(campaign),
                      child: Text(
                        _actingId == campaign.id
                            ? strings.groupBuyOpening
                            : strings.groupBuyOpen,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
