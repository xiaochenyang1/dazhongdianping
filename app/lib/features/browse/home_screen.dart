import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/search_screen.dart';
import 'package:dazhongdianping_app/features/browse/shop_detail_screen.dart';
import 'package:dazhongdianping_app/features/community/community_feed_screen.dart';
import 'package:dazhongdianping_app/features/community/community_repository.dart';
import 'package:dazhongdianping_app/features/circle/circle_repository.dart';
import 'package:dazhongdianping_app/features/topic/topic_repository.dart';
import 'package:dazhongdianping_app/core/app_config.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
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
    this.onProfileTap,
    this.onNotificationTap,
    this.currentUserLabel,
    this.localeTag = 'zh-CN',
    this.onLocaleChanged,
    this.thirdPartyConfig = const ThirdPartyConfig(),
    this.tradeRepository,
    this.reservationRepository,
    this.reviewRepository,
    this.communityRepository,
    this.canCommunityInteract = false,
    this.onCommunityUserTap,
    this.circleRepository,
    this.topicRepository,
    this.onCommunityLoginRequired,
  });
  final BrowseRepository repository;
  final AppRegion region;
  final ValueChanged<AppRegion>? onRegionChanged;
  final ValueChanged<BuildContext>? onProfileTap;
  final ValueChanged<BuildContext>? onNotificationTap;
  final String? currentUserLabel;
  final String localeTag;
  final ValueChanged<String>? onLocaleChanged;
  final ThirdPartyConfig thirdPartyConfig;
  final TradeRepository? tradeRepository;
  final ReservationRepository? reservationRepository;
  final ReviewRepository? reviewRepository;
  final CommunityRepository? communityRepository;
  final bool canCommunityInteract;
  final void Function(BuildContext, int)? onCommunityUserTap;
  final CircleRepository? circleRepository;
  final TopicRepository? topicRepository;
  final ValueChanged<BuildContext>? onCommunityLoginRequired;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<ShopSummary>> _shops;
  @override
  void initState() {
    super.initState();
    _shops = widget.repository.loadFeaturedShops();
  }

  void _retry() =>
      setState(() => _shops = widget.repository.loadFeaturedShops());

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.forTag(widget.localeTag);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.region == AppRegion.eu ? 'Europe' : 'China'} · ${strings.homeTitle}',
            ),
            const Text(
              'Chinese-friendly places nearby',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<AppRegion>(
            initialValue: widget.region,
            onSelected: widget.onRegionChanged,
            itemBuilder: (_) => const [
              PopupMenuItem(value: AppRegion.eu, child: Text('EU · Europe')),
              PopupMenuItem(value: AppRegion.cn, child: Text('CN · China')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: Text(widget.region.code)),
            ),
          ),
          PopupMenuButton<String>(
            initialValue: widget.localeTag,
            onSelected: widget.onLocaleChanged,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'zh-CN', child: Text('简体中文')),
              PopupMenuItem(value: 'zh-TW', child: Text('繁體中文')),
              PopupMenuItem(value: 'en', child: Text('English')),
            ],
            icon: const Icon(Icons.language),
          ),
          IconButton(
            onPressed: () {
              final reason = widget.thirdPartyConfig.unavailableReason(
                ThirdPartyFeature.maps,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(reason.isEmpty ? 'Google Maps 已配置' : reason),
                ),
              );
            },
            icon: const Icon(Icons.map_outlined),
          ),
          IconButton(
            key: const Key('home-notification-action'),
            onPressed: () => widget.onNotificationTap?.call(context),
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            key: const Key('home-profile-action'),
            onPressed: () => widget.onProfileTap?.call(context),
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
        onRefresh: () async => _retry(),
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
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      children: [
                        const Text('Could not load places'),
                        TextButton(
                          onPressed: _retry,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                final shops = snapshot.data ?? const [];
                if (shops.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No places in this city yet')),
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
                                '${shop.category} · ★ ${shop.score.toStringAsFixed(1)}',
                              ),
                              trailing: Text(
                                '${shop.currency} ${shop.pricePerCapita}',
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
          if (index == 1 && widget.communityRepository != null) {
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
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            label: 'Explore',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Orders',
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
