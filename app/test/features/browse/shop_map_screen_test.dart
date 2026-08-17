import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/shop_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MapBrowseRepository extends BrowseRepository {
  int? detailShopId;

  @override
  Future<List<ShopSummary>> loadFeaturedShops() => loadMapShops();

  @override
  Future<List<ShopSummary>> loadMapShops() async => const [
    ShopSummary(
      id: 1,
      name: 'Paris Tea',
      category: 'Tea',
      score: 4.5,
      currency: 'EUR',
      pricePerCapita: 12,
      address: '12 Rue du Temple, Paris',
      latitude: 48.857,
      longitude: 2.356,
    ),
    ShopSummary(
      id: 2,
      name: 'London Hotpot',
      category: 'Hotpot',
      score: 4.8,
      currency: 'GBP',
      pricePerCapita: 35,
      address: '10 Gerrard Street, London',
      latitude: 51.5117,
      longitude: -0.1318,
    ),
    ShopSummary(
      id: 3,
      name: 'Missing Coordinates',
      category: 'Cafe',
      score: 4.0,
      currency: 'EUR',
      pricePerCapita: 10,
    ),
  ];

  @override
  Future<ShopDetail> loadShopDetail(int shopId) async {
    detailShopId = shopId;
    return ShopDetail(
      id: shopId,
      name: shopId == 2 ? 'London Hotpot' : 'Paris Tea',
      category: shopId == 2 ? 'Hotpot' : 'Tea',
      score: shopId == 2 ? 4.8 : 4.5,
      currency: shopId == 2 ? 'GBP' : 'EUR',
      pricePerCapita: shopId == 2 ? 35 : 12,
      address: shopId == 2
          ? '10 Gerrard Street, London'
          : '12 Rue du Temple, Paris',
      latitude: shopId == 2 ? 51.5117 : 48.857,
      longitude: shopId == 2 ? -0.1318 : 2.356,
      phone: '',
      businessHours: '10:00-22:00',
      summary: 'Map detail',
      tags: const [],
    );
  }

  @override
  Future<List<ShopSummary>> loadSimilarShops(
    int shopId, {
    int limit = 6,
  }) async => const [];

  @override
  Future<List<ShopReviewPreview>> loadShopReviews(
    int shopId, {
    int page = 1,
    int pageSize = 5,
    String sort = 'latest',
    double? minScore,
    bool? hasImages,
  }) async => const [];

  @override
  Future<bool> isShopFavorited(int shopId) async => false;
}

Widget testMapBuilder(
  BuildContext context,
  List<ShopSummary> shops,
  int selectedShopId,
  ValueChanged<int> onShopSelected,
) => Container(
  key: const Key('fake-map'),
  child: Text('shops=${shops.length};selected=$selectedShopId'),
);

void main() {
  testWidgets('map screen fails closed without Google Maps configuration', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ShopMapScreen(
          repository: MapBrowseRepository(),
          thirdPartyConfig: const ThirdPartyConfig(),
          mapBuilder: testMapBuilder,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Google Maps 未配置，仍可按城市和列表浏览。'), findsOneWidget);
    expect(find.byKey(const Key('fake-map')), findsNothing);
  });

  testWidgets('map screen filters coordinates and opens selected shop', (
    tester,
  ) async {
    final repository = MapBrowseRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ShopMapScreen(
          repository: repository,
          thirdPartyConfig: const ThirdPartyConfig(
            googleMapsApiKey: 'AIza-fake-test-key',
          ),
          mapBuilder: testMapBuilder,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('shops=2;selected=1'), findsOneWidget);
    expect(find.text('Missing Coordinates'), findsNothing);

    await tester.tap(find.byKey(const Key('shop-map-place-2')));
    await tester.pumpAndSettle();
    expect(find.text('shops=2;selected=2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('shop-map-view-detail')));
    await tester.pumpAndSettle();

    expect(repository.detailShopId, 2);
    expect(find.text('London Hotpot'), findsWidgets);
  });
}
