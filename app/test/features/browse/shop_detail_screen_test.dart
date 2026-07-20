import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/shop_detail_screen.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class DetailFakeRepository extends BrowseRepository {
  @override
  Future<List<ShopSummary>> loadFeaturedShops() async => const [];

  @override
  Future<ShopDetail> loadShopDetail(int shopId) async => const ShopDetail(
    id: 7,
    name: 'Berlin Tea',
    category: 'Tea',
    score: 4.5,
    currency: 'EUR',
    pricePerCapita: 12,
    address: 'Alexanderplatz',
    phone: '+493000000',
    businessHours: '09:00-21:00',
    summary: 'Tea and snacks',
    tags: ['Chinese-friendly'],
  );
}

class DetailReviewApi implements JsonApi {
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async => const {};

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      const {};
}

void main() {
  testWidgets('shop detail shows address and opening hours', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ShopDetailScreen(repository: DetailFakeRepository(), shopId: 7),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Alexanderplatz'), findsOneWidget);
    expect(find.text('09:00-21:00'), findsOneWidget);
    expect(find.text('Berlin Tea'), findsOneWidget);
  });

  testWidgets('shop detail opens the review editor for signed-in users', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ShopDetailScreen(
          repository: DetailFakeRepository(),
          shopId: 7,
          reviewRepository: ReviewRepository(DetailReviewApi()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('写点评'), findsOneWidget);
    await tester.tap(find.text('写点评'));
    await tester.pumpAndSettle();

    expect(find.text('Berlin Tea'), findsOneWidget);
    expect(find.byKey(const Key('review-content')), findsOneWidget);
  });
}
