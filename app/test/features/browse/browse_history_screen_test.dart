import 'dart:async';

import 'package:dazhongdianping_app/features/browse/browse_history_screen.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class BrowseHistoryFakeRepository extends BrowseRepository {
  BrowseHistoryFakeRepository({
    List<ShopBrowseHistoryItem>? history,
    this.paginated = false,
  }) : history = List<ShopBrowseHistoryItem>.from(
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
  final bool paginated;
  int clearCalls = 0;
  final List<int> removedShopIds = <int>[];
  final List<int> requestedPages = <int>[];
  bool failNextLoad = false;
  Completer<void>? clearGate;
  final Map<int, Completer<void>> removeGates = {};
  final Map<int, Completer<void>> pageGates = {};

  @override
  Future<List<ShopSummary>> loadFeaturedShops() async => const [];

  @override
  Future<List<ShopBrowseHistoryItem>> loadBrowseHistory({
    int page = 1,
    int pageSize = 20,
  }) async => history;

  @override
  Future<ShopBrowseHistoryPage> loadBrowseHistoryPage({
    int page = 1,
    int pageSize = 20,
  }) async {
    requestedPages.add(page);
    await pageGates[page]?.future;
    if (failNextLoad) {
      failNextLoad = false;
      throw Exception('browse history network unavailable');
    }
    final effectivePageSize = paginated ? 1 : pageSize;
    final start = (page - 1) * effectivePageSize;
    final items = start >= history.length
        ? const <ShopBrowseHistoryItem>[]
        : history.skip(start).take(effectivePageSize).toList();
    return ShopBrowseHistoryPage(
      items: items,
      total: history.length,
      page: page,
      pageSize: effectivePageSize,
    );
  }

  @override
  Future<void> clearBrowseHistory() async {
    clearCalls += 1;
    await clearGate?.future;
    history = const [];
  }

  @override
  Future<void> removeBrowseHistoryItem(int shopId) async {
    removedShopIds.add(shopId);
    await removeGates[shopId]?.future;
    history = history.where((item) => item.shopId != shopId).toList();
  }
}

void main() {
  testWidgets('browse history screen loads later pages', (tester) async {
    final repository = BrowseHistoryFakeRepository(paginated: true);
    await tester.pumpWidget(
      MaterialApp(home: BrowseHistoryScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('London Hotpot'), findsOneWidget);
    expect(find.text('Paris Cafe'), findsNothing);
    expect(find.byKey(const Key('browse-history-load-more')), findsOneWidget);

    await tester.tap(find.byKey(const Key('browse-history-load-more')));
    await tester.pumpAndSettle();

    expect(repository.requestedPages, [1, 2]);
    expect(find.text('Paris Cafe'), findsOneWidget);
    expect(find.byKey(const Key('browse-history-load-more')), findsNothing);
  });

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

  testWidgets('browse history refresh invalidates a pending next page', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repository = BrowseHistoryFakeRepository(paginated: true)
      ..pageGates[2] = gate;
    await tester.pumpWidget(
      MaterialApp(home: BrowseHistoryScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('browse-history-load-more')));
    await tester.pump();
    expect(repository.requestedPages, [1, 2]);

    await tester.drag(find.byType(ListView), const Offset(0, 320));
    await tester.pumpAndSettle();
    expect(repository.requestedPages, [1, 2, 1]);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('London Hotpot'), findsOneWidget);
    expect(find.text('Paris Cafe'), findsNothing);
    expect(find.byKey(const Key('browse-history-load-more')), findsOneWidget);
  });

  testWidgets('browse history retries an initial load failure', (tester) async {
    final repository = BrowseHistoryFakeRepository()..failNextLoad = true;
    await tester.pumpWidget(
      MaterialApp(home: BrowseHistoryScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('足迹加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('browse-history-retry')));
    await tester.pumpAndSettle();

    expect(repository.requestedPages, [1, 1]);
    expect(find.text('London Hotpot'), findsOneWidget);
    expect(find.textContaining('足迹加载失败'), findsNothing);
  });

  testWidgets('browse history guards duplicate item removal', (tester) async {
    final repository = BrowseHistoryFakeRepository()
      ..removeGates[10001] = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(home: BrowseHistoryScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    final remove = find.byKey(const Key('browse-history-remove-10001'));
    await tester.tap(remove);
    await tester.tap(remove);
    await tester.pump();

    expect(repository.removedShopIds, [10001]);
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('browse-history-clear')))
          .onPressed,
      isNull,
    );
    repository.removeGates[10001]!.complete();
    await tester.pumpAndSettle();

    expect(find.text('London Hotpot'), findsNothing);
    expect(find.text('Paris Cafe'), findsOneWidget);
  });

  testWidgets('browse history blocks item removal while clearing', (
    tester,
  ) async {
    final repository = BrowseHistoryFakeRepository()
      ..clearGate = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(home: BrowseHistoryScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    final clear = find.byKey(const Key('browse-history-clear'));
    final remove = find.byKey(const Key('browse-history-remove-10001'));
    await tester.tap(clear);
    await tester.tap(clear);
    await tester.tap(remove, warnIfMissed: false);

    expect(repository.clearCalls, 1);
    expect(repository.removedShopIds, isEmpty);
    repository.clearGate!.complete();
    await tester.pumpAndSettle();

    expect(find.text('当前区域还没有浏览足迹'), findsOneWidget);
  });

  testWidgets('clear invalidates an in-flight browse history page', (
    tester,
  ) async {
    final repository = BrowseHistoryFakeRepository(paginated: true);
    await tester.pumpWidget(
      MaterialApp(home: BrowseHistoryScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    repository.pageGates[2] = Completer<void>();

    await tester.tap(find.byKey(const Key('browse-history-load-more')));
    await tester.tap(find.byKey(const Key('browse-history-clear')));
    await tester.pumpAndSettle();

    expect(repository.clearCalls, 1);
    expect(find.text('当前区域还没有浏览足迹'), findsOneWidget);
    repository.pageGates[2]!.complete();
    await tester.pumpAndSettle();

    expect(find.text('London Hotpot'), findsNothing);
    expect(find.text('Paris Cafe'), findsNothing);
  });

  testWidgets('failed browse history refresh preserves loaded items', (
    tester,
  ) async {
    final repository = BrowseHistoryFakeRepository();
    await tester.pumpWidget(
      MaterialApp(home: BrowseHistoryScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    repository.failNextLoad = true;

    await tester.drag(find.byType(ListView), const Offset(0, 320));
    await tester.pumpAndSettle();

    expect(find.text('London Hotpot'), findsOneWidget);
    expect(find.text('Paris Cafe'), findsOneWidget);
    expect(find.textContaining('刷新足迹失败'), findsOneWidget);
    expect(repository.requestedPages, [1, 1]);
  });
}
