import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/activity/activity_list_screen.dart';
import 'package:dazhongdianping_app/features/activity/activity_detail_screen.dart';
import 'package:dazhongdianping_app/features/activity/activity_repository.dart';
import 'package:dazhongdianping_app/features/rank/rank_list_screen.dart';
import 'package:dazhongdianping_app/features/rank/rank_detail_screen.dart';
import 'package:dazhongdianping_app/features/rank/rank_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class RankScreenApi implements JsonApi {
  int loadCount = 0;
  bool failNextLoad = false;
  bool failNextDetail = false;
  int detailLoadCount = 0;
  Completer<void>? loadGate;
  Completer<void>? detailGate;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (path == '/api/c/v1/ranks') {
      loadCount += 1;
      await loadGate?.future;
      if (failNextLoad) {
        failNextLoad = false;
        throw const ApiException('rank network unavailable');
      }
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
      detailLoadCount += 1;
      if (failNextDetail) {
        failNextDetail = false;
        throw const ApiException('rank detail network unavailable');
      }
      await detailGate?.future;
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
  int loadCount = 0;
  bool failNextLoad = false;
  int detailLoadCount = 0;
  bool failNextDetail = false;
  Completer<void>? loadGate;
  Completer<void>? detailGate;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (path == '/api/c/v1/activities') {
      loadCount += 1;
      await loadGate?.future;
      if (failNextLoad) {
        failNextLoad = false;
        throw const ApiException('activity network unavailable');
      }
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
      detailLoadCount += 1;
      if (failNextDetail) {
        failNextDetail = false;
        throw const ApiException('activity detail network unavailable');
      }
      await detailGate?.future;
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
  testWidgets('activity detail retries an initial load failure', (
    tester,
  ) async {
    final api = ActivityScreenApi()..failNextDetail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityDetailScreen(
          repository: ActivityRepository(api),
          activityId: 9001,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('活动详情加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('activity-detail-retry')));
    await tester.pumpAndSettle();

    expect(api.detailLoadCount, 2);
    expect(find.text('暑期火锅节'), findsOneWidget);
  });

  testWidgets('activity detail guards duplicate retries', (tester) async {
    final gate = Completer<void>();
    final api = ActivityScreenApi()
      ..failNextDetail = true
      ..detailGate = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityDetailScreen(
          repository: ActivityRepository(api),
          activityId: 9001,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('activity-detail-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(api.detailLoadCount, 2);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.detailLoadCount, 2);
    expect(find.text('暑期火锅节'), findsOneWidget);
  });

  testWidgets('rank detail retries an initial load failure', (tester) async {
    final api = RankScreenApi()..failNextDetail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: RankDetailScreen(repository: RankRepository(api), rankId: 30001),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('榜单详情加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('rank-detail-retry')));
    await tester.pumpAndSettle();

    expect(api.detailLoadCount, 2);
    expect(find.text('上海必吃榜'), findsOneWidget);
  });

  testWidgets('rank detail guards duplicate retries', (tester) async {
    final gate = Completer<void>();
    final api = RankScreenApi()
      ..failNextDetail = true
      ..detailGate = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: RankDetailScreen(repository: RankRepository(api), rankId: 30001),
      ),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('rank-detail-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(api.detailLoadCount, 2);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.detailLoadCount, 2);
    expect(find.text('上海必吃榜'), findsOneWidget);
  });

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

  testWidgets('rank list guards duplicate detail navigation', (tester) async {
    final gate = Completer<void>();
    final api = RankScreenApi()..detailGate = gate;
    await tester.pumpWidget(
      MaterialApp(home: RankListScreen(repository: RankRepository(api))),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const Key('rank-card-30001'));
    await tester.tap(card);
    await tester.tap(card, warnIfMissed: false);
    await tester.pump();

    expect(api.detailLoadCount, 1);

    gate.complete();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(api.detailLoadCount, 1);
    expect(api.loadCount, 1);
  });

  testWidgets('rank list retries an initial load failure', (tester) async {
    final api = RankScreenApi()..failNextLoad = true;
    await tester.pumpWidget(
      MaterialApp(home: RankListScreen(repository: RankRepository(api))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('榜单加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('rank-list-retry')));
    await tester.pumpAndSettle();

    expect(api.loadCount, 2);
    expect(find.text('上海必吃榜'), findsOneWidget);
  });

  testWidgets('failed rank refresh preserves loaded ranks', (tester) async {
    final api = RankScreenApi();
    await tester.pumpWidget(
      MaterialApp(home: RankListScreen(repository: RankRepository(api))),
    );
    await tester.pumpAndSettle();
    api.failNextLoad = true;

    await tester.drag(find.byType(ListView), const Offset(0, 320));
    await tester.pumpAndSettle();

    expect(api.loadCount, 2);
    expect(find.text('上海必吃榜'), findsOneWidget);
    expect(find.textContaining('刷新榜单失败'), findsOneWidget);
    expect(find.textContaining('榜单加载失败'), findsNothing);
  });

  testWidgets('rank list guards duplicate retries', (tester) async {
    final gate = Completer<void>();
    final api = RankScreenApi()..failNextLoad = true;
    await tester.pumpWidget(
      MaterialApp(home: RankListScreen(repository: RankRepository(api))),
    );
    await tester.pumpAndSettle();
    api.loadGate = gate;

    final retry = find.byKey(const Key('rank-list-retry'));
    await tester.tap(retry);
    await tester.tap(retry);
    await tester.pump();

    expect(api.loadCount, 2);
    expect(find.text('处理中...'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.loadCount, 2);
    expect(find.text('上海必吃榜'), findsOneWidget);
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

  testWidgets('activity list retries an initial load failure', (tester) async {
    final api = ActivityScreenApi()..failNextLoad = true;
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityListScreen(repository: ActivityRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('活动加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('activity-list-retry')));
    await tester.pumpAndSettle();

    expect(api.loadCount, 2);
    expect(find.text('暑期火锅节'), findsOneWidget);
  });

  testWidgets('activity list guards duplicate retries', (tester) async {
    final gate = Completer<void>();
    final api = ActivityScreenApi()..failNextLoad = true;
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityListScreen(repository: ActivityRepository(api)),
      ),
    );
    await tester.pumpAndSettle();
    api.loadGate = gate;

    final retry = find.byKey(const Key('activity-list-retry'));
    await tester.tap(retry);
    await tester.tap(retry);
    await tester.pump();

    expect(api.loadCount, 2);
    expect(find.text('处理中...'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.loadCount, 2);
    expect(find.text('暑期火锅节'), findsOneWidget);
  });

  testWidgets('failed activity refresh preserves loaded activities', (
    tester,
  ) async {
    final api = ActivityScreenApi();
    await tester.pumpWidget(
      MaterialApp(
        home: ActivityListScreen(repository: ActivityRepository(api)),
      ),
    );
    await tester.pumpAndSettle();
    api.failNextLoad = true;

    await tester.drag(find.byType(ListView), const Offset(0, 320));
    await tester.pumpAndSettle();

    expect(api.loadCount, 2);
    expect(find.text('暑期火锅节'), findsOneWidget);
    expect(find.textContaining('刷新活动失败'), findsOneWidget);
    expect(find.textContaining('活动加载失败'), findsNothing);
  });
}
