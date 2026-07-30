import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/rank/rank_error_localizer.dart';
import 'package:dazhongdianping_app/features/browse/shop_detail_screen.dart';
import 'package:dazhongdianping_app/features/rank/rank_repository.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';

class RankDetailScreen extends StatefulWidget {
  const RankDetailScreen({
    super.key,
    required this.repository,
    required this.rankId,
    this.browseRepository,
    this.tradeRepository,
    this.reservationRepository,
    this.reviewRepository,
    this.canInteractReviews = false,
    this.thirdPartyConfig = const ThirdPartyConfig(),
  });

  final RankRepository repository;
  final int rankId;
  final BrowseRepository? browseRepository;
  final TradeRepository? tradeRepository;
  final ReservationRepository? reservationRepository;
  final ReviewRepository? reviewRepository;
  final bool canInteractReviews;
  final ThirdPartyConfig thirdPartyConfig;

  @override
  State<RankDetailScreen> createState() => _RankDetailScreenState();
}

class _RankDetailScreenState extends State<RankDetailScreen> {
  late Future<RankDetail> _detail;
  bool _reloading = false;

  @override
  void initState() {
    super.initState();
    _detail = widget.repository.loadRankDetail(widget.rankId);
  }

  Future<void> _reload() async {
    if (_reloading) return;
    final future = widget.repository.loadRankDetail(widget.rankId);
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

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.rankDetailTitle)),
      body: FutureBuilder<RankDetail>(
        future: _detail,
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
                  Text(strings.rankDetailLoadFailed(error)),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    key: const Key('rank-detail-retry'),
                    onPressed: _reloading ? null : _reload,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      _reloading ? strings.processing : strings.retry,
                    ),
                  ),
                ],
              ),
            );
          }
          final detail = snapshot.data!;
          final typeText = strings.rankTypeLabel(
            type: detail.type,
            fallback: detail.typeText,
          );
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
                  typeText,
                  if (detail.cityName.isNotEmpty) detail.cityName,
                  if (detail.categoryName.isNotEmpty) detail.categoryName,
                  if (detail.period.isNotEmpty) detail.period,
                  if (detail.updatedAt.isNotEmpty)
                    formatDisplayDateTime(
                      detail.updatedAt,
                      locale: strings.tag,
                    ),
                ].where((part) => part.isNotEmpty).join(' · '),
              ),
              const SizedBox(height: 16),
              if (detail.items.isEmpty)
                Text(strings.rankNoShops)
              else
                ...detail.items.map((item) {
                  final shop = item.shop;
                  final location = [
                    shop.cityName,
                    shop.areaName,
                  ].where((part) => part.isNotEmpty).join(' · ');
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${item.position}')),
                      title: Text(shop.name),
                      subtitle: Text(
                        [
                          if (location.isNotEmpty) location,
                          '★ ${shop.score.toStringAsFixed(1)}',
                          if (strings
                              .certificationBadgeLabel(
                                code: shop.merchantCertificationCode,
                                fallback: shop.merchantCertificationLabel,
                              )
                              .isNotEmpty)
                            strings.certificationBadgeLabel(
                              code: shop.merchantCertificationCode,
                              fallback: shop.merchantCertificationLabel,
                            ),
                          if (item.reason.isNotEmpty) item.reason,
                        ].join(' · '),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        formatMoney(
                          shop.pricePerCapita,
                          shop.currency,
                          locale: strings.tag,
                        ),
                      ),
                      onTap: widget.browseRepository == null || shop.id <= 0
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ShopDetailScreen(
                                  repository: widget.browseRepository!,
                                  shopId: shop.id,
                                  tradeRepository: widget.tradeRepository,
                                  reservationRepository:
                                      widget.reservationRepository,
                                  reviewRepository: widget.reviewRepository,
                                  canInteractReviews: widget.canInteractReviews,
                                  thirdPartyConfig: widget.thirdPartyConfig,
                                ),
                              ),
                            ),
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
