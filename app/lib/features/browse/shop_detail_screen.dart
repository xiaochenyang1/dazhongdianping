import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/browse_error_localizer.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_screen.dart';
import 'package:dazhongdianping_app/features/browse/shop_reviews_screen.dart';
import 'package:dazhongdianping_app/features/review/review_detail_screen.dart';
import 'package:dazhongdianping_app/features/review/review_editor_screen.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/trade/deals_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

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
  bool _reloadingSimilar = false;

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

  Future<void> _reloadSimilar() async {
    if (_reloadingSimilar) return;
    final future = _loadSimilar();
    setState(() {
      _similar = future;
      _reloadingSimilar = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => _reloadingSimilar = false);
    }
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
      final strings = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            strings.favoriteActionFailed(localizeBrowseError(strings, error)),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _favoriteSaving = false);
    }
  }

  Future<void> _shareShop(ShopDetail shop) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final strings = AppLocalizations.of(context);
    final shareUrl = widget.thirdPartyConfig.shopShareUrl(shop.id);
    final shareText =
        '${shop.name} · ★ ${shop.score.toStringAsFixed(1)} · $shareUrl';
    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    try {
      await Share.share(
        shareText,
        subject: shop.name,
        sharePositionOrigin: sharePositionOrigin,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.shareCopied)),
      );
    } catch (_) {
      // No native share target on this platform (e.g. a desktop/headless
      // environment without a registered handler): fall back to the clipboard
      // so the user can still paste the link instead of losing the action.
      await Clipboard.setData(ClipboardData(text: shareText));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.shareCopied)),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.shopDetail),
        actions: [
          if (widget.enableFavorite)
            IconButton(
              tooltip: _favorited
                  ? strings.unfavoriteShop
                  : strings.favoriteShop,
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
            final error = localizeBrowseError(strings, snapshot.error!);
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings.shopDetailLoadFailed(error)),
                  SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    key: const Key('shop-detail-retry'),
                    onPressed: _reloadingDetail ? null : _reloadDetail,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      _reloadingDetail ? strings.processing : strings.retry,
                    ),
                  ),
                ],
              ),
            );
          }
          final shop = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (shop.coverUrl != null && shop.coverUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    shop.coverUrl!,
                    key: const Key('shop-cover-image'),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      key: const Key('shop-cover-fallback'),
                      height: 200,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Text(strings.shopCoverPlaceholder),
                    ),
                  ),
                )
              else
                Container(
                  key: const Key('shop-cover-fallback'),
                  height: 200,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(strings.shopCoverPlaceholder),
                ),
              const SizedBox(height: 16),
              Text(
                shop.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (strings
                  .certificationBadgeLabel(
                    code: shop.merchantCertificationCode,
                    fallback: shop.merchantCertificationLabel,
                  )
                  .isNotEmpty) ...[
                const SizedBox(height: 8),
                Chip(
                  avatar: const Icon(Icons.verified, size: 16),
                  label: Text(
                    strings.certificationBadgeLabel(
                      code: shop.merchantCertificationCode,
                      fallback: shop.merchantCertificationLabel,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                '${shop.category} · ★ ${shop.score.toStringAsFixed(1)} · ${formatMoney(shop.pricePerCapita, shop.currency, locale: strings.tag)}',
              ),
              const SizedBox(height: 8),
              _ScoreBreakdownTile(
                tasteScore: shop.tasteScore,
                envScore: shop.envScore,
                serviceScore: shop.serviceScore,
              ),
              const SizedBox(height: 24),
              _InfoTile(
                icon: Icons.location_on_outlined,
                title: strings.address,
                value: shop.address,
              ),
              _InfoTile(
                icon: Icons.schedule_outlined,
                title: strings.openingHours,
                value: shop.businessHours,
              ),
              _InfoTile(
                icon: Icons.phone_outlined,
                title: strings.contactPhone,
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
              _RecommendedDishesSection(dishes: shop.recommendedDishes),
              _ShopGallerySection(photos: shop.photos),
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
                          ? strings.favoriteStatusLoading
                          : (_favorited
                                ? strings.unfavoriteShop
                                : strings.favoriteShop),
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
                  child: Text(_sharing ? strings.sharing : strings.shareShop),
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
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(strings.writeReview),
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
                        label: Text(strings.groupDeals),
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
                        label: Text(
                          AppLocalizations.of(context).onlineReservation,
                        ),
                      ),
                    ),
                ],
              ),
              if (_reviews != null) ...[
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).shopReviewsSection,
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
                      child: Text(AppLocalizations.of(context).viewAll),
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
                      final error = localizeBrowseError(
                        AppLocalizations.of(context),
                        reviewSnapshot.error!,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(
                              context,
                            ).shopReviewsLoadFailed(error),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.tonalIcon(
                            key: const Key('shop-review-previews-retry'),
                            onPressed: _reloadingReviewPreviews
                                ? null
                                : _reloadReviewPreviews,
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              _reloadingReviewPreviews
                                  ? AppLocalizations.of(context).processing
                                  : AppLocalizations.of(context).retryReviews,
                            ),
                          ),
                        ],
                      );
                    }
                    final items = reviewSnapshot.data ?? const [];
                    if (items.isEmpty) {
                      return Text(AppLocalizations.of(context).noPublicReviews);
                    }
                    return Column(
                      children: items.map((item) {
                        final userName = item.userName.isEmpty
                            ? AppLocalizations.of(context).anonymousUser
                            : item.userName;
                        return Card(
                          child: ListTile(
                            title: Text(
                              strings
                                      .certificationBadgeLabel(
                                        code: item.authorCertificationCode,
                                        fallback: item.authorCertificationLabel,
                                      )
                                      .isEmpty
                                  ? '$userName · ★ ${item.score.toStringAsFixed(1)}'
                                  : '$userName · ${strings.certificationBadgeLabel(code: item.authorCertificationCode, fallback: item.authorCertificationLabel)} · ★ ${item.score.toStringAsFixed(1)}',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 6),
                                Text(item.content),
                                if (item.merchantReply != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    ).merchantReplyLabel(
                                      item.merchantReply ?? '',
                                    ),
                                    style: const TextStyle(
                                      color: Color(0xFF4B5563),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  '${AppLocalizations.of(context).likeCommentStats(likes: item.likedCount, comments: item.commentCount)}${item.createdAt.isEmpty ? '' : ' · ${formatDisplayDateTime(item.createdAt, locale: AppLocalizations.of(context).tag)}'}',
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
                                        repository: widget.reviewRepository!,
                                        reviewId: item.id,
                                        canInteract: widget.canInteractReviews,
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
              if (_similar != null) ...[
                SizedBox(height: 28),
                Text(
                  AppLocalizations.of(context).similarShopsSection,
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
                      final error = localizeBrowseError(
                        AppLocalizations.of(context),
                        similarSnapshot.error!,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(
                              context,
                            ).similarShopsLoadFailed(error),
                          ),
                          SizedBox(height: 8),
                          FilledButton.tonalIcon(
                            key: const Key('similar-shops-retry'),
                            onPressed: _reloadingSimilar
                                ? null
                                : _reloadSimilar,
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              _reloadingSimilar
                                  ? AppLocalizations.of(context).processing
                                  : AppLocalizations.of(
                                      context,
                                    ).retryRecommendations,
                            ),
                          ),
                        ],
                      );
                    }
                    final items = similarSnapshot.data ?? const [];
                    if (items.isEmpty) {
                      return Text(AppLocalizations.of(context).noSimilarShops);
                    }
                    return Column(
                      children: items
                          .map(
                            (item) => Card(
                              child: ListTile(
                                title: Text(item.name),
                                subtitle: Text(
                                  strings
                                          .certificationBadgeLabel(
                                            code:
                                                item.merchantCertificationCode,
                                            fallback:
                                                item.merchantCertificationLabel,
                                          )
                                          .isEmpty
                                      ? '${item.category} · ★ ${item.score.toStringAsFixed(1)}'
                                      : '${item.category} · ★ ${item.score.toStringAsFixed(1)} · ${strings.certificationBadgeLabel(code: item.merchantCertificationCode, fallback: item.merchantCertificationLabel)}',
                                ),
                                trailing: Text(
                                  formatMoney(
                                    item.pricePerCapita,
                                    item.currency,
                                    locale: strings.tag,
                                  ),
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

class _ScoreBreakdownTile extends StatelessWidget {
  const _ScoreBreakdownTile({
    required this.tasteScore,
    required this.envScore,
    required this.serviceScore,
  });
  final double tasteScore;
  final double envScore;
  final double serviceScore;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ListTile(
      key: const Key('shop-score-breakdown'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.leaderboard_outlined),
      title: Text(strings.scoreBreakdownTitle),
      subtitle: Text(
        strings.scoreBreakdownValue(
          taste: '${strings.scoreTaste} ${tasteScore.toStringAsFixed(1)}',
          env: '${strings.scoreEnv} ${envScore.toStringAsFixed(1)}',
          service: '${strings.scoreService} ${serviceScore.toStringAsFixed(1)}',
        ),
      ),
    );
  }
}

class _RecommendedDishesSection extends StatelessWidget {
  const _RecommendedDishesSection({required this.dishes});
  final List<ShopDish> dishes;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (dishes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Text(
          strings.recommendedDishesMissing,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return Column(
      key: const Key('shop-recommended-dishes'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.recommendedDishesSection,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...dishes.map(
          (dish) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: Text(dish.name),
              subtitle: dish.recommendReason == null ||
                      dish.recommendReason!.isEmpty
                  ? null
                  : Text(strings.dishRecommendReason(dish.recommendReason!)),
              trailing: Text(
                formatMoney(
                  dish.price,
                  '',
                  locale: strings.tag,
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ShopGallerySection extends StatelessWidget {
  const _ShopGallerySection({required this.photos});
  final List<ShopPhoto> photos;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (photos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Text(
          strings.shopGalleryMissing,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return Column(
      key: const Key('shop-gallery'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.shopGallerySection,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photo.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
