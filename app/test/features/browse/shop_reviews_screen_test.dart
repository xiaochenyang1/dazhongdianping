import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/shop_reviews_screen.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ReviewsFakeRepository extends BrowseRepository {
  final List<Map<String, Object?>> requests = <Map<String, Object?>>[];

  @override
  Future<List<ShopSummary>> loadFeaturedShops() async => const [];

  @override
  Future<ShopReviewPage> loadShopReviewPage(
    int shopId, {
    int page = 1,
    int pageSize = 20,
    String sort = 'latest',
    double? minScore,
    bool? hasImages,
  }) async {
    requests.add({
      'shopId': shopId,
      'page': page,
      'pageSize': pageSize,
      'sort': sort,
      'minScore': minScore,
      'hasImages': hasImages,
    });
    final items = page == 1
        ? const [
            ShopReviewPreview(
              id: 501,
              userName: '阿遥',
              score: 4.8,
              content: '茶底干净，服务也稳。',
              likedCount: 2,
              commentCount: 1,
              createdAt: '2026-07-01 18:30',
              authorCertificationLabel: '本地达人',
            ),
          ]
        : const [
            ShopReviewPreview(
              id: 502,
              userName: '小林',
              score: 4.2,
              content: '周末人有点多。',
              likedCount: 1,
              commentCount: 0,
              createdAt: '2026-07-02 12:00',
            ),
          ];
    return ShopReviewPage(
      items: items,
      page: page,
      pageSize: pageSize,
      total: 2,
      hasMore: page == 1,
    );
  }
}

class ReviewsDetailApi implements JsonApi {
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
        'shopName': '柏林茶馆',
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
        'tags': const [],
        'images': const [],
        'createdAt': '2026-07-01 18:30',
        'updatedAt': '2026-07-01 18:30',
      };
    }
    if (path.endsWith('/comments')) {
      return {'list': const [], 'total': 0};
    }
    return const {};
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      const {};
}

void main() {
  testWidgets('shop reviews screen filters sorts and opens review detail', (
    tester,
  ) async {
    final repository = ReviewsFakeRepository();
    final api = ReviewsDetailApi();
    await tester.pumpWidget(
      MaterialApp(
        home: ShopReviewsScreen(
          repository: repository,
          shopId: 7,
          shopName: '柏林茶馆',
          reviewRepository: ReviewRepository(api),
          canInteractReviews: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('柏林茶馆 · 点评'), findsOneWidget);
    expect(find.text('茶底干净，服务也稳。'), findsOneWidget);
    expect(repository.requests.first['sort'], 'latest');

    await tester.tap(find.byKey(const Key('shop-reviews-sort-popular')));
    await tester.pumpAndSettle();
    expect(repository.requests.last['sort'], 'popular');

    await tester.tap(find.byKey(const Key('shop-reviews-filter-score4')));
    await tester.pumpAndSettle();
    expect(repository.requests.last['minScore'], 4);

    await tester.tap(find.byKey(const Key('shop-reviews-load-more')));
    await tester.pumpAndSettle();
    expect(find.text('周末人有点多。'), findsOneWidget);
    expect(repository.requests.last['page'], 2);

    await tester.tap(find.text('茶底干净，服务也稳。'));
    await tester.pumpAndSettle();
    expect(find.text('点评详情'), findsOneWidget);
    expect(api.paths, contains('/api/c/v1/reviews/501'));
  });
}
