import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/user/daily_check_in_screen.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class CheckInFakeApi implements JsonApi {
  Object? loadError;
  Object? submitError;
  Completer<void>? loadGate;
  Completer<void>? submitGate;
  int loadRequests = 0;
  int submitRequests = 0;
  bool checkedIn = false;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    expect(path, '/api/c/v1/user/check-in/status');
    loadRequests++;
    await loadGate?.future;
    if (loadError != null) {
      final error = loadError!;
      loadError = null;
      throw error;
    }
    return status();
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    expect(path, '/api/c/v1/user/check-in');
    submitRequests++;
    await submitGate?.future;
    if (submitError != null) throw submitError!;
    checkedIn = true;
    return status();
  }

  Map<String, dynamic> status() => {
    'checkedInToday': checkedIn,
    'streakDays': checkedIn ? 4 : 3,
    'totalCount': checkedIn ? 13 : 12,
    'todayGrowthReward': 2,
    'todayPointsReward': 1,
    'lastCheckInAt': checkedIn ? '2026-08-04 09:00:00' : '2026-08-03 09:00:00',
  };
}

Widget localizedApp({
  required Widget home,
  Locale locale = const Locale('zh', 'CN'),
}) => MaterialApp(
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

void main() {
  testWidgets('daily check-in credits the reward and updates the status', (
    tester,
  ) async {
    final api = CheckInFakeApi();
    UserCheckInStatus? callbackStatus;
    await tester.pumpWidget(
      localizedApp(
        home: DailyCheckInScreen(
          repository: UserRepository(api),
          onCheckedIn: (status) => callbackStatus = status,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('连续签到 3 天 · 累计 12 次'), findsOneWidget);
    expect(find.text('今日可得成长值 +2 · 积分 +1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('check-in-submit')));
    await tester.pumpAndSettle();

    expect(api.submitRequests, 1);
    expect(callbackStatus?.checkedInToday, isTrue);
    expect(find.text('连续签到 4 天 · 累计 13 次'), findsOneWidget);
    expect(find.text('今日已签到'), findsOneWidget);
    expect(find.text('签到成功'), findsOneWidget);
  });

  testWidgets('daily check-in retries an initial status failure', (
    tester,
  ) async {
    final api = CheckInFakeApi()..loadError = StateError('offline');
    await tester.pumpWidget(
      localizedApp(home: DailyCheckInScreen(repository: UserRepository(api))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('签到状态加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('check-in-retry')));
    await tester.pumpAndSettle();
    expect(api.loadRequests, 2);
    expect(find.text('立即签到'), findsOneWidget);
  });

  testWidgets('daily check-in guards duplicate submissions', (tester) async {
    final gate = Completer<void>();
    final api = CheckInFakeApi()..submitGate = gate;
    await tester.pumpWidget(
      localizedApp(home: DailyCheckInScreen(repository: UserRepository(api))),
    );
    await tester.pumpAndSettle();

    final submit = find.byKey(const Key('check-in-submit'));
    final action = tester.widget<FilledButton>(submit).onPressed!;
    action();
    action();
    await tester.pump();
    expect(api.submitRequests, 1);
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.submitRequests, 1);
    expect(find.text('今日已签到'), findsOneWidget);
  });

  testWidgets('daily check-in localizes duplicate errors in English', (
    tester,
  ) async {
    final api = CheckInFakeApi()..submitError = const ApiException('今天已经签过到了');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: DailyCheckInScreen(repository: UserRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('check-in-submit')));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not check in: You already checked in today.'),
      findsOneWidget,
    );
    expect(find.textContaining('今天已经签过到了'), findsNothing);
  });
}
