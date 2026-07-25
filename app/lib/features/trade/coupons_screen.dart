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
  late Future<List<Coupon>> _coupons;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _reload();
  }

  void _reload() {
    final future = widget.repository.loadCoupons(status: _status);
    setState(() => _coupons = future);
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
            child: FutureBuilder<List<Coupon>>(
              future: _coupons,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('券码加载失败：${snapshot.error}'));
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return const Center(child: Text('当前筛选下暂无券码'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final coupon = items[index];
                    final isHighlight =
                        highlight.isNotEmpty && highlight == coupon.code;
                    return Card(
                      key: Key('coupon-card-${coupon.code}'),
                      color: isHighlight
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: ListTile(
                        title: Text(coupon.dealTitle.isEmpty
                            ? coupon.code
                            : coupon.dealTitle),
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
