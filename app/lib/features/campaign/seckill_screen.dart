import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/campaign/campaign_repository.dart';
import 'package:dazhongdianping_app/features/trade/order_detail_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_error_localizer.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';

class SeckillScreen extends StatefulWidget {
  const SeckillScreen({
    super.key,
    required this.repository,
    this.thirdPartyConfig = const ThirdPartyConfig(),
  });

  final CampaignRepository repository;
  final ThirdPartyConfig thirdPartyConfig;

  @override
  State<SeckillScreen> createState() => _SeckillScreenState();
}

class _SeckillScreenState extends State<SeckillScreen> {
  late Future<List<SeckillEvent>> _events;
  int? _actingId;
  String? _error;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _events = widget.repository.seckill();
  }

  @override
  void didUpdateWidget(covariant SeckillScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _generation++;
      _actingId = null;
      _error = null;
      _events = widget.repository.seckill();
    }
  }

  void _reload() => setState(() {
    _error = null;
    _events = widget.repository.seckill();
  });

  Future<void> _claim(SeckillEvent event) async {
    if (_actingId != null) return;
    final generation = _generation;
    setState(() {
      _actingId = event.id;
      _error = null;
    });
    try {
      final TradeOrder? order = event.orderId == null
          ? await widget.repository.claim(event.id)
          : null;
      if (!mounted || generation != _generation) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OrderDetailScreen(
            repository: TradeRepository(widget.repository.api),
            orderId: order?.id ?? event.orderId!,
            initialOrder: order,
            thirdPartyConfig: widget.thirdPartyConfig,
          ),
        ),
      );
      if (mounted && generation == _generation) _reload();
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

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.seckillTitle)),
      body: FutureBuilder<List<SeckillEvent>>(
        future: _events,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings.seckillLoadFailed),
                  TextButton(
                    key: const Key('seckill-retry'),
                    onPressed: _reload,
                    child: Text(strings.retry),
                  ),
                ],
              ),
            );
          }
          final events = snapshot.data ?? const <SeckillEvent>[];
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text(strings.seckillRules),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _error!,
                    key: const Key('seckill-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (events.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(strings.seckillEmpty),
                ),
              for (final event in events)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          key: Key('seckill-${event.id}'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${formatMoney(event.seckillPrice, event.currency, locale: strings.tag)} · ${strings.seckillStock} ${event.remaining}',
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          key: Key('seckill-buy-${event.id}'),
                          onPressed:
                              _actingId != null ||
                                  (event.orderId == null &&
                                      (event.remaining <= 0 ||
                                          event.participationStatus == 0))
                              ? null
                              : () => _claim(event),
                          child: Text(
                            _actingId == event.id
                                ? strings.seckillBuying
                                : event.orderId != null
                                ? strings.seckillViewOrder
                                : event.participationStatus == 0
                                ? strings.seckillLimitReached
                                : event.remaining <= 0
                                ? strings.seckillSoldOut
                                : strings.seckillClaim,
                          ),
                        ),
                      ],
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
