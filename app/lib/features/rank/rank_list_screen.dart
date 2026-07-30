import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/rank/rank_error_localizer.dart';
import 'package:dazhongdianping_app/features/rank/rank_detail_screen.dart';
import 'package:dazhongdianping_app/features/rank/rank_repository.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
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
  final Set<int> _openingRankIds = <int>{};

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
        final strings = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.refreshRanksFailed(localizeRankError(strings, error)),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _reloading = false);
    }
  }

  Future<void> _openRank(RankSummary rank) async {
    if (_openingRankIds.contains(rank.id)) return;
    setState(() => _openingRankIds.add(rank.id));
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RankDetailScreen(
            repository: widget.repository,
            rankId: rank.id,
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
        setState(() => _openingRankIds.remove(rank.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.cityRankings)),
      body: FutureBuilder<List<RankSummary>>(
        future: _ranks,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = localizeRankError(strings, snapshot.error!);
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings.ranksLoadFailed(error)),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('rank-list-retry'),
                    onPressed: _reloading ? null : _reload,
                    child: Text(
                      _reloading ? strings.processing : strings.retry,
                    ),
                  ),
                ],
              ),
            );
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return Center(child: Text(strings.noPublicRanks));
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final typeText = strings.rankTypeLabel(
                  type: item.type,
                  fallback: item.typeText,
                );
                final meta = [
                  typeText,
                  if (item.cityName.isNotEmpty) item.cityName,
                  if (item.categoryName.isNotEmpty) item.categoryName,
                  if (item.period.isNotEmpty) item.period,
                  strings.shopCount(item.itemCount),
                ].where((part) => part.isNotEmpty).join(' · ');
                return Card(
                  key: Key('rank-card-${item.id}'),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                      [
                        meta,
                        if (item.topShopName.isNotEmpty)
                          strings.topShop(item.topShopName),
                        if (item.updatedAt.isNotEmpty)
                          formatDisplayDateTime(
                            item.updatedAt,
                            locale: strings.tag,
                          ),
                      ].where((part) => part.isNotEmpty).join('\n'),
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _openingRankIds.contains(item.id)
                        ? null
                        : () => _openRank(item),
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
