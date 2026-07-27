import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
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
      final order = await widget.repository.createOrder(
        dealId: deal.id,
        quantity: 1,
      );
      final reason = widget.thirdPartyConfig.unavailableReason(
        ThirdPartyFeature.payment,
      );
      if (!mounted) return;
      if (reason.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$reason 订单 ${order.orderNo} 已创建，可稍后支付。')),
        );
        return;
      }
      final intent = await widget.repository.createPayment(order.id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('请使用 ${intent.channel} 完成支付')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('下单失败：$error')));
      }
    } finally {
      if (mounted) setState(() => buying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('团购优惠')),
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
                  Text('团购加载失败：${snapshot.error}'),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    key: const Key('deals-retry'),
                    onPressed: reloading ? null : reload,
                    icon: const Icon(Icons.refresh),
                    label: Text(reloading ? '处理中...' : '重试'),
                  ),
                ],
              ),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) return const Center(child: Text('当前门店暂无团购'));
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
                              '${formatMoney(deal.price, deal.currency)} · 已售 ${deal.soldCount}',
                            ),
                            Text('库存 ${deal.stock}'),
                          ],
                        ),
                      ),
                      FilledButton(
                        onPressed: buying || deal.stock <= 0
                            ? null
                            : () => buy(deal),
                        child: const Text('购买'),
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
