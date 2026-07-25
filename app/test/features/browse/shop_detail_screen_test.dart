import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/shop_detail_screen.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class DetailFakeRepository extends BrowseRepository {
  DetailFakeRepository({
    this.favorited = false,
    this.similar = const [
      ShopSummary(
        id: 8,
        name: 'Berlin Dumplings',
        category: 'Chinese',
        score: 4.4,
        currency: 'EUR',
        pricePerCapita: 15,
      ),
    ],
    this.reviews = const [
      ShopReviewPreview(
        id: 501,
        userName: '阿遥',
        score: 4.8,
        content: '茶底干净，服务也稳。',
        likedCount: 2,
        commentCount: 1,
        createdAt: '2026-07-01 18:30',
        authorCertificationLabel: '本地达人',
        merchantReply: '柏林茶馆：谢谢支持。',
      ),
    ],
  });

  bool favorited;
  final List<ShopSummary> similar;
  final List<ShopReviewPreview> reviews;
  final List<String> favoriteCalls = <String>[];
  final List<int> similarRequests = <int>[];
  final List<int> reviewRequests = <int>[];

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

  @override
  Future<bool> isShopFavorited(int shopId) async => favorited;

  @override
  Future<void> favoriteShop(int shopId) async {
    favoriteCalls.add('favorite:$shopId');
    favorited = true;
  }

  @override
  Future<void> unfavoriteShop(int shopId) async {
    favoriteCalls.add('unfavorite:$shopId');
    favorited = false;
  }

  @override
  Future<List<ShopSummary>> loadSimilarShops(int shopId, {int limit = 6}) async {
    similarRequests.add(shopId);
    return similar;
  }

  @override
  Future<List<ShopReviewPreview>> loadShopReviews(
    int shopId, {
    int page = 1,
    int pageSize = 5,
    String sort = 'latest',
  }) async {
    reviewRequests.add(shopId);
    return reviews;
  }
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

  testWidgets('shop detail can favorite and unfavorite a shop', (tester) async {
    final repository = DetailFakeRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ShopDetailScreen(repository: repository, shopId: 7),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('收藏门店'), findsOneWidget);
    await tester.tap(find.text('收藏门店'));
    await tester.pumpAndSettle();

    expect(repository.favoriteCalls, contains('favorite:7'));
    expect(find.text('取消收藏'), findsOneWidget);

    await tester.tap(find.text('取消收藏'));
    await tester.pumpAndSettle();

    expect(repository.favoriteCalls, contains('unfavorite:7'));
    expect(find.text('收藏门店'), findsOneWidget);
  });

  testWidgets('shop detail shows similar shops', (tester) async {
    final repository = DetailFakeRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ShopDetailScreen(repository: repository, shopId: 7),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.similarRequests, contains(7));
    expect(find.text('相似门店'), findsOneWidget);
    expect(find.text('Berlin Dumplings'), findsOneWidget);
  });

  testWidgets('shop detail shows public reviews preview', (tester) async {
    final repository = DetailFakeRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ShopDetailScreen(repository: repository, shopId: 7),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.reviewRequests, contains(7));
    expect(find.text('门店点评'), findsOneWidget);
    expect(find.textContaining('阿遥'), findsOneWidget);
    expect(find.text('茶底干净，服务也稳。'), findsOneWidget);
    expect(find.textContaining('商家回复：柏林茶馆：谢谢支持。'), findsOneWidget);
  });
}
