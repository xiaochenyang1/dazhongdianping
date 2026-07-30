import 'package:dazhongdianping_app/features/activity/activity_list_screen.dart';
import 'package:dazhongdianping_app/features/activity/activity_repository.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/search_screen.dart';
import 'package:dazhongdianping_app/features/browse/shop_detail_screen.dart';
import 'package:dazhongdianping_app/features/community/community_feed_screen.dart';
import 'package:dazhongdianping_app/features/community/community_repository.dart';
import 'package:dazhongdianping_app/features/circle/circle_repository.dart';
import 'package:dazhongdianping_app/features/notification/notification_repository.dart';
import 'package:dazhongdianping_app/features/rank/rank_list_screen.dart';
import 'package:dazhongdianping_app/features/rank/rank_repository.dart';
import 'package:dazhongdianping_app/features/topic/topic_repository.dart';
import 'package:dazhongdianping_app/core/app_config.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    this.region = AppRegion.eu,
    this.onRegionChanged,
    this.onOrdersTap,
    this.onProfileTap,
    this.onNotificationTap,
    this.currentUserLabel,
    this.localeTag = 'zh-CN',
    this.onLocaleChanged,
    this.thirdPartyConfig = const ThirdPartyConfig(),
    this.tradeRepository,
    this.reservationRepository,
    this.reviewRepository,
    this.canInteractReviews = false,
    this.communityRepository,
    this.canCommunityInteract = false,
    this.onCommunityUserTap,
    this.circleRepository,
    this.topicRepository,
    this.rankRepository,
    this.activityRepository,
    this.notificationRepository,
    this.onCommunityLoginRequired,
  });
  final BrowseRepository repository;
  final AppRegion region;
  final ValueChanged<AppRegion>? onRegionChanged;
  final ValueChanged<BuildContext>? onOrdersTap;
  final ValueChanged<BuildContext>? onProfileTap;
  final Future<void> Function(BuildContext)? onNotificationTap;
  final String? currentUserLabel;
  final String localeTag;
  final ValueChanged<String>? onLocaleChanged;
  final ThirdPartyConfig thirdPartyConfig;
  final TradeRepository? tradeRepository;
  final ReservationRepository? reservationRepository;
  final ReviewRepository? reviewRepository;
  final bool canInteractReviews;
  final CommunityRepository? communityRepository;
  final bool canCommunityInteract;
  final void Function(BuildContext, int)? onCommunityUserTap;
  final CircleRepository? circleRepository;
  final TopicRepository? topicRepository;
  final RankRepository? rankRepository;
  final ActivityRepository? activityRepository;
  final NotificationRepository? notificationRepository;
  final ValueChanged<BuildContext>? onCommunityLoginRequired;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<ShopSummary>> _shops;
  int _notificationUnreadCount = 0;
  int _unreadRequestGeneration = 0;
  bool _openingNotifications = false;

  @override
  void initState() {
    super.initState();
    _shops = widget.repository.loadFeaturedShops();
    _refreshUnreadCount();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.region != widget.region) {
      _reloadShops();
    }
    if (oldWidget.notificationRepository != widget.notificationRepository) {
      _refreshUnreadCount();
    }
  }

  Future<void> _reloadShops() async {
    final future = widget.repository.loadFeaturedShops();
    setState(() {
      _shops = future;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    }
  }

  Future<void> _retry() =>
      Future.wait<void>([_reloadShops(), _refreshUnreadCount()]);

  Future<void> _refreshUnreadCount() async {
    final requestGeneration = ++_unreadRequestGeneration;
    final repository = widget.notificationRepository;
    if (repository == null) {
      if (mounted && _notificationUnreadCount != 0) {
        setState(() => _notificationUnreadCount = 0);
      }
      return;
    }
    try {
      final count = await repository.loadUnreadCount();
      if (!mounted || requestGeneration != _unreadRequestGeneration) return;
      setState(() => _notificationUnreadCount = count);
    } catch (_) {
      // Keep the last known badge when unread-count is temporarily unavailable.
    }
  }

  Future<void> _openNotifications() async {
    if (_openingNotifications) return;
    setState(() => _openingNotifications = true);
    try {
      await widget.onNotificationTap?.call(context);
      if (mounted) await _refreshUnreadCount();
    } finally {
      if (mounted) setState(() => _openingNotifications = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.forTag(widget.localeTag);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.region == AppRegion.eu ? strings.europe : strings.china} · ${strings.homeTitle}',
            ),
            Text(
              strings.homeSubtitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<AppRegion>(
            initialValue: widget.region,
            onSelected: widget.onRegionChanged,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: AppRegion.eu,
                child: Text('EU · ${strings.europe}'),
              ),
              PopupMenuItem(
                value: AppRegion.cn,
                child: Text('CN · ${strings.china}'),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: Text(widget.region.code)),
            ),
          ),
          PopupMenuButton<String>(
            initialValue: widget.localeTag,
            onSelected: widget.onLocaleChanged,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'zh-CN',
                child: Text(strings.simplifiedChinese),
              ),
              PopupMenuItem(
                value: 'zh-TW',
                child: Text(strings.traditionalChinese),
              ),
              PopupMenuItem(value: 'en', child: Text(strings.englishLanguage)),
            ],
            icon: const Icon(Icons.language),
            tooltip: strings.language,
          ),
          IconButton(
            key: const Key('home-map-action'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    widget.thirdPartyConfig.googleMapsEnabled
                        ? strings.mapsConfigured
                        : strings.mapsUnavailable,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.map_outlined),
            tooltip: strings.map,
          ),
          IconButton(
            key: const Key('home-notification-action'),
            onPressed: _openingNotifications ? null : _openNotifications,
            tooltip: strings.notifications,
            icon: Badge(
              key: const Key('home-notification-badge'),
              isLabelVisible: _notificationUnreadCount > 0,
              label: Text(
                _notificationUnreadCount > 99
                    ? '99+'
                    : '$_notificationUnreadCount',
              ),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            key: const Key('home-profile-action'),
            onPressed: () => widget.onProfileTap?.call(context),
            tooltip: strings.account,
            icon: widget.currentUserLabel == null
                ? const Icon(Icons.person_outline)
                : CircleAvatar(
                    radius: 14,
                    child: Text(widget.currentUserLabel!.characters.first),
                  ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _retry,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              textInputAction: TextInputAction.search,
              onSubmitted: (keyword) => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SearchScreen(
                    repository: widget.repository,
                    initialKeyword: keyword,
                    tradeRepository: widget.tradeRepository,
                    reservationRepository: widget.reservationRepository,
                    reviewRepository: widget.reviewRepository,
                    canInteractReviews: widget.canInteractReviews,
                    thirdPartyConfig: widget.thirdPartyConfig,
                  ),
                ),
              ),
              decoration: InputDecoration(
                hintText: strings.searchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (widget.rankRepository != null)
                  ActionChip(
                    key: const Key('home-ranks-entry'),
                    avatar: const Icon(Icons.emoji_events_outlined, size: 18),
                    label: Text(strings.cityRankings),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RankListScreen(
                          repository: widget.rankRepository!,
                          browseRepository: widget.repository,
                          tradeRepository: widget.tradeRepository,
                          reservationRepository: widget.reservationRepository,
                          reviewRepository: widget.reviewRepository,
                          canInteractReviews: widget.canInteractReviews,
                          thirdPartyConfig: widget.thirdPartyConfig,
                        ),
                      ),
                    ),
                  ),
                if (widget.activityRepository != null)
                  ActionChip(
                    key: const Key('home-activities-entry'),
                    avatar: const Icon(Icons.campaign_outlined, size: 18),
                    label: Text(strings.activities),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ActivityListScreen(
                          repository: widget.activityRepository!,
                          browseRepository: widget.repository,
                          tradeRepository: widget.tradeRepository,
                          reservationRepository: widget.reservationRepository,
                          reviewRepository: widget.reviewRepository,
                          canInteractReviews: widget.canInteractReviews,
                          thirdPartyConfig: widget.thirdPartyConfig,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              strings.featured,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<ShopSummary>>(
              future: _shops,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      children: [
                        Text(strings.placesLoadFailed),
                        TextButton(
                          onPressed: _retry,
                          child: Text(strings.retry),
                        ),
                      ],
                    ),
                  );
                }
                final shops = snapshot.data ?? const [];
                if (shops.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: Text(strings.noPlaces)),
                  );
                }
                return Column(
                  children: shops
                      .map(
                        (shop) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFFFE4D5),
                                child: Text(shop.name.characters.first),
                              ),
                              title: Text(
                                shop.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                strings
                                        .certificationBadgeLabel(
                                          code: shop.merchantCertificationCode,
                                          fallback:
                                              shop.merchantCertificationLabel,
                                        )
                                        .isEmpty
                                    ? '${shop.category} · ★ ${shop.score.toStringAsFixed(1)}'
                                    : '${shop.category} · ★ ${shop.score.toStringAsFixed(1)} · ${strings.certificationBadgeLabel(code: shop.merchantCertificationCode, fallback: shop.merchantCertificationLabel)}',
                              ),
                              trailing: Text(
                                formatMoney(
                                  shop.pricePerCapita,
                                  shop.currency,
                                  locale: strings.tag,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ShopDetailScreen(
                                    repository: widget.repository,
                                    shopId: shop.id,
                                    tradeRepository: widget.tradeRepository,
                                    reservationRepository:
                                        widget.reservationRepository,
                                    reviewRepository: widget.reviewRepository,
                                    canInteractReviews:
                                        widget.canInteractReviews,
                                    thirdPartyConfig: widget.thirdPartyConfig,
                                  ),
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
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 1 when widget.communityRepository != null:
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CommunityFeedScreen(
                    repository: widget.communityRepository!,
                    canInteract: widget.canCommunityInteract,
                    onUserTap: widget.onCommunityUserTap,
                    circleRepository: widget.circleRepository,
                    topicRepository: widget.topicRepository,
                    onLoginRequired: widget.onCommunityLoginRequired,
                  ),
                ),
              );
            case 2:
              widget.onOrdersTap?.call(context);
            case 3:
              widget.onProfileTap?.call(context);
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: strings.homeNavigation,
          ),
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            label: strings.exploreNavigation,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            label: strings.ordersNavigation,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            label: strings.profile,
          ),
        ],
      ),
    );
  }
}
