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
  late Future<TradeOrderPage> _orders;
  bool _loadingMore = false;
  bool _retrying = false;
  final Set<int> _openingOrderIds = <int>{};
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _payStatus = widget.initialPayStatus;
    _orders = widget.repository.loadOrderPage(payStatus: _payStatus);
  }

  void _reload() {
    _requestId++;
    final future = widget.repository.loadOrderPage(payStatus: _payStatus);
    setState(() {
      _orders = future;
      _loadingMore = false;
    });
  }

  Future<void> _retry() async {
    if (_retrying) return;
    _requestId++;
    final future = widget.repository.loadOrderPage(payStatus: _payStatus);
    setState(() {
      _orders = future;
      _loadingMore = false;
      _retrying = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  Future<void> _loadMore(TradeOrderPage current) async {
    if (_loadingMore || !current.hasMore) return;
    final requestId = _requestId;
    setState(() => _loadingMore = true);
    try {
      final next = await widget.repository.loadOrderPage(
        payStatus: _payStatus,
        page: current.page + 1,
        pageSize: current.pageSize,
      );
      if (!mounted || requestId != _requestId) return;
      final knownIds = current.items.map((item) => item.id).toSet();
      final items = [
        ...current.items,
        ...next.items.where((item) => knownIds.add(item.id)),
      ];
      setState(() {
        _orders = Future.value(
          TradeOrderPage(
            items: items,
            total: next.total,
            page: next.page,
            pageSize: current.pageSize,
          ),
        );
      });
    } catch (error) {
      if (mounted && requestId == _requestId) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载更多订单失败：$error')));
      }
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loadingMore = false);
      }
    }
  }

  void _selectPayStatus(int? payStatus) {
    if (_payStatus == payStatus) return;
    setState(() => _payStatus = payStatus);
    _reload();
  }

  Future<void> _openOrder(TradeOrder order) async {
    if (_openingOrderIds.contains(order.id)) return;
    setState(() => _openingOrderIds.add(order.id));
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(
            repository: widget.repository,
            orderId: order.id,
          ),
        ),
      );
      if (mounted) _reload();
    } finally {
      if (mounted) {
        setState(() => _openingOrderIds.remove(order.id));
      }
    }
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
            child: FutureBuilder<TradeOrderPage>(
              future: _orders,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('订单加载失败：${snapshot.error}'),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          key: const Key('orders-retry'),
                          onPressed: _retrying ? null : _retry,
                          icon: const Icon(Icons.refresh),
                          label: Text(_retrying ? '处理中...' : '重试'),
                        ),
                      ],
                    ),
                  );
                }
                final page = snapshot.data!;
                final items = page.items;
                if (items.isEmpty) {
                  return const Center(child: Text('当前筛选下暂无订单'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: items.length + (page.hasMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == items.length) {
                      return Center(
                        child: OutlinedButton.icon(
                          key: const Key('orders-load-more'),
                          onPressed: _loadingMore
                              ? null
                              : () => _loadMore(page),
                          icon: _loadingMore
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.expand_more),
                          label: Text(_loadingMore ? '加载中...' : '加载更多'),
                        ),
                      );
                    }
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
                        onTap: _openingOrderIds.contains(order.id)
                            ? null
                            : () => _openOrder(order),
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
