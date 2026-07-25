import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/activity/activity_list_screen.dart';
import 'package:dazhongdianping_app/features/activity/activity_repository.dart';
import 'package:dazhongdianping_app/features/rank/rank_list_screen.dart';
import 'package:dazhongdianping_app/features/rank/rank_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class RankScreenApi implements JsonApi {
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (path == '/api/c/v1/ranks') {
      return {
        'value': [
          {
            'id': 30001,
            'name': '上海必吃榜',
            'typeText': '必吃榜',
            'cityName': '上海',
            'categoryName': '火锅',
            'period': '2026-07',
            'itemCount': 10,
            'topShopName': '渝里火锅徐汇店',
            'updatedAt': '2026-07-20 10:00:00',
          },
        ],
      };
    }
    if (path == '/api/c/v1/ranks/30001') {
      return {
        'id': 30001,
        'name': '上海必吃榜',
        'typeText': '必吃榜',
        'cityName': '上海',
        'categoryName': '火锅',
        'period': '2026-07',
        'updatedAt': '2026-07-20 10:00:00',
        'items': const [],
      };
    }
    return const {};
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      const {};
}

class ActivityScreenApi implements JsonApi {
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (path == '/api/c/v1/activities') {
      return {
        'value': [
          {
            'id': 9001,
            'name': '暑期火锅节',
            'cityName': '上海',
            'channelText': 'C端',
            'typeText': '专题',
            'cover': '',
            'startAt': '2026-07-01',
            'endAt': '2026-08-31',
            'itemCount': 3,
          },
        ],
      };
    }
    if (path == '/api/c/v1/activities/9001') {
      return {
        'id': 9001,
        'name': '暑期火锅节',
        'cityName': '上海',
        'channelText': 'C端',
        'typeText': '专题',
        'cover': '',
        'startAt': '2026-07-01',
        'endAt': '2026-08-31',
        'items': const [],
      };
    }
    return const {};
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      const {};
}

void main() {
  testWidgets('rank list opens detail', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RankListScreen(repository: RankRepository(RankScreenApi())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('上海必吃榜'), findsOneWidget);
    await tester.tap(find.text('上海必吃榜'));
    await tester.pumpAndSettle();
    expect(find.text('榜单详情'), findsOneWidget);
  });

  testWidgets('activity list opens detail', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityListScreen(
          repository: ActivityRepository(ActivityScreenApi()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('暑期火锅节'), findsOneWidget);
    await tester.tap(find.text('暑期火锅节'));
    await tester.pumpAndSettle();
    expect(find.text('活动详情'), findsOneWidget);
  });
}
