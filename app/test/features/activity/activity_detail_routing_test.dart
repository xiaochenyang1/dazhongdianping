import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/activity/activity_detail_screen.dart';
import 'package:dazhongdianping_app/features/activity/activity_repository.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/shop_detail_screen.dart';
import 'package:dazhongdianping_app/features/community/post_detail_screen.dart';
import 'package:dazhongdianping_app/features/rank/rank_detail_screen.dart';
import 'package:dazhongdianping_app/features/topic/topic_detail_screen.dart';
import 'package:dazhongdianping_app/features/trade/deal_detail_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ActivityRoutingApi implements JsonApi {
  ActivityRoutingApi(this.items);

  final List<Map<String, dynamic>> items;
  int dealRequests = 0;
  int topicDetailRequests = 0;
  int topicPostRequests = 0;
  final List<String> requestedPaths = <String>[];

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    requestedPaths.add(path);
    if (path == '/api/c/v1/activities/9001') {
      return {
        'id': 9001,
        'name': '暑期活动',
        'cityName': '上海',
        'channelText': '活动页',
        'typeText': '专题',
        'cover': '',
        'startAt': '2026-07-01',
        'endAt': '2026-08-31',
        'items': items,
      };
    }
    if (path == '/api/c/v1/shops/21') {
      return {
        'id': 21,
        'name': 'Activity Shop',
        'categoryName': 'Restaurant',
        'score': 4.8,
        'currency': 'EUR',
        'pricePerCapita': 35,
        'address': '21 Activity Street',
        'phone': '',
        'businessHours': '',
        'summary': '',
        'tags': const <String>[],
      };
    }
    if (path == '/api/c/v1/posts/31') {
      return {
        'id': 31,
        'userId': 7,
        'userName': 'Activity Author',
        'title': 'Activity Post',
        'content': 'Post opened from activity',
        'contentType': 1,
        'likeCount': 0,
        'commentCount': 0,
        'repostCount': 0,
        'repostedByCurrentUser': false,
        'auditStatus': 1,
        'auditStatusText': 'Approved',
        'auditRemark': '',
        'images': const <String>[],
        'topics': const <String>[],
        'createdAt': '2026-07-27 12:00:00',
      };
    }
    if (path == '/api/c/v1/posts/31/comments') {
      return {'list': const [], 'total': 0, 'page': 1, 'pageSize': 50};
    }
    if (path == '/api/c/v1/ranks/41') {
      return {
        'id': 41,
        'name': 'Activity Rank',
        'typeText': 'Best restaurants',
        'cityName': 'Paris',
        'categoryName': 'Restaurant',
        'period': '2026-07',
        'updatedAt': '2026-07-27 12:00:00',
        'items': const [],
      };
    }
    if (path == '/api/c/v1/shops/21/similar' ||
        path == '/api/c/v1/shops/21/reviews' ||
        path == '/api/c/v1/favorites') {
      return {'list': const []};
    }
    if (path == '/api/c/v1/deals/42') {
      dealRequests++;
      return {
        'id': 42,
        'shopId': 2,
        'shopName': 'EU Shop',
        'title': 'Activity Dinner Set',
        'coverImage': '',
        'price': 29.9,
        'originalPrice': 39.9,
        'currency': 'EUR',
        'stock': 8,
        'soldCount': 12,
        'rules': 'Advance booking required',
        'validStart': '2026-07-01',
        'validEnd': '2026-12-31',
        'items': [
          {
            'id': 421,
            'dealId': 42,
            'name': 'Dinner for two',
            'quantity': 1,
            'price': 29.9,
            'sort': 1,
          },
        ],
      };
    }
    if (path == '/api/c/v1/topics/51') {
      topicDetailRequests++;
      return {
        'id': 51,
        'region': 'EU',
        'name': '伦敦咖啡',
        'postCount': 0,
        'followerCount': 8,
        'recommended': true,
        'pinnedSort': 0,
        'followedByCurrentUser': false,
        'hotScore': 20,
        'postCount7d': 0,
        'likeCount7d': 0,
        'commentCount7d': 0,
        'calculatedAt': '2026-07-27 12:00:00',
      };
    }
    if (path == '/api/c/v1/topics/51/posts') {
      topicPostRequests++;
      return {'list': const [], 'total': 0, 'page': 1, 'pageSize': 30};
    }
    throw StateError('unexpected GET $path');
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    throw StateError('unexpected POST $path');
  }
}

Map<String, dynamic> activityItem({
  required int id,
  required int targetType,
  required int targetId,
  required String title,
  String linkUrl = '',
}) => {
  'id': id,
  'targetType': targetType,
  'targetTypeText': switch (targetType) {
    1 => '店铺',
    2 => '团购',
    3 => '帖子',
    4 => '榜单',
    5 => '话题',
    6 => '外链',
    _ => '未知',
  },
  'targetId': targetId,
  'targetName': title,
  'title': title,
  'subtitle': '',
  'linkUrl': linkUrl,
};

void main() {
  testWidgets('activity shop item opens the matching shop detail', (
    tester,
  ) async {
    final api = ActivityRoutingApi([
      activityItem(id: 1, targetType: 1, targetId: 21, title: '活动店铺'),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityDetailScreen(
          repository: ActivityRepository(api),
          activityId: 9001,
          browseRepository: ApiBrowseRepository(api),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('activity-item-1')));
    await tester.pumpAndSettle();

    expect(find.byType(ShopDetailScreen), findsOneWidget);
    expect(find.text('Activity Shop'), findsOneWidget);
    expect(api.requestedPaths, contains('/api/c/v1/shops/21'));
  });

  testWidgets('activity deal item opens the matching deal detail', (
    tester,
  ) async {
    final api = ActivityRoutingApi([
      activityItem(id: 2, targetType: 2, targetId: 42, title: '活动双人餐'),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityDetailScreen(
          repository: ActivityRepository(api),
          activityId: 9001,
          tradeRepository: TradeRepository(api),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('activity-item-2')));
    await tester.pumpAndSettle();

    expect(find.byType(DealDetailScreen), findsOneWidget);
    expect(find.text('Activity Dinner Set'), findsOneWidget);
    expect(find.text('Advance booking required'), findsOneWidget);
    expect(api.dealRequests, 1);
  });

  testWidgets('activity post item opens the matching post detail', (
    tester,
  ) async {
    final api = ActivityRoutingApi([
      activityItem(id: 3, targetType: 3, targetId: 31, title: '活动帖子'),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityDetailScreen(
          repository: ActivityRepository(api),
          activityId: 9001,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('activity-item-3')));
    await tester.pumpAndSettle();

    expect(find.byType(PostDetailScreen), findsOneWidget);
    expect(find.text('Activity Post'), findsOneWidget);
    expect(api.requestedPaths, contains('/api/c/v1/posts/31'));
  });

  testWidgets('activity rank item opens the matching rank detail', (
    tester,
  ) async {
    final api = ActivityRoutingApi([
      activityItem(id: 4, targetType: 4, targetId: 41, title: '活动榜单'),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityDetailScreen(
          repository: ActivityRepository(api),
          activityId: 9001,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('activity-item-4')));
    await tester.pumpAndSettle();

    expect(find.byType(RankDetailScreen), findsOneWidget);
    expect(find.text('Activity Rank'), findsOneWidget);
    expect(api.requestedPaths, contains('/api/c/v1/ranks/41'));
  });

  testWidgets('activity topic item opens the matching topic detail', (
    tester,
  ) async {
    final api = ActivityRoutingApi([
      activityItem(id: 5, targetType: 5, targetId: 51, title: '伦敦咖啡'),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityDetailScreen(
          repository: ActivityRepository(api),
          activityId: 9001,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('activity-item-5')));
    await tester.pumpAndSettle();

    expect(find.byType(TopicDetailScreen), findsOneWidget);
    expect(find.text('#伦敦咖啡'), findsOneWidget);
    expect(api.topicDetailRequests, 1);
    expect(api.topicPostRequests, 1);
  });

  testWidgets('activity external item launches a safe URL once', (
    tester,
  ) async {
    final gate = Completer<bool>();
    final opened = <Uri>[];
    final api = ActivityRoutingApi([
      activityItem(
        id: 6,
        targetType: 6,
        targetId: 0,
        title: '活动规则',
        linkUrl: 'https://promo.example.com/rules',
      ),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityDetailScreen(
          repository: ActivityRepository(api),
          activityId: 9001,
          externalUrlLauncher: (uri) {
            opened.add(uri);
            return gate.future;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final item = find.byKey(const Key('activity-item-6'));
    await tester.tap(item);
    await tester.tap(item, warnIfMissed: false);
    await tester.pump();

    expect(opened, [Uri.parse('https://promo.example.com/rules')]);
    gate.complete(true);
    await tester.pumpAndSettle();
    expect(find.byType(ActivityDetailScreen), findsOneWidget);
  });

  testWidgets('activity disables unsafe or unavailable targets', (
    tester,
  ) async {
    final api = ActivityRoutingApi([
      activityItem(id: 20, targetType: 2, targetId: 42, title: '缺少团购仓储'),
      activityItem(
        id: 60,
        targetType: 6,
        targetId: 0,
        title: '不安全外链',
        linkUrl: 'javascript:alert(1)',
      ),
      activityItem(id: 90, targetType: 9, targetId: 1, title: '未知资源'),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityDetailScreen(
          repository: ActivityRepository(api),
          activityId: 9001,
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final id in [20, 60, 90]) {
      final tile = tester.widget<ListTile>(
        find.descendant(
          of: find.byKey(Key('activity-item-$id')),
          matching: find.byType(ListTile),
        ),
      );
      expect(tile.onTap, isNull);
      expect(tile.trailing, isNull);
    }
  });
}
