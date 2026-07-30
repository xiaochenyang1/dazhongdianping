import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/activity/activity_list_screen.dart';
import 'package:dazhongdianping_app/features/activity/activity_detail_screen.dart';
import 'package:dazhongdianping_app/features/activity/activity_repository.dart';
import 'package:dazhongdianping_app/features/rank/rank_list_screen.dart';
import 'package:dazhongdianping_app/features/rank/rank_detail_screen.dart';
import 'package:dazhongdianping_app/features/rank/rank_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

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
            'type': 1,
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
        'type': 1,
        'typeText': '必吃榜',
        'cityName': '上海',
        'categoryName': '火锅',
        'period': '2026-07',
        'updatedAt': '2026-07-20 10:00:00',
        'items': [
          {
            'position': 1,
            'rankScore': 94.7,
            'reason': '综合评分稳定',
            'shop': {
              'id': 10001,
              'name': '渝里火锅徐汇店',
              'score': 4.7,
              'currency': 'CNY',
              'pricePerCapita': 138,
              'cityName': '上海',
              'areaName': '徐汇',
              'merchantCertification': {
                'code': 'verified_merchant',
                'label': '认证商户',
              },
            },
          },
        ],
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
            'channel': 4,
            'channelText': '活动页',
            'type': 1,
            'typeText': '专题活动',
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
        'channel': 4,
        'channelText': '活动页',
        'type': 1,
        'typeText': '专题活动',
        'cover': '',
        'startAt': '2026-07-01',
        'endAt': '2026-08-31',
        'items': [
          {
            'id': 1,
            'targetType': 4,
            'targetTypeText': '榜单',
            'targetId': 30001,
            'targetName': '上海必吃榜',
            'title': '榜单入口',
            'subtitle': '',
            'linkUrl': '',
          },
        ],
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
      localizedApp(
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
      localizedApp(
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
      localizedApp(
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
      localizedApp(
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
      localizedApp(
        home: RankListScreen(repository: RankRepository(RankScreenApi())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('上海必吃榜'), findsOneWidget);
    await tester.tap(find.text('上海必吃榜'));
    await tester.pumpAndSettle();
    expect(find.text('榜单详情'), findsOneWidget);
  });

  testWidgets('rank and activity screens switch English chrome', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: RankListScreen(repository: RankRepository(RankScreenApi())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('City rankings'), findsOneWidget);
    expect(find.textContaining('10 places'), findsOneWidget);
    expect(find.textContaining('Top place:'), findsOneWidget);
    expect(find.textContaining('Must-eat ranking'), findsOneWidget);

    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: ActivityListScreen(
          repository: ActivityRepository(ActivityScreenApi()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Activities'), findsOneWidget);
    expect(find.textContaining('3 resources'), findsOneWidget);
    expect(find.textContaining('Themed campaign'), findsOneWidget);
    expect(find.textContaining('Activity page'), findsOneWidget);
  });

  testWidgets('rank and activity detail screens localize English metadata', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: RankDetailScreen(
          repository: RankRepository(RankScreenApi()),
          rankId: 30001,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Must-eat ranking'), findsOneWidget);
    expect(find.textContaining('Verified merchant'), findsOneWidget);

    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: ActivityDetailScreen(
          repository: ActivityRepository(ActivityScreenApi()),
          activityId: 9001,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Themed campaign'), findsOneWidget);
    expect(find.textContaining('Activity page'), findsOneWidget);
    expect(find.textContaining('ranking'), findsOneWidget);
  });

  testWidgets('rank list guards duplicate detail navigation', (tester) async {
    final gate = Completer<void>();
    final api = RankScreenApi()..detailGate = gate;
    await tester.pumpWidget(
      localizedApp(home: RankListScreen(repository: RankRepository(api))),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const Key('rank-card-30001'));
    await tester.tap(card);
    await tester.tap(card, warnIfMissed: false);
    await tester.pump();

    expect(api.detailLoadCount, 1);

    gate.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    expect(api.detailLoadCount, 1);
    expect(api.loadCount, 1);
  });

  testWidgets('rank list retries an initial load failure', (tester) async {
    final api = RankScreenApi()..failNextLoad = true;
    await tester.pumpWidget(
      localizedApp(home: RankListScreen(repository: RankRepository(api))),
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
      localizedApp(home: RankListScreen(repository: RankRepository(api))),
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
      localizedApp(home: RankListScreen(repository: RankRepository(api))),
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
      localizedApp(
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

  testWidgets('activity list guards duplicate detail navigation', (
    tester,
  ) async {
    final gate = Completer<void>();
    final api = ActivityScreenApi()..detailGate = gate;
    await tester.pumpWidget(
      localizedApp(
        home: ActivityListScreen(repository: ActivityRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const Key('activity-card-9001'));
    await tester.tap(card);
    await tester.tap(card, warnIfMissed: false);
    await tester.pump();

    expect(api.detailLoadCount, 1);

    gate.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    expect(api.detailLoadCount, 1);
    expect(api.loadCount, 1);
  });

  testWidgets('activity list retries an initial load failure', (tester) async {
    final api = ActivityScreenApi()..failNextLoad = true;
    await tester.pumpWidget(
      localizedApp(
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
      localizedApp(
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
      localizedApp(
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
