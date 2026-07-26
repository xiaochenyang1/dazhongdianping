import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/rank/rank_detail_screen.dart';
import 'package:dazhongdianping_app/features/rank/rank_repository.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:flutter/material.dart';

class RankListScreen extends StatefulWidget {
  const RankListScreen({
    super.key,
    required this.repository,
    this.browseRepository,
    this.tradeRepository,
    this.reservationRepository,
    this.reviewRepository,
    this.canInteractReviews = false,
    this.thirdPartyConfig = const ThirdPartyConfig(),
  });

  final RankRepository repository;
  final BrowseRepository? browseRepository;
  final TradeRepository? tradeRepository;
  final ReservationRepository? reservationRepository;
  final ReviewRepository? reviewRepository;
  final bool canInteractReviews;
  final ThirdPartyConfig thirdPartyConfig;

  @override
  State<RankListScreen> createState() => _RankListScreenState();
}

class _RankListScreenState extends State<RankListScreen> {
  late Future<List<RankSummary>> _ranks;
  bool _reloading = false;

  @override
  void initState() {
    super.initState();
    _ranks = widget.repository.loadRanks();
  }

  Future<void> _reload() async {
    if (_reloading) return;
    setState(() => _reloading = true);
    try {
      final ranks = await widget.repository.loadRanks();
      if (mounted) {
        setState(() {
          _ranks = Future.value(ranks);
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('刷新榜单失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _reloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('城市榜单')),
      body: FutureBuilder<List<RankSummary>>(
        future: _ranks,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('榜单加载失败：${snapshot.error}'),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('rank-list-retry'),
                    onPressed: _reloading ? null : _reload,
                    child: Text(_reloading ? '处理中...' : '重试'),
                  ),
                ],
              ),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('当前区域暂无公开榜单'));
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final meta = [
                  item.typeText,
                  if (item.cityName.isNotEmpty) item.cityName,
                  if (item.categoryName.isNotEmpty) item.categoryName,
                  if (item.period.isNotEmpty) item.period,
                  '${item.itemCount} 家门店',
                ].where((part) => part.isNotEmpty).join(' · ');
                return Card(
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                      [
                        meta,
                        if (item.topShopName.isNotEmpty)
                          '榜首 ${item.topShopName}',
                        if (item.updatedAt.isNotEmpty) item.updatedAt,
                      ].where((part) => part.isNotEmpty).join('\n'),
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RankDetailScreen(
                          repository: widget.repository,
                          rankId: item.id,
                          browseRepository: widget.browseRepository,
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
