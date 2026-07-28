import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/trade/order_detail_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';

class DealsScreen extends StatefulWidget {
  const DealsScreen({
    super.key,
    required this.repository,
    required this.shopId,
    required this.thirdPartyConfig,
  });
  final TradeRepository repository;
  final int shopId;
  final ThirdPartyConfig thirdPartyConfig;

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  late Future<List<DealSummary>> deals;
  bool buying = false;
  bool reloading = false;

  @override
  void initState() {
    super.initState();
    deals = widget.repository.loadShopDeals(widget.shopId);
  }

  Future<void> reload() async {
    if (reloading) return;
    final future = widget.repository.loadShopDeals(widget.shopId);
    setState(() {
      deals = future;
      reloading = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => reloading = false);
    }
  }

  Future<void> buy(DealSummary deal) async {
    if (buying) return;
    setState(() => buying = true);
    try {
      late TradeOrder order;
      try {
        order = await widget.repository.createOrder(
          dealId: deal.id,
          quantity: 1,
        );
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).createOrderFailed(error))));
        }
        return;
      }
      if (!mounted) return;
      try {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(
              repository: widget.repository,
              orderId: order.id,
              initialOrder: order,
              thirdPartyConfig: widget.thirdPartyConfig,
            ),
          ),
        );
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).orderCreatedOpenDetailFailed(order.orderNo, error))),
          );
        }
      }
    } finally {
      if (mounted) setState(() => buying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.groupDeals)),
      body: FutureBuilder<List<DealSummary>>(
        future: deals,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings.dealsLoadFailed(snapshot.error!)),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    key: const Key('deals-retry'),
                    onPressed: reloading ? null : reload,
                    icon: const Icon(Icons.refresh),
                    label: Text(reloading ? strings.processing : strings.retry),
                  ),
                ],
              ),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) return Center(child: Text(strings.noDealsForShop));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final deal = items[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deal.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              strings.priceSoldMeta(
                                price: formatMoney(deal.price, deal.currency),
                                count: deal.soldCount,
                              ),
                            ),
                            Text(strings.stockCount(deal.stock)),
                          ],
                        ),
                      ),
                      FilledButton(
                        key: Key('deal-action-${deal.id}'),
                        onPressed: buying || deal.stock <= 0
                            ? null
                            : () => buy(deal),
                        child: Text(strings.buy),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
