import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/shop_detail_screen.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';

class BrowseHistoryScreen extends StatefulWidget {
  const BrowseHistoryScreen({
    super.key,
    required this.repository,
    this.tradeRepository,
    this.reservationRepository,
    this.reviewRepository,
    this.canInteractReviews = false,
    this.thirdPartyConfig = const ThirdPartyConfig(),
  });

  final BrowseRepository repository;
  final TradeRepository? tradeRepository;
  final ReservationRepository? reservationRepository;
  final ReviewRepository? reviewRepository;
  final bool canInteractReviews;
  final ThirdPartyConfig thirdPartyConfig;

  @override
  State<BrowseHistoryScreen> createState() => _BrowseHistoryScreenState();
}

class _BrowseHistoryScreenState extends State<BrowseHistoryScreen> {
  late Future<ShopBrowseHistoryPage> _history;
  bool _clearing = false;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _history = widget.repository.loadBrowseHistoryPage();
  }

  Future<void> _reload() async {
    setState(() {
      _history = widget.repository.loadBrowseHistoryPage();
    });
    await _history;
  }

  Future<void> _loadMore(ShopBrowseHistoryPage current) async {
    if (_loadingMore || !current.hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final next = await widget.repository.loadBrowseHistoryPage(
        page: current.page + 1,
        pageSize: current.pageSize,
      );
      if (!mounted) return;
      final knownShopIds = current.items.map((item) => item.shopId).toSet();
      final items = [
        ...current.items,
        ...next.items.where((item) => knownShopIds.add(item.shopId)),
      ];
      setState(() {
        _history = Future.value(
          ShopBrowseHistoryPage(
            items: items,
            total: next.total,
            page: next.page,
            pageSize: current.pageSize,
          ),
        );
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载更多足迹失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _clearAll() async {
    if (_clearing) return;
    setState(() => _clearing = true);
    try {
      await widget.repository.clearBrowseHistory();
      if (!mounted) return;
      setState(() {
        _history = Future.value(
          const ShopBrowseHistoryPage(
            items: [],
            total: 0,
            page: 1,
            pageSize: 20,
          ),
        );
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('清空足迹失败：$error')));
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  Future<void> _removeItem(ShopBrowseHistoryItem item) async {
    try {
      await widget.repository.removeBrowseHistoryItem(item.shopId);
      if (!mounted) return;
      final current = await _history;
      if (!mounted) return;
      setState(() {
        _history = Future.value(
          ShopBrowseHistoryPage(
            items: current.items
                .where((row) => row.shopId != item.shopId)
                .toList(),
            total: current.total > 0 ? current.total - 1 : 0,
            page: current.page,
            pageSize: current.pageSize,
          ),
        );
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除足迹失败：$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的足迹'),
        actions: [
          TextButton(
            onPressed: _clearing ? null : _clearAll,
            child: Text(_clearing ? '清空中...' : '清空'),
          ),
        ],
      ),
      body: FutureBuilder<ShopBrowseHistoryPage>(
        future: _history,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('足迹加载失败：${snapshot.error}'),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _reload, child: const Text('重试')),
                ],
              ),
            );
          }
          final page = snapshot.data!;
          final items = page.items;
          if (items.isEmpty) {
            return const Center(child: Text('当前区域还没有浏览足迹'));
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length + (page.hasMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return Center(
                    child: OutlinedButton.icon(
                      key: const Key('browse-history-load-more'),
                      onPressed: _loadingMore ? null : () => _loadMore(page),
                      icon: _loadingMore
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.expand_more),
                      label: Text(_loadingMore ? '加载中...' : '加载更多'),
                    ),
                  );
                }
                final item = items[index];
                final location = [
                  item.cityName,
                  item.areaName,
                ].where((part) => part.isNotEmpty).join(' · ');
                final subtitle = [
                  if (location.isNotEmpty) location,
                  '浏览 ${item.viewCount} 次',
                  if (item.lastViewedAt.isNotEmpty) item.lastViewedAt,
                  if (item.merchantCertificationLabel != null)
                    item.merchantCertificationLabel!,
                ].join(' · ');
                return Card(
                  child: ListTile(
                    title: Text(item.shopName),
                    subtitle: Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: '删除足迹',
                      onPressed: () => _removeItem(item),
                      icon: const Icon(Icons.close),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ShopDetailScreen(
                          repository: widget.repository,
                          shopId: item.shopId,
                          tradeRepository: widget.tradeRepository,
                          reservationRepository: widget.reservationRepository,
                          reviewRepository: widget.reviewRepository,
                          canInteractReviews: widget.canInteractReviews,
                          thirdPartyConfig: widget.thirdPartyConfig,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
