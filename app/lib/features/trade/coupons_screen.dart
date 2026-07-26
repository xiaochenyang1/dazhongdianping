import 'package:dazhongdianping_app/features/trade/order_detail_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({
    super.key,
    required this.repository,
    this.initialStatus,
    this.highlightCode,
  });

  final TradeRepository repository;
  final int? initialStatus;
  final String? highlightCode;

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  static const _tabs = <({int? status, String label})>[
    (status: null, label: '全部'),
    (status: 1, label: '待使用'),
    (status: 2, label: '已使用'),
    (status: 3, label: '已过期'),
    (status: 4, label: '已退款'),
  ];

  late int? _status;
  late Future<CouponPage> _coupons;
  bool _loadingMore = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _coupons = widget.repository.loadCouponPage(status: _status);
  }

  void _reload() {
    _requestId++;
    final future = widget.repository.loadCouponPage(status: _status);
    setState(() {
      _coupons = future;
      _loadingMore = false;
    });
  }

  Future<void> _loadMore(CouponPage current) async {
    if (_loadingMore || !current.hasMore) return;
    final requestId = _requestId;
    setState(() => _loadingMore = true);
    try {
      final next = await widget.repository.loadCouponPage(
        status: _status,
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
        _coupons = Future.value(
          CouponPage(
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
        ).showSnackBar(SnackBar(content: Text('加载更多券码失败：$error')));
      }
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loadingMore = false);
      }
    }
  }

  void _selectStatus(int? status) {
    if (_status == status) return;
    setState(() => _status = status);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final highlight = widget.highlightCode?.trim() ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('我的券')),
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
                        key: Key('coupon-tab-${tab.status ?? 'all'}'),
                        label: Text(tab.label),
                        selected: _status == tab.status,
                        onSelected: (_) => _selectStatus(tab.status),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          if (highlight.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '定位券码 $highlight',
                  key: const Key('coupon-highlight-banner'),
                ),
              ),
            ),
          Expanded(
            child: FutureBuilder<CouponPage>(
              future: _coupons,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('券码加载失败：${snapshot.error}'),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          key: const Key('coupons-retry'),
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh),
                          label: const Text('重试'),
                        ),
                      ],
                    ),
                  );
                }
                final page = snapshot.data!;
                final items = page.items;
                if (items.isEmpty) {
                  return const Center(child: Text('当前筛选下暂无券码'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: items.length + (page.hasMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == items.length) {
                      return Center(
                        child: OutlinedButton.icon(
                          key: const Key('coupons-load-more'),
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
                    final coupon = items[index];
                    final isHighlight =
                        highlight.isNotEmpty && highlight == coupon.code;
                    return Card(
                      key: Key('coupon-card-${coupon.code}'),
                      color: isHighlight
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: ListTile(
                        title: Text(
                          coupon.dealTitle.isEmpty
                              ? coupon.code
                              : coupon.dealTitle,
                        ),
                        subtitle: Text(
                          '${coupon.code}\n${coupon.shopName} · ${coupon.statusText} · 有效期至 ${coupon.expireAt.isEmpty ? '不限期' : coupon.expireAt}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CouponDetailScreen(
                              repository: widget.repository,
                              code: coupon.code,
                              initialCoupon: coupon,
                            ),
                          ),
                        ),
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
