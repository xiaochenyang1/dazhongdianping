import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/user/user_collection_screen.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CollectionApi implements JsonApi {
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (path == '/api/c/v1/user/reviews') {
      return {
        'list': [
          {
            'id': 12,
            'shopId': 7,
            'shopName': '柏林茶馆',
            'content': '原来的体验记录',
            'scoreOverall': 4,
            'auditStatusText': '待审核',
          },
        ],
        'total': 1,
      };
    }
    if (path == '/api/c/v1/user/posts') {
      return {
        'list': [communityPost],
        'total': 1,
      };
    }
    if (path == '/api/c/v1/user/posts/7') return communityPost;
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
    if (path == '/api/c/v1/reservations') {
      return {
        'list': [reservation],
        'total': 1,
      };
    }
    if (path == '/api/c/v1/reservations/11') return reservation;
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
    'auditStatus': 2,
    'auditStatusText': '审核驳回',
    'auditRemark': '请补充具体地址',
    'status': 1,
    'images': const [],
    'topics': ['伦敦生活'],
    'createdAt': '2026-07-16 10:00:00',
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

void main() {
  testWidgets('owned review collection opens the review editor', (
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

    expect(find.text('编辑点评'), findsOneWidget);
    expect(find.byKey(const Key('review-content')), findsOneWidget);
  });

  testWidgets('order collection opens business order detail', (tester) async {
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

    await tester.tap(find.text('OD-10'));
    await tester.pumpAndSettle();

    expect(find.text('订单详情'), findsOneWidget);
    expect(find.text('双人晚餐套餐'), findsOneWidget);
  });

  testWidgets('coupon collection opens coupon detail', (tester) async {
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

    await tester.tap(find.text('CP-DEMO'));
    await tester.pumpAndSettle();

    expect(find.text('券详情'), findsOneWidget);
    expect(find.textContaining('由商户核销'), findsOneWidget);
  });

  testWidgets('reservation collection opens reservation detail', (
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

    await tester.tap(find.text('RS-11'));
    await tester.pumpAndSettle();

    expect(find.text('预订详情'), findsOneWidget);
    expect(find.text('Berlin Mitte'), findsOneWidget);
  });

  testWidgets('owned post collection opens the post editor', (tester) async {
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
    expect(find.text('请补充具体地址'), findsOneWidget);
  });
}
