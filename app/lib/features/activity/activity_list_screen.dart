import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/activity/activity_detail_screen.dart';
import 'package:dazhongdianping_app/features/activity/activity_repository.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({
    super.key,
    required this.repository,
    this.browseRepository,
    this.tradeRepository,
    this.reservationRepository,
    this.reviewRepository,
    this.canInteractReviews = false,
    this.thirdPartyConfig = const ThirdPartyConfig(),
  });

  final ActivityRepository repository;
  final BrowseRepository? browseRepository;
  final TradeRepository? tradeRepository;
  final ReservationRepository? reservationRepository;
  final ReviewRepository? reviewRepository;
  final bool canInteractReviews;
  final ThirdPartyConfig thirdPartyConfig;

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  late Future<List<ActivitySummary>> _activities;
  bool _reloading = false;
  final Set<int> _openingActivityIds = <int>{};

  @override
  void initState() {
    super.initState();
    _activities = widget.repository.loadActivities();
  }

  Future<void> _reload() async {
    if (_reloading) return;
    setState(() => _reloading = true);
    try {
      final activities = await widget.repository.loadActivities();
      if (mounted) {
        setState(() {
          _activities = Future.value(activities);
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).refreshActivitiesFailed(error),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _reloading = false);
    }
  }

  Future<void> _openActivity(ActivitySummary activity) async {
    if (_openingActivityIds.contains(activity.id)) return;
    setState(() => _openingActivityIds.add(activity.id));
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ActivityDetailScreen(
            repository: widget.repository,
            activityId: activity.id,
            browseRepository: widget.browseRepository,
            tradeRepository: widget.tradeRepository,
            reservationRepository: widget.reservationRepository,
            reviewRepository: widget.reviewRepository,
            canInteractReviews: widget.canInteractReviews,
            thirdPartyConfig: widget.thirdPartyConfig,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _openingActivityIds.remove(activity.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.activities)),
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
                  Text(strings.activitiesLoadFailed(snapshot.error!)),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('activity-list-retry'),
                    onPressed: _reloading ? null : _reload,
                    child: Text(_reloading ? strings.processing : strings.retry),
                  ),
                ],
              ),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return Center(child: Text(strings.noOnlineActivities));
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
                  strings.resourceCount(item.itemCount),
                ].where((part) => part.isNotEmpty).join(' · ');
                final period = [
                  if (item.startAt.isNotEmpty) item.startAt,
                  if (item.endAt.isNotEmpty) item.endAt,
                ].join(' ~ ');
                return Card(
                  key: Key('activity-card-${item.id}'),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                      [
                        meta,
                        if (period.isNotEmpty) period,
                      ].where((part) => part.isNotEmpty).join('\n'),
                    ),
                    isThreeLine: period.isNotEmpty,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openingActivityIds.contains(item.id)
                        ? null
                        : () => _openActivity(item),
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
