import 'package:dazhongdianping_app/features/activity/activity_repository.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/shop_detail_screen.dart';
import 'package:dazhongdianping_app/features/community/community_repository.dart';
import 'package:dazhongdianping_app/features/community/post_detail_screen.dart';
import 'package:dazhongdianping_app/features/rank/rank_detail_screen.dart';
import 'package:dazhongdianping_app/features/rank/rank_repository.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/topic/topic_detail_screen.dart';
import 'package:dazhongdianping_app/features/topic/topic_repository.dart';
import 'package:dazhongdianping_app/features/trade/deal_detail_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef ActivityExternalUrlLauncher = Future<bool> Function(Uri uri);

Future<bool> _launchActivityExternalUrl(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

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
    this.externalUrlLauncher,
  });

  final ActivityRepository repository;
  final int activityId;
  final BrowseRepository? browseRepository;
  final TradeRepository? tradeRepository;
  final ReservationRepository? reservationRepository;
  final ReviewRepository? reviewRepository;
  final bool canInteractReviews;
  final ThirdPartyConfig thirdPartyConfig;
  final ActivityExternalUrlLauncher? externalUrlLauncher;

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late Future<ActivityDetail> _detail;
  bool _reloading = false;
  final Set<int> _openingItemIds = <int>{};

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

  Uri? _externalUri(ActivityItem item) {
    if (item.targetType != 6) return null;
    final uri = Uri.tryParse(item.linkUrl.trim());
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      return null;
    }
    return uri;
  }

  bool _canOpenItem(ActivityItem item) => switch (item.targetType) {
    1 => widget.browseRepository != null && item.targetId > 0,
    2 => widget.tradeRepository != null && item.targetId > 0,
    3 || 4 || 5 => item.targetId > 0,
    6 => _externalUri(item) != null,
    _ => false,
  };

  Future<void> _openItem(ActivityItem item) async {
    if (!_canOpenItem(item) || _openingItemIds.contains(item.id)) return;
    setState(() => _openingItemIds.add(item.id));
    try {
      switch (item.targetType) {
        case 1:
          await Navigator.of(context).push(
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
          break;
        case 2:
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DealDetailScreen(
                repository: widget.tradeRepository!,
                dealId: item.targetId,
              ),
            ),
          );
          break;
        case 3:
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PostDetailScreen(
                repository: CommunityRepository(widget.repository.api),
                postId: item.targetId,
                canInteract: false,
              ),
            ),
          );
          break;
        case 4:
          await Navigator.of(context).push(
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
          break;
        case 5:
          final topicRepository = TopicRepository(widget.repository.api);
          final topic = await topicRepository.loadDetail(item.targetId);
          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TopicDetailScreen(
                repository: topicRepository,
                initial: topic,
                canInteract: false,
              ),
            ),
          );
          break;
        case 6:
          final uri = _externalUri(item)!;
          final launched =
              await (widget.externalUrlLauncher ?? _launchActivityExternalUrl)(
                uri,
              );
          if (!launched && mounted) {
            _showOpenError('无法打开外部链接');
          }
          break;
      }
    } catch (error) {
      if (mounted) {
        final targetName = switch (item.targetType) {
          2 => '团购',
          5 => '话题',
          6 => '外部链接',
          _ => '资源',
        };
        _showOpenError('$targetName打开失败：$error');
      }
    } finally {
      if (mounted) setState(() => _openingItemIds.remove(item.id));
    }
  }

  void _showOpenError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                ...detail.items.map((item) {
                  final canOpen = _canOpenItem(item);
                  final opening = _openingItemIds.contains(item.id);
                  return Card(
                    key: Key('activity-item-${item.id}'),
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
                      trailing: canOpen
                          ? SizedBox.square(
                              dimension: 24,
                              child: opening
                                  ? const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    )
                                  : const Icon(Icons.chevron_right),
                            )
                          : null,
                      onTap: canOpen && !opening ? () => _openItem(item) : null,
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
