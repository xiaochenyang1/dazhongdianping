import 'package:dazhongdianping_app/features/activity/activity_detail_screen.dart';
import 'package:dazhongdianping_app/features/activity/activity_repository.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:flutter/material.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({
    super.key,
    required this.repository,
    this.browseRepository,
    this.tradeRepository,
    this.reservationRepository,
    this.reviewRepository,
    this.thirdPartyConfig = const ThirdPartyConfig(),
  });

  final ActivityRepository repository;
  final BrowseRepository? browseRepository;
  final TradeRepository? tradeRepository;
  final ReservationRepository? reservationRepository;
  final ReviewRepository? reviewRepository;
  final ThirdPartyConfig thirdPartyConfig;

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  late Future<List<ActivitySummary>> _activities;

  @override
  void initState() {
    super.initState();
    _activities = widget.repository.loadActivities();
  }

  Future<void> _reload() async {
    setState(() => _activities = widget.repository.loadActivities());
    await _activities;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('运营活动')),
      body: FutureBuilder<List<ActivitySummary>>(
        future: _activities,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('活动加载失败：${snapshot.error}'),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _reload, child: const Text('重试')),
                ],
              ),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('当前区域暂无上线活动'));
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
                  item.channelText,
                  if (item.cityName.isNotEmpty) item.cityName,
                  '${item.itemCount} 个资源',
                ].where((part) => part.isNotEmpty).join(' · ');
                final period = [
                  if (item.startAt.isNotEmpty) item.startAt,
                  if (item.endAt.isNotEmpty) item.endAt,
                ].join(' ~ ');
                return Card(
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                      [meta, if (period.isNotEmpty) period]
                          .where((part) => part.isNotEmpty)
                          .join('\n'),
                    ),
                    isThreeLine: period.isNotEmpty,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ActivityDetailScreen(
                          repository: widget.repository,
                          activityId: item.id,
                          browseRepository: widget.browseRepository,
                          tradeRepository: widget.tradeRepository,
                          reservationRepository: widget.reservationRepository,
                          reviewRepository: widget.reviewRepository,
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
