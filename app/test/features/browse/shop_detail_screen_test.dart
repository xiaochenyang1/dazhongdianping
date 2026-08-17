import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/shop_detail_screen.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class DetailFakeRepository extends BrowseRepository {
  DetailFakeRepository({
    this.favorited = false,
    this.failFirstDetail = false,
    this.failFirstSimilar = false,
    this.failFirstReviews = false,
    this.detailError,
    this.favoriteError,
    this.similarError,
    this.reviewsError,
    this.detailCurrency = 'EUR',
    this.detailPricePerCapita = 12,
    // Rich media (cover/dishes/photos) is opt-in: the default fake keeps the
    // compact layout the pre-existing assertions were written against, mirroring
    // how deal_detail/points_mall tests pass empty image URLs. Tests that
    // exercise the new parity sections pass `true` here.
    this.withCover = false,
    this.withDishes = false,
    this.withPhotos = false,
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
        merchantReply: '谢谢支持。',
      ),
    ],
  });

  bool favorited;
  final bool failFirstDetail;
  final bool failFirstSimilar;
  final bool failFirstReviews;
  final String detailCurrency;
  final num detailPricePerCapita;
  final bool withCover;
  final bool withDishes;
  final bool withPhotos;
  Object? detailError;
  Object? favoriteError;
  Object? similarError;
  Object? reviewsError;
  int detailRequests = 0;
  Completer<void>? detailRetryGate;
  Completer<void>? reviewRetryGate;
  Completer<void>? similarRetryGate;
  final List<ShopSummary> similar;
  final List<ShopReviewPreview> reviews;
  final List<String> favoriteCalls = <String>[];
  final List<int> similarRequests = <int>[];
  final List<int> reviewRequests = <int>[];

  @override
  Future<List<ShopSummary>> loadFeaturedShops() async => const [];

  @override
  Future<ShopDetail> loadShopDetail(int shopId) async {
    detailRequests++;
    if (detailError != null) {
      throw detailError!;
    }
    if (failFirstDetail && detailRequests == 1) {
      throw StateError('network unavailable');
    }
    if (detailRequests > 1) await detailRetryGate?.future;
    return ShopDetail(
      id: 7,
      name: 'Berlin Tea',
      category: 'Tea',
      score: 4.5,
      currency: detailCurrency,
      pricePerCapita: detailPricePerCapita,
      address: 'Alexanderplatz',
      phone: '+493000000',
      businessHours: '09:00-21:00',
      summary: 'Tea and snacks',
      tags: ['Chinese-friendly'],
      latitude: 52.5219,
      longitude: 13.4132,
      coverUrl: withCover
          ? 'https://cdn.example.com/berlin-tea-cover.jpg'
          : null,
      tasteScore: 4.6,
      envScore: 4.4,
      serviceScore: 4.5,
      photos: withPhotos
          ? const [
              ShopPhoto(id: 1, imageUrl: 'https://cdn.example.com/tea-1.jpg'),
              ShopPhoto(id: 2, imageUrl: 'https://cdn.example.com/tea-2.jpg'),
            ]
          : const [],
      recommendedDishes: withDishes
          ? const [
              ShopDish(
                id: 11,
                name: 'Jasmine Cake',
                price: 6.5,
                recommendReason: 'Pairs with the house blend',
              ),
            ]
          : const [],
    );
  }

  @override
  Future<bool> isShopFavorited(int shopId) async => favorited;

  @override
  Future<void> favoriteShop(int shopId) async {
    favoriteCalls.add('favorite:$shopId');
    if (favoriteError != null) {
      throw favoriteError!;
    }
    favorited = true;
  }

  @override
  Future<void> unfavoriteShop(int shopId) async {
    favoriteCalls.add('unfavorite:$shopId');
    if (favoriteError != null) {
      throw favoriteError!;
    }
    favorited = false;
  }

  @override
  Future<List<ShopSummary>> loadSimilarShops(
    int shopId, {
    int limit = 6,
  }) async {
    similarRequests.add(shopId);
    if (similarError != null) {
      throw similarError!;
    }
    if (failFirstSimilar && similarRequests.length == 1) {
      throw StateError('similar network unavailable');
    }
    if (similarRequests.length > 1) await similarRetryGate?.future;
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
    if (reviewsError != null) {
      throw reviewsError!;
    }
    if (failFirstReviews && reviewRequests.length == 1) {
      throw StateError('review network unavailable');
    }
    if (reviewRequests.length > 1) await reviewRetryGate?.future;
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
  testWidgets('shop detail formats all prices using the current locale', (
    tester,
  ) async {
    final repository = DetailFakeRepository(
      detailCurrency: 'JPY',
      detailPricePerCapita: 29.9,
      similar: const [
        ShopSummary(
          id: 8,
          name: 'Tokyo Tea',
          category: 'Tea',
          score: 4.4,
          currency: 'JPY',
          pricePerCapita: 45.5,
        ),
      ],
    );
    await tester.pumpWidget(
      localizedApp(home: ShopDetailScreen(repository: repository, shopId: 7)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('¥30'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Tokyo Tea'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('¥46'), findsOneWidget);
    expect(find.textContaining('JPY '), findsNothing);
  });

  testWidgets('shop detail retries failed review previews locally', (
    tester,
  ) async {
    final repository = DetailFakeRepository(failFirstReviews: true);
    await tester.pumpWidget(
      MaterialApp(home: ShopDetailScreen(repository: repository, shopId: 7)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('shop-review-previews-retry')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.byKey(const Key('shop-review-previews-retry')));
    await tester.pumpAndSettle();
    expect(repository.reviewRequests, [7, 7]);
    expect(find.text('茶底干净，服务也稳。'), findsOneWidget);
    expect(repository.detailRequests, 1);
  });

  testWidgets('shop detail guards duplicate review preview retries', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repository = DetailFakeRepository(failFirstReviews: true)
      ..reviewRetryGate = gate;
    await tester.pumpWidget(
      MaterialApp(home: ShopDetailScreen(repository: repository, shopId: 7)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('shop-review-previews-retry')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    final retry = find.byKey(const Key('shop-review-previews-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(repository.reviewRequests, [7, 7]);

    gate.complete();
    await tester.pumpAndSettle();
    expect(repository.reviewRequests, [7, 7]);
    expect(find.text('茶底干净，服务也稳。'), findsOneWidget);
  });

  testWidgets('shop detail retries failed similar shops locally', (
    tester,
  ) async {
    final repository = DetailFakeRepository(failFirstSimilar: true);
    await tester.pumpWidget(
      MaterialApp(home: ShopDetailScreen(repository: repository, shopId: 7)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('similar-shops-retry')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.byKey(const Key('similar-shops-retry')));
    await tester.pumpAndSettle();
    expect(repository.similarRequests, [7, 7]);
    expect(find.text('Berlin Dumplings'), findsOneWidget);
    expect(repository.detailRequests, 1);
  });

  testWidgets('shop detail guards duplicate similar shop retries', (
    tester,
  ) async {
    final gate = Completer<void>();
    final repository = DetailFakeRepository(failFirstSimilar: true)
      ..similarRetryGate = gate;
    await tester.pumpWidget(
      MaterialApp(home: ShopDetailScreen(repository: repository, shopId: 7)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('similar-shops-retry')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    final retry = find.byKey(const Key('similar-shops-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(repository.similarRequests, [7, 7]);

    gate.complete();
    await tester.pumpAndSettle();
    expect(repository.similarRequests, [7, 7]);
    expect(find.text('Berlin Dumplings'), findsOneWidget);
  });

  testWidgets('shop detail retries an initial load failure safely', (
    tester,
  ) async {
    final repository = DetailFakeRepository(failFirstDetail: true);
    await tester.pumpWidget(
      MaterialApp(home: ShopDetailScreen(repository: repository, shopId: 7)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('门店详情加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('shop-detail-retry')));
    await tester.pumpAndSettle();

    expect(repository.detailRequests, 2);
    expect(find.text('Berlin Tea'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shop detail guards duplicate detail retries', (tester) async {
    final gate = Completer<void>();
    final repository = DetailFakeRepository(failFirstDetail: true)
      ..detailRetryGate = gate;
    await tester.pumpWidget(
      MaterialApp(home: ShopDetailScreen(repository: repository, shopId: 7)),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('shop-detail-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(repository.detailRequests, 2);

    gate.complete();
    await tester.pumpAndSettle();
    expect(repository.detailRequests, 2);
    expect(find.text('Berlin Tea'), findsOneWidget);
  });

  testWidgets('shop detail localizes load failures in English', (tester) async {
    final repository = DetailFakeRepository(
      detailError: const ApiException('商户不存在'),
    );
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: ShopDetailScreen(repository: repository, shopId: 7),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Could not load place details: This place could not be found.'),
      findsOneWidget,
    );
    expect(find.textContaining('商户不存在'), findsNothing);
  });

  testWidgets('shop detail localizes favorite failures in English', (
    tester,
  ) async {
    final repository = DetailFakeRepository(
      favoriteError: const ApiException('用户登录状态不存在'),
    );
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: ShopDetailScreen(repository: repository, shopId: 7),
      ),
    );
    await tester.pumpAndSettle();
    // The favorite button sits below the score-breakdown tile; bring it on
    // screen before tapping.
    await tester.scrollUntilVisible(
      find.text('Save place'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Save place'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save place'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not update favorite: Your sign-in session is no longer available. Please sign in again.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('用户登录状态不存在'), findsNothing);
  });

  testWidgets('shop detail localizes preview failures in English', (
    tester,
  ) async {
    final repository = DetailFakeRepository(
      reviewsError: const ApiException('商户不存在'),
    );
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: ShopDetailScreen(repository: repository, shopId: 7),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('shop-review-previews-retry')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(
      find.text('Could not load place reviews: This place could not be found.'),
      findsOneWidget,
    );
    expect(find.textContaining('商户不存在'), findsNothing);
  });

  testWidgets('shop detail shows address and opening hours', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ShopDetailScreen(repository: DetailFakeRepository(), shopId: 7),
      ),
    );
    await tester.pumpAndSettle();
    // The cover placeholder + score-breakdown tile push the contact row below
    // the 800×600 test viewport; scroll it into view before asserting.
    await tester.scrollUntilVisible(
      find.text('联系电话'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('地址'), findsOneWidget);
    expect(find.text('营业时间'), findsOneWidget);
    expect(find.text('联系电话'), findsOneWidget);
    expect(find.text('Alexanderplatz'), findsOneWidget);
    expect(find.text('09:00-21:00'), findsOneWidget);
    expect(find.text('Berlin Tea'), findsOneWidget);
  });

  testWidgets(
    'shop detail renders cover image, score breakdown, dishes and gallery',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ShopDetailScreen(
            repository: DetailFakeRepository(
              withCover: true,
              withDishes: true,
              withPhotos: true,
            ),
            shopId: 7,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Cover image from the fake repository.
      expect(find.byKey(const Key('shop-cover-image')), findsOneWidget);
      // Score breakdown renders the three sub-scores.
      expect(find.byKey(const Key('shop-score-breakdown')), findsOneWidget);
      expect(find.textContaining('口味 4.6'), findsOneWidget);
      expect(find.textContaining('环境 4.4'), findsOneWidget);
      expect(find.textContaining('服务 4.5'), findsOneWidget);
      // Recommended dishes + gallery live below the fold; scroll them into view.
      await tester.scrollUntilVisible(
        find.byKey(const Key('shop-recommended-dishes')),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('shop-recommended-dishes')), findsOneWidget);
      expect(find.text('Jasmine Cake'), findsOneWidget);
      expect(find.textContaining('Pairs with the house blend'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('shop-gallery')),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('shop-gallery')), findsOneWidget);
    },
  );

  testWidgets(
    'shop detail degrades gracefully when cover, dishes and photos are absent',
    (tester) async {
      final repo = DetailFakeRepository(
        withCover: false,
        withDishes: false,
        withPhotos: false,
      );
      await tester.pumpWidget(
        MaterialApp(home: ShopDetailScreen(repository: repo, shopId: 7)),
      );
      await tester.pumpAndSettle();
      // No cover URL → placeholder container, never an empty Image.network.
      expect(find.byKey(const Key('shop-cover-fallback')), findsOneWidget);
      expect(find.byKey(const Key('shop-cover-image')), findsNothing);
      // Empty dishes / gallery render their missing-state copy below the fold;
      // scroll each into view before asserting.
      await tester.scrollUntilVisible(
        find.textContaining('推荐菜'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.scrollUntilVisible(
        find.textContaining('门店相册'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('推荐菜'), findsOneWidget);
      expect(find.textContaining('门店相册'), findsOneWidget);
    },
  );

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

    await tester.scrollUntilVisible(
      find.text('写点评'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('写点评'), findsOneWidget);
    await tester.tap(find.text('写点评'));
    await tester.pumpAndSettle();

    expect(find.text('Berlin Tea'), findsOneWidget);
    expect(find.byKey(const Key('review-content')), findsOneWidget);
  });

  testWidgets('shop detail can favorite and unfavorite a shop', (tester) async {
    final repository = DetailFakeRepository();
    await tester.pumpWidget(
      MaterialApp(home: ShopDetailScreen(repository: repository, shopId: 7)),
    );
    await tester.pumpAndSettle();
    // The favorite button is below the score-breakdown tile; scroll it on
    // screen before tapping. ensureVisible centers it so the tap's hit-test
    // lands on the button rather than the viewport edge.
    await tester.scrollUntilVisible(
      find.text('收藏门店'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('收藏门店'));
    await tester.pumpAndSettle();

    expect(find.text('收藏门店'), findsOneWidget);
    await tester.tap(find.text('收藏门店'));
    await tester.pumpAndSettle();

    expect(repository.favoriteCalls, contains('favorite:7'));
    expect(find.text('取消收藏'), findsOneWidget);

    await tester.ensureVisible(find.text('取消收藏'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消收藏'));
    await tester.pumpAndSettle();

    expect(repository.favoriteCalls, contains('unfavorite:7'));
    expect(find.text('收藏门店'), findsOneWidget);
  });

  testWidgets('shop detail shows similar shops', (tester) async {
    final repository = DetailFakeRepository();
    await tester.pumpWidget(
      MaterialApp(home: ShopDetailScreen(repository: repository, shopId: 7)),
    );
    await tester.pumpAndSettle();

    expect(repository.similarRequests, contains(7));
    await tester.scrollUntilVisible(
      find.text('相似门店'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
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

    await tester.scrollUntilVisible(
      find.text('茶底干净，服务也稳。'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('茶底干净，服务也稳。'));
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

    await tester.scrollUntilVisible(
      find.byKey(const Key('shop-reviews-view-all')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('shop-reviews-view-all')), findsOneWidget);
    await tester.tap(find.byKey(const Key('shop-reviews-view-all')));
    await tester.pumpAndSettle();

    expect(find.text('Berlin Tea · 点评'), findsOneWidget);
    expect(find.text('茶底干净，服务也稳。'), findsOneWidget);
  });

  testWidgets('shop detail shares via the native share sheet', (tester) async {
    MethodCall? shared;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        if (call.method == 'share') {
          shared = call;
          // A non-empty, non-"unavailable" result string maps to
          // ShareResultStatus.success on the platform side.
          return 'success';
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ShopDetailScreen(repository: DetailFakeRepository(), shopId: 7),
      ),
    );
    await tester.pumpAndSettle();

    // The share button is below the dishes/gallery sections; bring it on
    // screen before tapping.
    await tester.scrollUntilVisible(
      find.byKey(const Key('shop-share-button')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const Key('shop-share-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('shop-share-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('shop-share-button')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(shared, isNotNull);
    // The link is built from the configurable SHARE_BASE_URL placeholder and
    // must point at the shop detail deep link rather than a dead hardcode.
    final args = shared!.arguments as Map;
    expect(args['text'], contains('https://local.life/shops/7'));
    expect(args['subject'], 'Berlin Tea');
    expect(find.text('分享文案已复制'), findsOneWidget);
  });

  testWidgets('shop detail opens Google Maps directions with coordinates', (
    tester,
  ) async {
    Uri? openedUri;
    await tester.pumpWidget(
      MaterialApp(
        home: ShopDetailScreen(
          repository: DetailFakeRepository(),
          shopId: 7,
          thirdPartyConfig: const ThirdPartyConfig(
            googleMapsApiKey: 'AIza-fake-test-key',
          ),
          navigationLauncher: (uri) async {
            openedUri = uri;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('shop-navigation-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('shop-navigation-button')));
    await tester.pumpAndSettle();

    expect(openedUri, isNotNull);
    expect(openedUri!.host, 'www.google.com');
    expect(openedUri!.path, '/maps/dir/');
    expect(openedUri!.queryParameters['destination'], '52.5219,13.4132');
    expect(openedUri!.queryParameters['travelmode'], 'driving');
  });

  testWidgets('shop detail hides navigation without Google Maps config', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ShopDetailScreen(repository: DetailFakeRepository(), shopId: 7),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('shop-navigation-button')), findsNothing);
  });

  testWidgets('shop detail guards duplicate share copies', (tester) async {
    final gate = Completer<void>();
    var shareCalls = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        if (call.method == 'share') {
          shareCalls += 1;
          await gate.future;
          return 'success';
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('dev.fluttercommunity.plus/share'),
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ShopDetailScreen(repository: DetailFakeRepository(), shopId: 7),
      ),
    );
    await tester.pumpAndSettle();

    // Bring the share button on screen before the double-tap.
    await tester.scrollUntilVisible(
      find.byKey(const Key('shop-share-button')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const Key('shop-share-button')));
    await tester.pumpAndSettle();
    final share = find.byKey(const Key('shop-share-button'));
    await tester.tap(share);
    await tester.tap(share);
    await tester.pump();
    expect(shareCalls, 1);
    expect(find.text('分享中...'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(shareCalls, 1);
    expect(find.text('分享文案已复制'), findsOneWidget);
  });
}
