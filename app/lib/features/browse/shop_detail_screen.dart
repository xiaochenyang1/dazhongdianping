import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_screen.dart';
import 'package:dazhongdianping_app/features/browse/shop_reviews_screen.dart';
import 'package:dazhongdianping_app/features/review/review_detail_screen.dart';
import 'package:dazhongdianping_app/features/review/review_editor_screen.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/trade/deals_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    this.canInteractReviews = false,
  });
  final BrowseRepository repository;
  final int shopId;
  final TradeRepository? tradeRepository;
  final ReservationRepository? reservationRepository;
  final ReviewRepository? reviewRepository;
  final ThirdPartyConfig thirdPartyConfig;
  final bool enableFavorite;
  final bool canInteractReviews;

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  late Future<ShopDetail> _detail;
  Future<List<ShopSummary>>? _similar;
  Future<List<ShopReviewPreview>>? _reviews;
  bool _favorited = false;
  bool _favoriteLoading = false;
  bool _favoriteSaving = false;
  bool _sharing = false;
  bool _reloadingDetail = false;
  bool _reloadingReviewPreviews = false;

  @override
  void initState() {
    super.initState();
    _detail = widget.repository.loadShopDetail(widget.shopId);
    _similar = _loadSimilar();
    _reviews = _loadReviewPreviews();
    if (widget.enableFavorite) {
      _loadFavoriteState();
    }
  }

  Future<List<ShopSummary>> _loadSimilar() {
    final future = widget.repository.loadSimilarShops(widget.shopId, limit: 6);
    future.ignore();
    return future;
  }

  Future<List<ShopReviewPreview>> _loadReviewPreviews() {
    final future = widget.repository.loadShopReviews(
      widget.shopId,
      page: 1,
      pageSize: 5,
      sort: 'latest',
    );
    future.ignore();
    return future;
  }

  void _reloadSimilar() {
    final future = _loadSimilar();
    setState(() {
      _similar = future;
    });
  }

  Future<void> _reloadReviewPreviews() async {
    if (_reloadingReviewPreviews) return;
    final future = _loadReviewPreviews();
    setState(() {
      _reviews = future;
      _reloadingReviewPreviews = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => _reloadingReviewPreviews = false);
    }
  }

  Future<void> _reloadDetail() async {
    if (_reloadingDetail) return;
    final future = widget.repository.loadShopDetail(widget.shopId);
    setState(() {
      _detail = future;
      _reloadingDetail = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => _reloadingDetail = false);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('收藏操作失败：$error')));
    } finally {
      if (mounted) setState(() => _favoriteSaving = false);
    }
  }

  Future<void> _shareShop(ShopDetail shop) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final shareUrl = 'https://local.life/shops/${shop.id}';
    final shareText =
        '${shop.name} · ★ ${shop.score.toStringAsFixed(1)} · $shareUrl';
    try {
      await Clipboard.setData(ClipboardData(text: shareText));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('分享文案已复制')));
    } finally {
      if (mounted) setState(() => _sharing = false);
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('门店详情加载失败：${snapshot.error}'),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    key: const Key('shop-detail-retry'),
                    onPressed: _reloadingDetail ? null : _reloadDetail,
                    icon: const Icon(Icons.refresh),
                    label: Text(_reloadingDetail ? '处理中...' : '重试'),
                  ),
                ],
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
              FilledButton.tonalIcon(
                key: const Key('shop-share-button'),
                onPressed: _sharing ? null : () => _shareShop(shop),
                icon: const Icon(Icons.share_outlined),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(_sharing ? '分享中...' : '分享门店'),
                ),
              ),
              const SizedBox(height: 12),
              if (widget.reviewRepository != null &&
                  widget.canInteractReviews) ...[
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
              if (_reviews != null) ...[
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '门店点评',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      key: const Key('shop-reviews-view-all'),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ShopReviewsScreen(
                            repository: widget.repository,
                            shopId: widget.shopId,
                            shopName: shop.name,
                            reviewRepository: widget.reviewRepository,
                            canInteractReviews: widget.canInteractReviews,
                          ),
                        ),
                      ),
                      child: const Text('查看全部'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<ShopReviewPreview>>(
                  future: _reviews,
                  builder: (context, reviewSnapshot) {
                    if (reviewSnapshot.connectionState !=
                        ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (reviewSnapshot.hasError) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('门店点评加载失败：${reviewSnapshot.error}'),
                          const SizedBox(height: 8),
                          FilledButton.tonalIcon(
                            key: const Key('shop-review-previews-retry'),
                            onPressed: _reloadingReviewPreviews
                                ? null
                                : _reloadReviewPreviews,
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              _reloadingReviewPreviews ? '处理中...' : '重试点评',
                            ),
                          ),
                        ],
                      );
                    }
                    final items = reviewSnapshot.data ?? const [];
                    if (items.isEmpty) {
                      return const Text('暂无公开点评');
                    }
                    return Column(
                      children: items
                          .map(
                            (item) => Card(
                              child: ListTile(
                                title: Text(
                                  item.authorCertificationLabel == null
                                      ? '${item.userName} · ★ ${item.score.toStringAsFixed(1)}'
                                      : '${item.userName} · ${item.authorCertificationLabel} · ★ ${item.score.toStringAsFixed(1)}',
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 6),
                                    Text(item.content),
                                    if (item.merchantReply != null) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        '商家回复：${item.merchantReply}',
                                        style: const TextStyle(
                                          color: Color(0xFF4B5563),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      '点赞 ${item.likedCount} · 评论 ${item.commentCount}'
                                      '${item.createdAt.isEmpty ? '' : ' · ${item.createdAt}'}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: widget.reviewRepository == null
                                    ? null
                                    : const Icon(Icons.chevron_right),
                                onTap: widget.reviewRepository == null
                                    ? null
                                    : () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ReviewDetailScreen(
                                            repository:
                                                widget.reviewRepository!,
                                            reviewId: item.id,
                                            canInteract:
                                                widget.canInteractReviews,
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
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('相似门店加载失败：${similarSnapshot.error}'),
                          const SizedBox(height: 8),
                          FilledButton.tonalIcon(
                            key: const Key('similar-shops-retry'),
                            onPressed: _reloadSimilar,
                            icon: const Icon(Icons.refresh),
                            label: const Text('重试推荐'),
                          ),
                        ],
                      );
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
                                      canInteractReviews:
                                          widget.canInteractReviews,
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
