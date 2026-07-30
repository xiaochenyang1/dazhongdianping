import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_detail_screen.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class ReservationDetailApi implements JsonApi {
  String? path;
  Object? body;
  bool failNextReschedule = false;
  Object? detailError;
  Object? slotError;
  Object? cancelError;
  Object? rescheduleError;
  int rescheduleRequests = 0;
  Completer<void>? slotGate;
  int slotRequests = 0;
  bool failFirstDetail = false;
  Completer<void>? detailGate;
  int detailRequests = 0;

  Map<String, dynamic> detail({String statusText = '已确认'}) => {
    'id': 11,
    'reservationNo': 'RS-11',
    'shop': {
      'id': 2,
      'name': '柏林茶馆',
      'coverImage': '',
      'address': 'Berlin Mitte',
    },
    'slotId': 3,
    'reserveTime': '2026-07-20T18:00:00',
    'peopleCount': 2,
    'contactName': 'Li',
    'contactPhone': '+447700900000',
    'remark': '靠窗',
    'status': statusText == '用户取消' ? 3 : 1,
    'statusText': statusText,
    'confirmMode': 1,
    'confirmModeText': '自动确认',
    'rescheduleCount': 0,
    'canCancel': statusText != '用户取消',
    'canReschedule': statusText != '用户取消',
    'timeline': [
      {
        'actionType': 1,
        'actionText': '创建预订',
        'operatorType': 1,
        'operatorText': '用户',
        'remark': '创建预订',
        'createdAt': '2026-07-10T10:00:00',
      },
    ],
  };

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    this.path = path;
    if (path.contains('reservation-slots')) {
      slotRequests += 1;
      await slotGate?.future;
      if (slotError != null) {
        throw slotError!;
      }
      return {
        'list': [
          {
            'slotId': 4,
            'startTime': '19:00:00',
            'endTime': '21:00:00',
            'remainingCount': 3,
            'available': true,
            'confirmMode': 1,
            'confirmModeText': '自动确认',
            'closedReason': '',
          },
        ],
      };
    }
    detailRequests += 1;
    await detailGate?.future;
    if (detailError != null) {
      throw detailError!;
    }
    if (failFirstDetail && detailRequests == 1) {
      throw StateError('reservation unavailable');
    }
    return detail();
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    this.path = path;
    this.body = body;
    if (path.endsWith('/cancel') && cancelError != null) {
      throw cancelError!;
    }
    if (path.endsWith('/reschedule')) rescheduleRequests++;
    if (path.endsWith('/reschedule') && rescheduleError != null) {
      throw rescheduleError!;
    }
    if (path.endsWith('/reschedule') && failNextReschedule) {
      failNextReschedule = false;
      throw StateError('reschedule unavailable');
    }
    return detail(statusText: path.endsWith('/cancel') ? '用户取消' : '已确认');
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
  testWidgets('reservation detail localizes reservation labels in English', (
    tester,
  ) async {
    final api = ReservationDetailApi();
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: ReservationDetailScreen(
          repository: ReservationRepository(api),
          reservationId: 11,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Confirmed'), findsOneWidget);
    expect(find.textContaining('Auto confirm'), findsOneWidget);
    expect(find.text('Created reservation'), findsOneWidget);
    expect(find.text('已确认'), findsNothing);
    expect(find.textContaining('自动确认'), findsNothing);
    expect(find.text('创建预订'), findsNothing);
  });

  testWidgets('reservation detail guards duplicate load retries', (
    tester,
  ) async {
    final gate = Completer<void>();
    final api = ReservationDetailApi()..failFirstDetail = true;
    await tester.pumpWidget(
      localizedApp(
        home: ReservationDetailScreen(
          repository: ReservationRepository(api),
          reservationId: 11,
        ),
      ),
    );
    await tester.pumpAndSettle();
    api.detailGate = gate;

    final retry = find.byKey(const Key('reservation-detail-retry'));
    await tester.tap(retry);
    await tester.tap(retry);
    await tester.pump();
    expect(api.detailRequests, 2);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.detailRequests, 2);
    expect(find.text('柏林茶馆'), findsOneWidget);
  });

  testWidgets('reservation detail localizes slot lookup failures in English', (
    tester,
  ) async {
    final api = ReservationDetailApi()
      ..slotError = const ApiException('预订时段不存在');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: ReservationDetailScreen(
          repository: ReservationRepository(api),
          reservationId: 11,
          initialRescheduleDate: DateTime(2026, 7, 21),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Find new slots'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not load time slots: This reservation slot could not be found.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('预订时段不存在'), findsNothing);
  });

  testWidgets('reservation detail localizes cancel failures in English', (
    tester,
  ) async {
    final api = ReservationDetailApi()
      ..cancelError = const ApiException('已超过允许取消时间');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: ReservationDetailScreen(
          repository: ReservationRepository(api),
          reservationId: 11,
          initialRescheduleDate: DateTime(2026, 7, 21),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancel reservation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm cancel'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not complete the action: The cancellation window has passed.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('已超过允许取消时间'), findsNothing);
  });

  testWidgets('reservation detail cancels after confirmation', (tester) async {
    final api = ReservationDetailApi();
    await tester.pumpWidget(
      localizedApp(
        home: ReservationDetailScreen(
          repository: ReservationRepository(api),
          reservationId: 11,
          initialRescheduleDate: DateTime(2026, 7, 21),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('柏林茶馆'), findsOneWidget);
    expect(find.text('创建预订'), findsOneWidget);
    await tester.tap(find.text('取消预订'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认取消'));
    await tester.pumpAndSettle();

    expect(api.path, '/api/c/v1/reservations/11/cancel');
    expect(find.text('用户取消'), findsOneWidget);
  });

  testWidgets('reservation detail queries a slot and reschedules', (
    tester,
  ) async {
    final api = ReservationDetailApi();
    await tester.pumpWidget(
      localizedApp(
        home: ReservationDetailScreen(
          repository: ReservationRepository(api),
          reservationId: 11,
          initialRescheduleDate: DateTime(2026, 7, 21),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('查询改期时段'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('19:00'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('确认改期'));
    await tester.tap(find.text('确认改期'));
    await tester.pumpAndSettle();

    expect(api.path, '/api/c/v1/reservations/11/reschedule');
    expect(api.body, {
      'slotId': 4,
      'reserveTime': '2026-07-21 19:00:00',
      'reason': '用户在线改期',
    });
  });

  testWidgets('reservation detail guards duplicate cancel dialogs', (
    tester,
  ) async {
    final api = ReservationDetailApi();
    await tester.pumpWidget(
      localizedApp(
        home: ReservationDetailScreen(
          repository: ReservationRepository(api),
          reservationId: 11,
          initialRescheduleDate: DateTime(2026, 7, 21),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cancel = find.byKey(const Key('reservation-cancel-button'));
    final cancelAction = tester.widget<OutlinedButton>(cancel).onPressed!;
    cancelAction();
    cancelAction();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('取消预订'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('先不取消'));
    await tester.pumpAndSettle();
    expect(api.path, '/api/c/v1/reservations/11');
  });

  testWidgets('reservation detail guards duplicate date pickers', (
    tester,
  ) async {
    final api = ReservationDetailApi();
    await tester.pumpWidget(
      localizedApp(
        home: ReservationDetailScreen(
          repository: ReservationRepository(api),
          reservationId: 11,
          initialRescheduleDate: DateTime.now().add(const Duration(days: 1)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pickDate = find.byKey(const Key('reservation-pick-date'));
    final pickDateAction = tester.widget<OutlinedButton>(pickDate).onPressed!;
    pickDateAction();
    pickDateAction();
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    Navigator.of(tester.element(find.byType(DatePickerDialog))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
  });

  testWidgets('failed reschedule preserves the selected slot for retry', (
    tester,
  ) async {
    final api = ReservationDetailApi()..failNextReschedule = true;
    await tester.pumpWidget(
      localizedApp(
        home: ReservationDetailScreen(
          repository: ReservationRepository(api),
          reservationId: 11,
          initialRescheduleDate: DateTime(2026, 7, 21),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('查询改期时段'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('19:00'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('确认改期'));
    await tester.tap(find.text('确认改期'));
    await tester.pumpAndSettle();

    expect(find.textContaining('操作失败'), findsOneWidget);
    expect(find.textContaining('19:00'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '确认改期'))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.text('确认改期'));
    await tester.pumpAndSettle();

    expect(api.rescheduleRequests, 2);
    expect(find.textContaining('19:00'), findsNothing);
  });

  testWidgets('reservation detail localizes reschedule failures in English', (
    tester,
  ) async {
    final api = ReservationDetailApi()
      ..rescheduleError = const ApiException('新时段余量不足');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: ReservationDetailScreen(
          repository: ReservationRepository(api),
          reservationId: 11,
          initialRescheduleDate: DateTime(2026, 7, 21),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Find new slots'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('19:00'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Confirm reschedule'));
    await tester.tap(find.text('Confirm reschedule'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not complete the action: The new time slot no longer has enough availability.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('新时段余量不足'), findsNothing);
  });

  testWidgets('reservation detail blocks duplicate slot requests', (
    tester,
  ) async {
    final gate = Completer<void>();
    final api = ReservationDetailApi()..slotGate = gate;
    await tester.pumpWidget(
      localizedApp(
        home: ReservationDetailScreen(
          repository: ReservationRepository(api),
          reservationId: 11,
          initialRescheduleDate: DateTime(2026, 7, 21),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reservation-find-slots')));
    await tester.tap(find.byKey(const Key('reservation-find-slots')));
    expect(api.slotRequests, 1);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.slotRequests, 1);
    expect(find.textContaining('19:00'), findsOneWidget);
  });
}
