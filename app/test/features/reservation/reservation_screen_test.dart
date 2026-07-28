import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class ReservationScreenApi implements JsonApi {
  ReservationScreenApi({this.failFirst = false});

  final bool failFirst;
  int slotRequests = 0;
  Completer<void>? retryGate;
  Completer<void>? createGate;
  int createRequests = 0;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    slotRequests++;
    if (failFirst && slotRequests == 1) {
      throw StateError('network unavailable');
    }
    if (slotRequests > 1) await retryGate?.future;
    return {
      'date': '2026-07-16',
      'list': [
        {
          'slotId': 3,
          'startTime': '18:00',
          'endTime': '20:00',
          'remainingCount': 4,
          'available': true,
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    createRequests++;
    await createGate?.future;
    return {'id': 11, 'reservationNo': 'R11', 'statusText': '待确认'};
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

  testWidgets('reservation screen switches English chrome', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: ReservationScreen(
          repository: ReservationRepository(ReservationScreenApi()),
          shopId: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Book online'), findsOneWidget);
    expect(find.text('Submit reservation'), findsOneWidget);
  });


  testWidgets('reservation screen retries an initial slot failure', (
    tester,
  ) async {
    final api = ReservationScreenApi(failFirst: true);
    await tester.pumpWidget(
      localizedApp(
        home: ReservationScreen(
          repository: ReservationRepository(api),
          shopId: 2,
          initialDate: DateTime(2026, 7, 16),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('时段加载失败'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reservation-slots-retry')));
    await tester.pumpAndSettle();
    expect(api.slotRequests, 2);
    expect(find.textContaining('18:00'), findsOneWidget);
  });

  testWidgets('reservation screen guards duplicate slot retries', (
    tester,
  ) async {
    final gate = Completer<void>();
    final api = ReservationScreenApi(failFirst: true)..retryGate = gate;
    await tester.pumpWidget(
      localizedApp(
        home: ReservationScreen(
          repository: ReservationRepository(api),
          shopId: 2,
          initialDate: DateTime(2026, 7, 16),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('reservation-slots-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(api.slotRequests, 2);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.slotRequests, 2);
    expect(find.textContaining('18:00'), findsOneWidget);
  });

  testWidgets('reservation screen renders available slots', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        home: ReservationScreen(
          repository: ReservationRepository(ReservationScreenApi()),
          shopId: 2,
          initialDate: DateTime(2026, 7, 16),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('18:00'), findsOneWidget);
    expect(find.textContaining('剩余 4'), findsOneWidget);
  });

  testWidgets('reservation screen guards duplicate submissions', (
    tester,
  ) async {
    final gate = Completer<void>();
    final api = ReservationScreenApi()..createGate = gate;
    await tester.pumpWidget(
      localizedApp(
        home: ReservationScreen(
          repository: ReservationRepository(api),
          shopId: 2,
          initialDate: DateTime(2026, 7, 16),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('18:00'));
    final submit = find.byKey(const Key('reservation-submit'));
    await tester.tap(submit);
    await tester.tap(submit, warnIfMissed: false);
    await tester.pump();
    expect(api.createRequests, 1);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.createRequests, 1);
    expect(find.textContaining('预订 R11 已创建'), findsOneWidget);
  });
}
