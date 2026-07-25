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
    double? minScore,
    bool? hasImages,
  }) async {
    reviewRequests.add(shopId);
    return reviews;
  }

  @override
  Future<ShopReviewPage> loadShopReviewPage(
    int shopId, {
    int page = 1,
    int pageSize = 20,
    String sort = 'latest',
    double? minScore,
    bool? hasImages,
  }) async {
    reviewRequests.add(shopId);
    return ShopReviewPage(
      items: reviews,
      page: page,
      pageSize: pageSize,
      total: reviews.length,
      hasMore: false,
    );
  }
}

class DetailReviewApi implements JsonApi {
  final List<String> paths = <String>[];

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    paths.add(path);
    if (path == '/api/c/v1/reviews/501') {
      return {
        'id': 501,
        'shopId': 7,
        'shopName': 'Berlin Tea',
        'userId': 9,
        'userName': '阿遥',
        'content': '茶底干净，服务也稳。',
        'scoreOverall': 4.8,
        'scoreTaste': 5,
        'scoreEnv': 4,
        'scoreService': 5,
        'cost': 12,
        'currency': 'EUR',
        'likeCount': 2,
        'commentCount': 1,
        'likedByCurrentUser': false,
        'auditStatus': 1,
        'auditStatusText': '审核通过',
        'auditRemark': '',
        'status': 1,
        'statusText': '正常',
        'authorCertification': {'code': 'local_expert', 'label': '本地达人'},
        'tags': const [],
        'images': const [],
        'merchantReply': {
          'merchantName': '柏林茶馆',
          'content': '谢谢支持。',
          'repliedAt': '2026-07-01 19:00:00',
          'updatedAt': '2026-07-01 19:00:00',
        },
        'createdAt': '2026-07-01 18:30',
        'updatedAt': '2026-07-01 18:30',
      };
    }
    if (path == '/api/c/v1/reviews/501/comments') {
      return {'list': const [], 'total': 0};
    }
    return const {};
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    paths.add(path);
    return const {};
  }
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
          canInteractReviews: true,
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

  testWidgets('shop detail opens public review detail from preview', (
    tester,
  ) async {
    final repository = DetailFakeRepository();
    final api = DetailReviewApi();
    await tester.pumpWidget(
      MaterialApp(
        home: ShopDetailScreen(
          repository: repository,
          shopId: 7,
          reviewRepository: ReviewRepository(api),
          canInteractReviews: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('茶底干净，服务也稳。'), findsOneWidget);
    await tester.tap(find.text('茶底干净，服务也稳。'));
    await tester.pumpAndSettle();

    expect(find.text('点评详情'), findsOneWidget);
    expect(api.paths, contains('/api/c/v1/reviews/501'));
  });

  testWidgets('shop detail opens full shop reviews list', (tester) async {
    final repository = DetailFakeRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: ShopDetailScreen(
          repository: repository,
          shopId: 7,
          reviewRepository: ReviewRepository(DetailReviewApi()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shop-reviews-view-all')), findsOneWidget);
    await tester.tap(find.byKey(const Key('shop-reviews-view-all')));
    await tester.pumpAndSettle();

    expect(find.text('Berlin Tea · 点评'), findsOneWidget);
    expect(find.text('茶底干净，服务也稳。'), findsOneWidget);
  });

  testWidgets('shop detail can copy share text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ShopDetailScreen(repository: DetailFakeRepository(), shopId: 7),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shop-share-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('shop-share-button')));
    await tester.pumpAndSettle();
    expect(find.text('分享文案已复制'), findsOneWidget);
  });
}
