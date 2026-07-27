import 'package:dazhongdianping_app/features/activity/activity_repository.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/shop_detail_screen.dart';
import 'package:dazhongdianping_app/features/community/community_repository.dart';
import 'package:dazhongdianping_app/features/community/post_detail_screen.dart';
import 'package:dazhongdianping_app/features/rank/rank_detail_screen.dart';
import 'package:dazhongdianping_app/features/rank/rank_repository.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:flutter/material.dart';

class ActivityDetailScreen extends StatefulWidget {
  const ActivityDetailScreen({
    super.key,
    required this.repository,
    required this.activityId,
    this.browseRepository,
    this.tradeRepository,
    this.reservationRepository,
    this.reviewRepository,
    this.canInteractReviews = false,
    this.thirdPartyConfig = const ThirdPartyConfig(),
  });

  final ActivityRepository repository;
  final int activityId;
  final BrowseRepository? browseRepository;
  final TradeRepository? tradeRepository;
  final ReservationRepository? reservationRepository;
  final ReviewRepository? reviewRepository;
  final bool canInteractReviews;
  final ThirdPartyConfig thirdPartyConfig;

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late Future<ActivityDetail> _detail;
  bool _reloading = false;

  @override
  void initState() {
    super.initState();
    _detail = widget.repository.loadActivityDetail(widget.activityId);
  }

  Future<void> _reload() async {
    if (_reloading) return;
    final future = widget.repository.loadActivityDetail(widget.activityId);
    setState(() {
      _detail = future;
      _reloading = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => _reloading = false);
    }
  }

  void _openItem(ActivityItem item) {
    // targetType: 1 shop, 2 deal, 3 post, 4 rank (backend PublicActivityService)
    if (item.targetType == 1 &&
        widget.browseRepository != null &&
        item.targetId > 0) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ShopDetailScreen(
            repository: widget.browseRepository!,
            shopId: item.targetId,
            tradeRepository: widget.tradeRepository,
            reservationRepository: widget.reservationRepository,
            reviewRepository: widget.reviewRepository,
            canInteractReviews: widget.canInteractReviews,
            thirdPartyConfig: widget.thirdPartyConfig,
          ),
        ),
      );
      return;
    }
    if (item.targetType == 3 && item.targetId > 0) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(
            repository: CommunityRepository(widget.repository.api),
            postId: item.targetId,
            canInteract: false,
          ),
        ),
      );
      return;
    }
    if (item.targetType == 4 && item.targetId > 0) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RankDetailScreen(
            repository: RankRepository(widget.repository.api),
            rankId: item.targetId,
            browseRepository: widget.browseRepository,
            tradeRepository: widget.tradeRepository,
            reservationRepository: widget.reservationRepository,
            reviewRepository: widget.reviewRepository,
            canInteractReviews: widget.canInteractReviews,
            thirdPartyConfig: widget.thirdPartyConfig,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('活动详情')),
      body: FutureBuilder<ActivityDetail>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('活动详情加载失败：${snapshot.error}'),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    key: const Key('activity-detail-retry'),
                    onPressed: _reloading ? null : _reload,
                    icon: const Icon(Icons.refresh),
                    label: Text(_reloading ? '处理中...' : '重试'),
                  ),
                ],
              ),
            );
          }
          final detail = snapshot.data!;
          final period = [
            if (detail.startAt.isNotEmpty) detail.startAt,
            if (detail.endAt.isNotEmpty) detail.endAt,
          ].join(' ~ ');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                detail.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                [
                  detail.typeText,
                  detail.channelText,
                  if (detail.cityName.isNotEmpty) detail.cityName,
                  if (period.isNotEmpty) period,
                ].where((part) => part.isNotEmpty).join(' · '),
              ),
              const SizedBox(height: 16),
              if (detail.items.isEmpty)
                const Text('该活动暂无资源项')
              else
                ...detail.items.map(
                  (item) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        item.title.isNotEmpty ? item.title : item.targetName,
                      ),
                      subtitle: Text(
                        [
                          item.targetTypeText,
                          if (item.subtitle.isNotEmpty) item.subtitle,
                          if (item.targetName.isNotEmpty &&
                              item.title.isNotEmpty)
                            item.targetName,
                        ].where((part) => part.isNotEmpty).join(' · '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openItem(item),
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
