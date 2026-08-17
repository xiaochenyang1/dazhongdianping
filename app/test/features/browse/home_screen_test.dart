import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_config.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/activity/activity_repository.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/home_screen.dart';
import 'package:dazhongdianping_app/features/community/community_repository.dart';
import 'package:dazhongdianping_app/features/notification/notification_repository.dart';
import 'package:dazhongdianping_app/features/rank/rank_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBrowseRepository extends BrowseRepository {
  @override
  Future<List<ShopSummary>> loadFeaturedShops() async => const [
    ShopSummary(
      id: 1,
      name: 'London Hotpot',
      category: 'Chinese',
      score: 4.8,
      currency: 'GBP',
      pricePerCapita: 35,
      address: '10 Gerrard Street, London',
      latitude: 51.5117,
      longitude: -0.1318,
    ),
  ];
}

class EmptyBrowseRepository extends BrowseRepository {
  @override
  Future<List<ShopSummary>> loadFeaturedShops() async => const [];
}

class RetryBrowseRepository extends BrowseRepository {
  int calls = 0;

  @override
  Future<List<ShopSummary>> loadFeaturedShops() async {
    calls += 1;
    if (calls == 1) throw StateError('temporary failure');
    return const [
      ShopSummary(
        id: 2,
        name: 'Retry Cafe',
        category: 'Cafe',
        score: 4.2,
        currency: 'EUR',
        pricePerCapita: 12,
      ),
    ];
  }
}

class NamedBrowseRepository extends BrowseRepository {
  NamedBrowseRepository(this.shop);

  final ShopSummary shop;
  int calls = 0;

  @override
  Future<List<ShopSummary>> loadFeaturedShops() async {
    calls += 1;
    return [shop];
  }
}

class GatedRefreshBrowseRepository extends BrowseRepository {
  int calls = 0;
  final Completer<List<ShopSummary>> refreshGate =
      Completer<List<ShopSummary>>();

  @override
  Future<List<ShopSummary>> loadFeaturedShops() {
    calls += 1;
    if (calls == 1) {
      return Future.value(const [
        ShopSummary(
          id: 1,
          name: 'Before Refresh',
          category: 'Cafe',
          score: 4.1,
          currency: 'EUR',
          pricePerCapita: 10,
        ),
      ]);
    }
    return refreshGate.future;
  }
}

class HomeCommunityApi implements JsonApi {
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async => {'list': const [], 'total': 0};
  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      const {};
}

class HomeNotificationApi implements JsonApi {
  HomeNotificationApi(this.unreadCount);

  int unreadCount;
  int calls = 0;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    calls += 1;
    expect(path, '/api/c/v1/notifications/unread-count');
    return {'count': unreadCount};
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      const {};
}

void main() {
  testWidgets('EU home shows region and featured shop', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: FakeBrowseRepository(),
          localeTag: 'en',
          rankRepository: RankRepository(HomeCommunityApi()),
          activityRepository: ActivityRepository(HomeCommunityApi()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Europe · Local life'), findsOneWidget);
    expect(find.text('London Hotpot'), findsOneWidget);
    expect(find.text('£35.00'), findsOneWidget);
    expect(find.text('City rankings'), findsOneWidget);
    expect(find.text('Activities'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
  });

  testWidgets(
    'retry refreshes featured shops without an async setState error',
    (tester) async {
      final repository = RetryBrowseRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(repository: repository, localeTag: 'en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Retry Cafe'), findsOneWidget);
      expect(repository.calls, 2);
    },
  );

  testWidgets('pull-to-refresh waits for the featured shops request', (
    tester,
  ) async {
    final repository = GatedRefreshBrowseRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(repository: repository, localeTag: 'en'),
      ),
    );
    await tester.pumpAndSettle();

    var completed = false;
    final refresh = tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    refresh.then((_) => completed = true);
    await tester.pump();

    expect(repository.calls, 2);
    expect(completed, isFalse);

    repository.refreshGate.complete(const [
      ShopSummary(
        id: 2,
        name: 'After Refresh',
        category: 'Restaurant',
        score: 4.9,
        currency: 'EUR',
        pricePerCapita: 25,
      ),
    ]);
    await refresh;
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(find.text('After Refresh'), findsOneWidget);
  });

  testWidgets('region change reloads featured shops from the new repository', (
    tester,
  ) async {
    final euRepository = NamedBrowseRepository(
      const ShopSummary(
        id: 1,
        name: 'Europe Bistro',
        category: 'Bistro',
        score: 4.5,
        currency: 'EUR',
        pricePerCapita: 20,
      ),
    );
    final cnRepository = NamedBrowseRepository(
      const ShopSummary(
        id: 2,
        name: 'China Noodles',
        category: 'Noodles',
        score: 4.6,
        currency: 'CNY',
        pricePerCapita: 30,
      ),
    );
    late StateSetter updateHost;
    var region = AppRegion.eu;
    var repository = euRepository;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          updateHost = setState;
          return MaterialApp(
            home: HomeScreen(repository: repository, region: region),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Europe Bistro'), findsOneWidget);

    updateHost(() {
      region = AppRegion.cn;
      repository = cnRepository;
    });
    await tester.pumpAndSettle();

    expect(find.text('China Noodles'), findsOneWidget);
    expect(find.text('Europe Bistro'), findsNothing);
    expect(euRepository.calls, 1);
    expect(cnRepository.calls, 1);
  });

  testWidgets('profile action delegates to authentication flow', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: FakeBrowseRepository(),
          onProfileTap: (_) => opened = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-profile-action')));
    expect(opened, isTrue);
  });

  testWidgets('notification action delegates to notification flow', (
    tester,
  ) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: FakeBrowseRepository(),
          onNotificationTap: (_) async => opened = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home-notification-action')));

    expect(opened, isTrue);
  });

  testWidgets(
    'notification badge loads and refreshes after notification flow',
    (tester) async {
      final api = HomeNotificationApi(120);
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            repository: FakeBrowseRepository(),
            notificationRepository: NotificationRepository(api),
            onNotificationTap: (_) async => api.unreadCount = 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('99+'), findsOneWidget);
      expect(api.calls, 1);

      await tester.tap(find.byKey(const Key('home-notification-action')));
      await tester.pumpAndSettle();

      expect(find.text('99+'), findsNothing);
      expect(api.calls, 2);
    },
  );

  testWidgets('notification action guards duplicate opens', (tester) async {
    final gate = Completer<void>();
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: FakeBrowseRepository(),
          onNotificationTap: (_) async {
            opened += 1;
            await gate.future;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final action = find.byKey(const Key('home-notification-action'));
    await tester.tap(action);
    await tester.tap(action);
    await tester.pump();
    expect(opened, 1);

    gate.complete();
    await tester.pumpAndSettle();
    expect(opened, 1);
  });

  testWidgets('orders and profile bottom destinations delegate to real flows', (
    tester,
  ) async {
    var ordersOpened = 0;
    var profileOpened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: FakeBrowseRepository(),
          onOrdersTap: (_) => ordersOpened++,
          onProfileTap: (_) => profileOpened++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('订单'));
    await tester.pump();
    await tester.tap(find.text('我的'));
    await tester.pump();

    expect(ordersOpened, 1);
    expect(profileOpened, 1);
  });

  testWidgets('explore navigation opens the real community feed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: FakeBrowseRepository(),
          communityRepository: CommunityRepository(HomeCommunityApi()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('发现'));
    await tester.pumpAndSettle();

    expect(find.text('华人社区'), findsOneWidget);
  });

  testWidgets('Traditional Chinese home localizes navigation and empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: EmptyBrowseRepository(),
          localeTag: 'zh-TW',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('歐洲 · 在地生活'), findsOneWidget);
    expect(find.text('探索附近更適合華人的好去處'), findsOneWidget);
    expect(find.text('附近推薦'), findsOneWidget);
    expect(find.text('目前城市暫無店家'), findsOneWidget);
    expect(find.text('首頁'), findsOneWidget);
    expect(find.text('探索'), findsOneWidget);
    expect(find.text('訂單'), findsOneWidget);
  });

  testWidgets('hides the map action when Google Maps is not configured', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(repository: FakeBrowseRepository(), localeTag: 'en'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-map-action')), findsNothing);
    expect(
      find.text(
        'Google Maps is not configured. City and list browsing remain available.',
      ),
      findsNothing,
    );
  });

  testWidgets('shows the map action when Google Maps is configured', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          repository: FakeBrowseRepository(),
          localeTag: 'en',
          thirdPartyConfig: const ThirdPartyConfig(
            googleMapsApiKey: 'AIza-fake-test-key',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home-map-action')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shop-google-map')), findsOneWidget);
    expect(find.byKey(const Key('shop-map-selected-card')), findsOneWidget);
    expect(find.text('London Hotpot'), findsWidgets);
  });
}
