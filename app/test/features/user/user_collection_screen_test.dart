import 'dart:async';

import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/user/user_collection_screen.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class CollectionApi implements JsonApi {
  CollectionApi({this.paginatedReviews = false, this.failFirstReviews = false});

  final bool paginatedReviews;
  final bool failFirstReviews;
  Object? reviewError;
  Object? loadMoreReviewError;
  int reviewRequests = 0;
  Completer<void>? reviewRetryGate;
  final List<int> requestedReviewPages = <int>[];

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (path == '/api/c/v1/user/reviews') {
      reviewRequests++;
      final page = query?['page'] as int? ?? 1;
      if (page == 1 && reviewError != null) {
        throw reviewError!;
      }
      if (page > 1 && loadMoreReviewError != null) {
        throw loadMoreReviewError!;
      }
      if (failFirstReviews && reviewRequests == 1) {
        throw StateError('network unavailable');
      }
      if (reviewRequests > 1) await reviewRetryGate?.future;
      requestedReviewPages.add(page);
      return {
        'list': [
          {
            'id': paginatedReviews ? 11 + page : 12,
            'shopId': 7,
            'shopName': page == 1 ? '柏林茶馆' : '巴黎面馆',
            'content': page == 1 ? '原来的体验记录' : '更早的体验记录',
            'scoreOverall': 4,
            'auditStatusText': '待审核',
          },
        ],
        'total': paginatedReviews ? 2 : 1,
        'page': page,
        'pageSize': paginatedReviews ? 1 : 30,
      };
    }
    if (path == '/api/c/v1/user/posts') {
      return {
        'list': [communityPost, approvedPost],
        'total': 2,
      };
    }
    if (path == '/api/c/v1/user/posts/7') return communityPost;
    if (path == '/api/c/v1/posts/8') return approvedPost;
    if (path == '/api/c/v1/posts/8/comments') {
      return {'list': const [], 'total': 0};
    }
    if (path == '/api/c/v1/orders') {
      return {
        'list': [order],
        'total': 1,
      };
    }
    if (path == '/api/c/v1/orders/10') return order;
    if (path == '/api/c/v1/coupons') {
      return {
        'list': [coupon],
        'total': 1,
      };
    }
    if (path == '/api/c/v1/coupons/CP-DEMO') {
      return {
        ...coupon,
        'rules': '周末通用',
        'validStart': '2026-01-01',
        'validEnd': '2026-12-31',
        'verifyAt': '',
        'usable': true,
        'qrPayload': 'CP-DEMO',
        'qrImageUrl': '',
        'verifyHint': '到店后出示二维码或券码，由商户核销。',
      };
    }
    if (path == '/api/c/v1/reservations') {
      return {
        'list': [reservation],
        'total': 1,
      };
    }
    if (path == '/api/c/v1/reservations/11') return reservation;
    if (path == '/api/c/v1/favorites') {
      return {
        'list': [
          {
            'id': 31,
            'targetType': 1,
            'targetId': 7,
            'createdAt': '2026-07-25 18:00:00',
            'target': {
              'id': 7,
              'name': '柏林茶馆',
              'cityName': 'Berlin',
              'areaName': 'Mitte',
              'score': 4.5,
            },
          },
          {
            'id': 32,
            'targetType': 2,
            'targetId': 7,
            'createdAt': '2026-07-25 18:10:00',
            'target': {'id': 7, 'name': '伦敦周末市场指南'},
          },
        ],
        'total': 2,
      };
    }
    if (path == '/api/c/v1/shops/7') {
      return {
        'id': 7,
        'name': '柏林茶馆',
        'categoryName': 'Tea',
        'score': 4.5,
        'currency': 'EUR',
        'pricePerCapita': 12,
        'address': 'Alexanderplatz',
        'phone': '+493000000',
        'businessHours': '09:00-21:00',
        'summary': 'Tea and snacks',
        'tags': ['Chinese-friendly'],
      };
    }
    if (path == '/api/c/v1/posts/7') return communityPost;
    if (path == '/api/c/v1/user/reviews/12') {
      return {
        'id': 12,
        'shopId': 7,
        'shopName': '柏林茶馆',
        'userId': 1,
        'userName': '我',
        'content': '原来的体验记录',
        'scoreOverall': 4,
        'scoreTaste': 5,
        'scoreEnv': 4,
        'scoreService': 4,
        'cost': 18,
        'currency': 'EUR',
        'likeCount': 0,
        'commentCount': 0,
        'likedByCurrentUser': false,
        'auditStatus': 0,
        'auditStatusText': '待审核',
        'auditRemark': '',
        'status': 1,
        'statusText': '正常',
        'tags': ['中文服务'],
        'images': const [],
        'createdAt': '2026-07-25 10:00:00',
        'updatedAt': '2026-07-25 10:00:00',
      };
    }
    return {
      'id': 12,
      'shopId': 7,
      'shopName': '柏林茶馆',
      'content': '原来的体验记录',
      'scoreOverall': 4,
      'scoreTaste': 5,
      'scoreEnv': 4,
      'scoreService': 4,
      'cost': 18,
      'currency': 'EUR',
      'auditStatusText': '待审核',
      'auditRemark': '',
      'tags': ['中文服务'],
      'images': const [],
    };
  }

  Map<String, dynamic> get order => {
    'id': 10,
    'orderNo': 'OD-10',
    'dealTitle': '双人晚餐套餐',
    'shopName': '柏林茶馆',
    'quantity': 1,
    'unitPrice': 29.9,
    'amount': 29.9,
    'currency': 'EUR',
    'payStatus': 0,
    'payStatusText': '待支付',
    'status': 1,
    'coupons': const [],
  };

  Map<String, dynamic> get communityPost => {
    'id': 7,
    'userId': 9,
    'userName': '伦敦小王',
    'title': '伦敦周末市场指南',
    'content': '周六上午去选择最多。',
    'contentType': 1,
    'likeCount': 3,
    'commentCount': 1,
    'repostCount': 0,
    'repostedByCurrentUser': false,
    'auditStatus': 2,
    'auditStatusText': '审核驳回',
    'auditRemark': '请补充具体地址',
    'status': 1,
    'images': const [],
    'topics': ['伦敦生活'],
    'createdAt': '2026-07-16 10:00:00',
  };

  Map<String, dynamic> get approvedPost => {
    'id': 8,
    'userId': 9,
    'userName': '伦敦小王',
    'title': '柏林早午餐清单',
    'content': 'Mitte 几家稳定的中文友好店。',
    'contentType': 1,
    'likeCount': 5,
    'commentCount': 2,
    'repostCount': 0,
    'repostedByCurrentUser': false,
    'auditStatus': 1,
    'auditStatusText': '审核通过',
    'auditRemark': '',
    'status': 1,
    'images': const [],
    'topics': ['柏林生活'],
    'createdAt': '2026-07-18 10:00:00',
  };

  Map<String, dynamic> get coupon => {
    'id': 21,
    'orderId': 10,
    'code': 'CP-DEMO',
    'status': 1,
    'statusText': '待使用',
    'dealTitle': '双人晚餐套餐',
    'shopName': '柏林茶馆',
    'expireAt': '2026-12-31',
  };

  Map<String, dynamic> get reservation => {
    'id': 11,
    'reservationNo': 'RS-11',
    'shop': {
      'id': 2,
      'name': '柏林茶馆',
      'coverImage': '',
      'address': 'Berlin Mitte',
    },
    'reserveTime': '2026-07-20T18:00:00',
    'peopleCount': 2,
    'contactName': 'Li',
    'contactPhone': '+447700900000',
    'remark': '',
    'statusText': '已确认',
    'confirmModeText': '自动确认',
    'rescheduleCount': 0,
    'canCancel': true,
    'canReschedule': true,
    'timeline': const [],
  };

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
  testWidgets('user collection retries an initial load failure', (
    tester,
  ) async {
    final api = CollectionApi(failFirstReviews: true);
    await tester.pumpWidget(
      MaterialApp(
        home: UserCollectionScreen(
          repository: UserRepository(api),
          collection: UserCollection.reviews,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('user-collection-retry')));
    await tester.pumpAndSettle();

    expect(api.reviewRequests, 2);
    expect(find.text('柏林茶馆'), findsOneWidget);
  });

  testWidgets('user collection guards duplicate retries', (tester) async {
    final gate = Completer<void>();
    final api = CollectionApi(failFirstReviews: true)..reviewRetryGate = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: UserCollectionScreen(
          repository: UserRepository(api),
          collection: UserCollection.reviews,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('user-collection-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(api.reviewRequests, 2);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.reviewRequests, 2);
    expect(find.text('柏林茶馆'), findsOneWidget);
  });

  testWidgets('owned review collection loads later pages', (tester) async {
    final api = CollectionApi(paginatedReviews: true);
    await tester.pumpWidget(
      MaterialApp(
        home: UserCollectionScreen(
          repository: UserRepository(api),
          collection: UserCollection.reviews,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('柏林茶馆'), findsOneWidget);
    expect(find.byKey(const Key('user-collection-load-more')), findsOneWidget);
    await tester.tap(find.byKey(const Key('user-collection-load-more')));
    await tester.pumpAndSettle();

    expect(api.requestedReviewPages, [1, 2]);
    expect(find.text('巴黎面馆'), findsOneWidget);
    expect(find.byKey(const Key('user-collection-load-more')), findsNothing);
  });

  testWidgets('owned review collection opens the review detail', (
    tester,
  ) async {
    final api = CollectionApi();
    await tester.pumpWidget(
      MaterialApp(
        home: UserCollectionScreen(
          repository: UserRepository(api),
          collection: UserCollection.reviews,
          reviewRepository: ReviewRepository(api),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('原来的体验记录'), findsOneWidget);
    await tester.tap(find.text('柏林茶馆'));
    await tester.pumpAndSettle();

    expect(find.text('我的点评详情'), findsOneWidget);
    expect(find.text('编辑'), findsOneWidget);
  });

  testWidgets('order collection opens filtered orders list', (tester) async {
    final api = CollectionApi();
    await tester.pumpWidget(
      MaterialApp(
        home: UserCollectionScreen(
          repository: UserRepository(api),
          collection: UserCollection.orders,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('我的订单'), findsOneWidget);
    expect(find.byKey(const Key('order-tab-all')), findsOneWidget);
    expect(find.byKey(const Key('order-card-10')), findsOneWidget);
    await tester.tap(find.byKey(const Key('order-card-10')));
    await tester.pumpAndSettle();

    expect(find.text('订单详情'), findsOneWidget);
    expect(find.text('双人晚餐套餐'), findsOneWidget);
  });

  testWidgets('coupon collection opens coupon list with status filters', (
    tester,
  ) async {
    final api = CollectionApi();
    await tester.pumpWidget(
      MaterialApp(
        home: UserCollectionScreen(
          repository: UserRepository(api),
          collection: UserCollection.coupons,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('我的券'), findsOneWidget);
    expect(find.byKey(const Key('coupon-tab-all')), findsOneWidget);
    expect(find.byKey(const Key('coupon-card-CP-DEMO')), findsOneWidget);
    await tester.tap(find.byKey(const Key('coupon-card-CP-DEMO')));
    await tester.pumpAndSettle();

    expect(find.text('券详情'), findsOneWidget);
    expect(find.byKey(const Key('coupon-detail-code')), findsOneWidget);
  });

  testWidgets('reservation collection opens filtered reservations list', (
    tester,
  ) async {
    final api = CollectionApi();
    await tester.pumpWidget(
      MaterialApp(
        home: UserCollectionScreen(
          repository: UserRepository(api),
          collection: UserCollection.reservations,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('我的预订'), findsOneWidget);
    expect(find.byKey(const Key('reservation-tab-all')), findsOneWidget);
    expect(find.byKey(const Key('reservation-card-11')), findsOneWidget);
    await tester.tap(find.byKey(const Key('reservation-card-11')));
    await tester.pumpAndSettle();

    expect(find.text('预订详情'), findsOneWidget);
    expect(find.text('Berlin Mitte'), findsOneWidget);
  });

  testWidgets('owned post collection routes by audit status', (tester) async {
    final api = CollectionApi();
    await tester.pumpWidget(
      MaterialApp(
        home: UserCollectionScreen(
          repository: UserRepository(api),
          collection: UserCollection.posts,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('伦敦周末市场指南'));
    await tester.pumpAndSettle();
    expect(find.text('编辑帖子'), findsOneWidget);
    expect(find.textContaining('审核备注：请补充具体地址'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('柏林早午餐清单'));
    await tester.pumpAndSettle();
    expect(find.text('帖子详情'), findsOneWidget);
    expect(find.text('Mitte 几家稳定的中文友好店。'), findsOneWidget);
  });

  testWidgets('favorites collection shows shop and post titles', (
    tester,
  ) async {
    final api = CollectionApi();
    await tester.pumpWidget(
      MaterialApp(
        home: UserCollectionScreen(
          repository: UserRepository(api),
          collection: UserCollection.favorites,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('柏林茶馆'), findsOneWidget);
    expect(find.text('伦敦周末市场指南'), findsOneWidget);
    expect(find.textContaining('门店'), findsOneWidget);
    expect(find.textContaining('帖子'), findsOneWidget);
    expect(find.textContaining('2026/7/25 18:00'), findsOneWidget);
    expect(find.textContaining('2026/7/25 18:10'), findsOneWidget);
    expect(find.textContaining('2026-07-25'), findsNothing);
  });

  testWidgets('user collection localizes raw backend statuses in English', (
    tester,
  ) async {
    final api = CollectionApi();
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: UserCollectionScreen(
          repository: UserRepository(api),
          collection: UserCollection.reviews,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My reviews'), findsOneWidget);
    expect(find.textContaining('Pending review'), findsOneWidget);
  });

  testWidgets('user collection localizes post audit remark in English', (
    tester,
  ) async {
    final api = CollectionApi();
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: UserCollectionScreen(
          repository: UserRepository(api),
          collection: UserCollection.posts,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My posts'), findsOneWidget);
    expect(find.textContaining('Rejected'), findsOneWidget);
    expect(find.textContaining('Audit note: 请补充具体地址'), findsOneWidget);
  });

  testWidgets('user collection localizes load errors in English', (
    tester,
  ) async {
    final api = CollectionApi()..reviewError = const ApiException('用户登录状态不存在');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: UserCollectionScreen(
          repository: UserRepository(api),
          collection: UserCollection.reviews,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not load: Your sign-in session is no longer available. Please sign in again.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('用户登录状态不存在'), findsNothing);
  });

  testWidgets('user collection localizes load more errors in English', (
    tester,
  ) async {
    final api = CollectionApi(paginatedReviews: true)
      ..loadMoreReviewError = const ApiException('用户登录状态不存在');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: UserCollectionScreen(
          repository: UserRepository(api),
          collection: UserCollection.reviews,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('user-collection-load-more')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not load more: Your sign-in session is no longer available. Please sign in again.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('用户登录状态不存在'), findsNothing);
  });
}
