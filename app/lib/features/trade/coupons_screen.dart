import 'package:dazhongdianping_app/core/app_localizations.dart';
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
  List<({int? status, String label})> _tabs(AppLocalizations strings) => [
    (status: null, label: strings.filterAll),
    (status: 1, label: strings.couponPending),
    (status: 2, label: strings.couponUsed),
    (status: 3, label: strings.couponExpired),
    (status: 4, label: strings.couponRefunded),
  ];

  late int? _status;
  late Future<CouponPage> _coupons;
  bool _loadingMore = false;
  bool _retrying = false;
  final Set<String> _openingCouponCodes = <String>{};
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

  Future<void> _retry() async {
    if (_retrying) return;
    _requestId++;
    final future = widget.repository.loadCouponPage(status: _status);
    setState(() {
      _coupons = future;
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
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).loadMoreCouponsFailed(error))));
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

  Future<void> _openCoupon(Coupon coupon) async {
    if (_openingCouponCodes.contains(coupon.code)) return;
    setState(() => _openingCouponCodes.add(coupon.code));
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CouponDetailScreen(
            repository: widget.repository,
            code: coupon.code,
            initialCoupon: coupon,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _openingCouponCodes.remove(coupon.code));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final tabs = _tabs(strings);
    final highlight = widget.highlightCode?.trim() ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(strings.myCoupons)),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: tabs
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
                  strings.couponHighlight(highlight),
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
                        Text(strings.couponsLoadFailed(snapshot.error!)),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          key: const Key('coupons-retry'),
                          onPressed: _retrying ? null : _retry,
                          icon: const Icon(Icons.refresh),
                          label: Text(_retrying ? strings.processing : strings.retry),
                        ),
                      ],
                    ),
                  );
                }
                final page = snapshot.data!;
                final items = page.items;
                if (items.isEmpty) {
                  return Center(child: Text(strings.noCouponsForFilter));
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
                          label: Text(_loadingMore ? strings.loading : strings.loadMore),
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
                        onTap: _openingCouponCodes.contains(coupon.code)
                            ? null
                            : () => _openCoupon(coupon),
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
