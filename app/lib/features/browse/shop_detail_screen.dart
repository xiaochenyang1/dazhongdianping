import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_screen.dart';
import 'package:dazhongdianping_app/features/review/review_editor_screen.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/trade/deals_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';

class ShopDetailScreen extends StatefulWidget {
  const ShopDetailScreen({
    super.key,
    required this.repository,
    required this.shopId,
    this.tradeRepository,
    this.reservationRepository,
    this.reviewRepository,
    this.thirdPartyConfig = const ThirdPartyConfig(),
    this.enableFavorite = true,
  });
  final BrowseRepository repository;
  final int shopId;
  final TradeRepository? tradeRepository;
  final ReservationRepository? reservationRepository;
  final ReviewRepository? reviewRepository;
  final ThirdPartyConfig thirdPartyConfig;
  final bool enableFavorite;

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  late Future<ShopDetail> _detail;
  Future<List<ShopSummary>>? _similar;
  bool _favorited = false;
  bool _favoriteLoading = false;
  bool _favoriteSaving = false;

  @override
  void initState() {
    super.initState();
    _detail = widget.repository.loadShopDetail(widget.shopId);
    _similar = widget.repository.loadSimilarShops(widget.shopId, limit: 6);
    if (widget.enableFavorite) {
      _loadFavoriteState();
    }
  }

  Future<void> _loadFavoriteState() async {
    setState(() => _favoriteLoading = true);
    try {
      final favorited = await widget.repository.isShopFavorited(widget.shopId);
      if (!mounted) return;
      setState(() {
        _favorited = favorited;
        _favoriteLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _favoriteLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_favoriteSaving) return;
    setState(() => _favoriteSaving = true);
    try {
      if (_favorited) {
        await widget.repository.unfavoriteShop(widget.shopId);
      } else {
        await widget.repository.favoriteShop(widget.shopId);
      }
      if (!mounted) return;
      setState(() => _favorited = !_favorited);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('收藏操作失败：$error')),
      );
    } finally {
      if (mounted) setState(() => _favoriteSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place details'),
        actions: [
          if (widget.enableFavorite)
            IconButton(
              tooltip: _favorited ? '取消收藏' : '收藏门店',
              onPressed: (_favoriteLoading || _favoriteSaving)
                  ? null
                  : _toggleFavorite,
              icon: Icon(
                _favorited ? Icons.favorite : Icons.favorite_border,
                color: _favorited ? Colors.redAccent : null,
              ),
            ),
        ],
      ),
      body: FutureBuilder<ShopDetail>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton(
                onPressed: () => setState(
                  () =>
                      _detail = widget.repository.loadShopDetail(widget.shopId),
                ),
                child: const Text('Retry'),
              ),
            );
          }
          final shop = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                shop.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (shop.merchantCertificationLabel != null) ...[
                const SizedBox(height: 8),
                Chip(
                  avatar: const Icon(Icons.verified, size: 16),
                  label: Text(shop.merchantCertificationLabel!),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '${shop.category} · ★ ${shop.score.toStringAsFixed(1)} · ${shop.currency} ${shop.pricePerCapita}',
              ),
              const SizedBox(height: 24),
              _InfoTile(
                icon: Icons.location_on_outlined,
                title: 'Address',
                value: shop.address,
              ),
              _InfoTile(
                icon: Icons.schedule_outlined,
                title: 'Opening hours',
                value: shop.businessHours,
              ),
              _InfoTile(
                icon: Icons.phone_outlined,
                title: 'Phone',
                value: shop.phone,
              ),
              const SizedBox(height: 20),
              Text(shop.summary),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shop.tags
                    .map((tag) => Chip(label: Text(tag)))
                    .toList(),
              ),
              const SizedBox(height: 24),
              if (widget.enableFavorite) ...[
                FilledButton.tonalIcon(
                  onPressed: (_favoriteLoading || _favoriteSaving)
                      ? null
                      : _toggleFavorite,
                  icon: Icon(
                    _favorited ? Icons.favorite : Icons.favorite_border,
                  ),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      _favoriteLoading
                          ? '收藏状态加载中...'
                          : (_favorited ? '取消收藏' : '收藏门店'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (widget.reviewRepository != null) ...[
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReviewEditorScreen(
                        repository: widget.reviewRepository!,
                        shopId: shop.id,
                        shopName: shop.name,
                        currency: shop.currency,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('写点评'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  if (widget.tradeRepository != null)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DealsScreen(
                              repository: widget.tradeRepository!,
                              shopId: widget.shopId,
                              thirdPartyConfig: widget.thirdPartyConfig,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.local_offer_outlined),
                        label: const Text('团购优惠'),
                      ),
                    ),
                  if (widget.tradeRepository != null &&
                      widget.reservationRepository != null)
                    const SizedBox(width: 12),
                  if (widget.reservationRepository != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReservationScreen(
                              repository: widget.reservationRepository!,
                              shopId: widget.shopId,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.event_available_outlined),
                        label: const Text('在线预订'),
                      ),
                    ),
                ],
              ),
              if (_similar != null) ...[
                const SizedBox(height: 28),
                const Text(
                  '相似门店',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<ShopSummary>>(
                  future: _similar,
                  builder: (context, similarSnapshot) {
                    if (similarSnapshot.connectionState !=
                        ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (similarSnapshot.hasError) {
                      return Text('相似门店加载失败：${similarSnapshot.error}');
                    }
                    final items = similarSnapshot.data ?? const [];
                    if (items.isEmpty) {
                      return const Text('暂无相似门店');
                    }
                    return Column(
                      children: items
                          .map(
                            (item) => Card(
                              child: ListTile(
                                title: Text(item.name),
                                subtitle: Text(
                                  item.merchantCertificationLabel == null
                                      ? '${item.category} · ★ ${item.score.toStringAsFixed(1)}'
                                      : '${item.category} · ★ ${item.score.toStringAsFixed(1)} · ${item.merchantCertificationLabel}',
                                ),
                                trailing: Text(
                                  '${item.currency} ${item.pricePerCapita}',
                                ),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ShopDetailScreen(
                                      repository: widget.repository,
                                      shopId: item.id,
                                      tradeRepository: widget.tradeRepository,
                                      reservationRepository:
                                          widget.reservationRepository,
                                      reviewRepository: widget.reviewRepository,
                                      thirdPartyConfig: widget.thirdPartyConfig,
                                      enableFavorite: widget.enableFavorite,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(value.isEmpty ? '--' : value),
  );
}
