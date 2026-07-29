import 'dart:async';

import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/shop_reviews_screen.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class ReviewsFakeRepository extends BrowseRepository {
  ReviewsFakeRepository({this.failFirst = false});

  final bool failFirst;
  int pageRequests = 0;
  Completer<void>? retryGate;
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
    pageRequests++;
    if (failFirst && pageRequests == 1) {
      throw StateError('network unavailable');
    }
    if (pageRequests > 1) await retryGate?.future;
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
              id: 501,
              userName: '阿遥',
              score: 4.8,
              content: '茶底干净，服务也稳。',
              likedCount: 2,
              commentCount: 1,
              createdAt: '2026-07-01 18:30',
            ),
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

class DeferredReviewsRepository extends ReviewsFakeRepository {
  final Map<String, Completer<ShopReviewPage>> responses = {};

  @override
  Future<ShopReviewPage> loadShopReviewPage(
    int shopId, {
    int page = 1,
    int pageSize = 20,
    String sort = 'latest',
    double? minScore,
    bool? hasImages,
  }) {
    requests.add({'sort': sort, 'page': page});
    return (responses[sort] ??= Completer<ShopReviewPage>()).future;
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

Widget localizedApp({
  required Widget home,
  Locale locale = const Locale('zh', 'CN'),
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );
}

void main() {
  testWidgets('shop reviews screen retries an initial load failure', (
    tester,
  ) async {
    final repository = ReviewsFakeRepository(failFirst: true);
    await tester.pumpWidget(
      MaterialApp(home: ShopReviewsScreen(repository: repository, shopId: 7)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('门店点评加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('shop-reviews-retry')));
    await tester.pumpAndSettle();

    expect(repository.pageRequests, 2);
    expect(find.text('茶底干净，服务也稳。'), findsOneWidget);
  });

  testWidgets('shop reviews screen guards duplicate retries', (tester) async {
    final gate = Completer<void>();
    final repository = ReviewsFakeRepository(failFirst: true)..retryGate = gate;
    await tester.pumpWidget(
      MaterialApp(home: ShopReviewsScreen(repository: repository, shopId: 7)),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('shop-reviews-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(repository.pageRequests, 2);

    gate.complete();
    await tester.pumpAndSettle();
    expect(repository.pageRequests, 2);
    expect(find.text('茶底干净，服务也稳。'), findsOneWidget);
  });

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
    expect(find.text('茶底干净，服务也稳。'), findsOneWidget);
    expect(repository.requests.last['page'], 2);

    await tester.tap(find.text('茶底干净，服务也稳。'));
    await tester.pumpAndSettle();
    expect(find.text('点评详情'), findsOneWidget);
    expect(api.paths, contains('/api/c/v1/reviews/501'));
  });

  testWidgets('shop reviews screen ignores stale filter responses', (
    tester,
  ) async {
    final repository = DeferredReviewsRepository();
    await tester.pumpWidget(
      MaterialApp(home: ShopReviewsScreen(repository: repository, shopId: 7)),
    );

    await tester.tap(find.byKey(const Key('shop-reviews-sort-popular')));
    await tester.pump();
    repository.responses['popular']!.complete(
      const ShopReviewPage(
        items: [
          ShopReviewPreview(
            id: 602,
            userName: '热门用户',
            score: 5,
            content: '当前筛选结果',
            likedCount: 8,
            commentCount: 2,
            createdAt: '',
          ),
        ],
        page: 1,
        pageSize: 20,
        total: 1,
        hasMore: false,
      ),
    );
    await tester.pump();
    repository.responses['latest']!.complete(
      const ShopReviewPage(
        items: [
          ShopReviewPreview(
            id: 601,
            userName: '旧用户',
            score: 3,
            content: '过期筛选结果',
            likedCount: 0,
            commentCount: 0,
            createdAt: '',
          ),
        ],
        page: 1,
        pageSize: 20,
        total: 1,
        hasMore: false,
      ),
    );
    await tester.pump();

    expect(find.text('当前筛选结果'), findsOneWidget);
    expect(find.text('过期筛选结果'), findsNothing);
  });

  testWidgets('shop reviews screen localizes English chrome', (tester) async {
    final repository = ReviewsFakeRepository();
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: ShopReviewsScreen(
          repository: repository,
          shopId: 7,
          shopName: 'Berlin Tea House',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Berlin Tea House · Reviews'), findsOneWidget);
    expect(find.text('Load more'), findsOneWidget);
    expect(find.textContaining('2 likes · 1 comments'), findsOneWidget);
  });
}
