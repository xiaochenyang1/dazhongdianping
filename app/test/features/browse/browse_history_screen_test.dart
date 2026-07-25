import 'package:dazhongdianping_app/features/browse/browse_history_screen.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class BrowseHistoryFakeRepository extends BrowseRepository {
  BrowseHistoryFakeRepository({List<ShopBrowseHistoryItem>? history})
    : history = List<ShopBrowseHistoryItem>.from(
        history ??
            const [
              ShopBrowseHistoryItem(
                id: 1,
                shopId: 10001,
                shopName: 'London Hotpot',
                score: 4.8,
                currency: 'GBP',
                pricePerCapita: 35,
                address: 'Chinatown',
                cityName: 'London',
                areaName: 'Soho',
                viewCount: 2,
                lastViewedAt: '2026-07-25 18:00',
              ),
              ShopBrowseHistoryItem(
                id: 2,
                shopId: 10002,
                shopName: 'Paris Cafe',
                score: 4.5,
                currency: 'EUR',
                pricePerCapita: 18,
                address: 'Marais',
                cityName: 'Paris',
                areaName: '3e',
                viewCount: 1,
                lastViewedAt: '2026-07-25 17:00',
              ),
            ],
      );

  List<ShopBrowseHistoryItem> history;
  int clearCalls = 0;
  final List<int> removedShopIds = <int>[];

  @override
  Future<List<ShopSummary>> loadFeaturedShops() async => const [];

  @override
  Future<List<ShopBrowseHistoryItem>> loadBrowseHistory({
    int page = 1,
    int pageSize = 20,
  }) async => history;

  @override
  Future<void> clearBrowseHistory() async {
    clearCalls += 1;
    history = const [];
  }

  @override
  Future<void> removeBrowseHistoryItem(int shopId) async {
    removedShopIds.add(shopId);
    history = history.where((item) => item.shopId != shopId).toList();
  }
}

void main() {
  testWidgets('browse history screen lists shops and supports remove/clear', (
    tester,
  ) async {
    final repository = BrowseHistoryFakeRepository();

    await tester.pumpWidget(
      MaterialApp(home: BrowseHistoryScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('我的足迹'), findsOneWidget);
    expect(find.text('London Hotpot'), findsOneWidget);
    expect(find.text('Paris Cafe'), findsOneWidget);
    expect(find.textContaining('浏览 2 次'), findsOneWidget);

    await tester.tap(find.byTooltip('删除足迹').first);
    await tester.pumpAndSettle();

    expect(repository.removedShopIds, contains(10001));
    expect(find.text('London Hotpot'), findsNothing);
    expect(find.text('Paris Cafe'), findsOneWidget);

    await tester.tap(find.text('清空'));
    await tester.pumpAndSettle();

    expect(repository.clearCalls, 1);
    expect(find.text('当前区域还没有浏览足迹'), findsOneWidget);
  });
}
