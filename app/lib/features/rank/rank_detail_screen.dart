import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/shop_detail_screen.dart';
import 'package:dazhongdianping_app/features/rank/rank_repository.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
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
    this.thirdPartyConfig = const ThirdPartyConfig(),
  });

  final RankRepository repository;
  final int rankId;
  final BrowseRepository? browseRepository;
  final TradeRepository? tradeRepository;
  final ReservationRepository? reservationRepository;
  final ReviewRepository? reviewRepository;
  final ThirdPartyConfig thirdPartyConfig;

  @override
  State<RankDetailScreen> createState() => _RankDetailScreenState();
}

class _RankDetailScreenState extends State<RankDetailScreen> {
  late Future<RankDetail> _detail;

  @override
  void initState() {
    super.initState();
    _detail = widget.repository.loadRankDetail(widget.rankId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('榜单详情')),
      body: FutureBuilder<RankDetail>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('榜单详情加载失败：${snapshot.error}'));
          }
          final detail = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                detail.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                [
                  detail.typeText,
                  if (detail.cityName.isNotEmpty) detail.cityName,
                  if (detail.categoryName.isNotEmpty) detail.categoryName,
                  if (detail.period.isNotEmpty) detail.period,
                  if (detail.updatedAt.isNotEmpty) detail.updatedAt,
                ].where((part) => part.isNotEmpty).join(' · '),
              ),
              const SizedBox(height: 16),
              if (detail.items.isEmpty)
                const Text('该榜单暂无门店')
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
                          if (shop.merchantCertificationLabel != null)
                            shop.merchantCertificationLabel!,
                          if (item.reason.isNotEmpty) item.reason,
                        ].join(' · '),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        '${shop.currency} ${shop.pricePerCapita}',
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
