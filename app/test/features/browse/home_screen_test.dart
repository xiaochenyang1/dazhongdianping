import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/home_screen.dart';
import 'package:dazhongdianping_app/features/community/community_repository.dart';
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
    ),
  ];
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

void main() {
  testWidgets('EU home shows region and featured shop', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(repository: FakeBrowseRepository(), localeTag: 'en'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Europe · Local life'), findsOneWidget);
    expect(find.text('London Hotpot'), findsOneWidget);
    expect(find.text('GBP 35'), findsOneWidget);
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
          onNotificationTap: (_) => opened = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home-notification-action')));

    expect(opened, isTrue);
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

    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();

    expect(find.text('华人社区'), findsOneWidget);
  });
}
