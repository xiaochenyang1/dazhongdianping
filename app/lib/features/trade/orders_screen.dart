import 'package:dazhongdianping_app/features/trade/order_detail_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({
    super.key,
    required this.repository,
    this.initialPayStatus,
  });

  final TradeRepository repository;
  final int? initialPayStatus;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const _tabs = <({int? payStatus, String label})>[
    (payStatus: null, label: '全部'),
    (payStatus: 0, label: '待支付'),
    (payStatus: 1, label: '已支付'),
    (payStatus: 2, label: '已退款'),
    (payStatus: 3, label: '部分退款'),
  ];

  late int? _payStatus;
  late Future<List<TradeOrder>> _orders;

  @override
  void initState() {
    super.initState();
    _payStatus = widget.initialPayStatus;
    _orders = widget.repository.loadOrders(payStatus: _payStatus);
  }

  void _reload() {
    final future = widget.repository.loadOrders(payStatus: _payStatus);
    setState(() {
      _orders = future;
    });
  }

  void _selectPayStatus(int? payStatus) {
    if (_payStatus == payStatus) return;
    setState(() => _payStatus = payStatus);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的订单')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: _tabs
                  .map(
                    (tab) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        key: Key('order-tab-${tab.payStatus ?? 'all'}'),
                        label: Text(tab.label),
                        selected: _payStatus == tab.payStatus,
                        onSelected: (_) => _selectPayStatus(tab.payStatus),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<TradeOrder>>(
              future: _orders,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('订单加载失败：${snapshot.error}'));
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return const Center(child: Text('当前筛选下暂无订单'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final order = items[index];
                    return Card(
                      key: Key('order-card-${order.id}'),
                      child: ListTile(
                        title: Text(
                          order.dealTitle.isEmpty
                              ? order.orderNo
                              : order.dealTitle,
                        ),
                        subtitle: Text(
                          '${order.orderNo}\n${order.shopName} · ${order.payStatusText} · ${order.currency} ${order.amount}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(
                                  repository: widget.repository,
                                  orderId: order.id,
                                ),
                              ),
                            )
                            .then((_) {
                              if (mounted) _reload();
                            }),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
