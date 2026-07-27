import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/reservation/reservations_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ReservationsApi implements JsonApi {
  ReservationsApi({this.paginated = false, this.failFirst = false});

  final bool paginated;
  final bool failFirst;
  int reservationListRequests = 0;
  Map<String, Object?>? lastQuery;
  final List<String> paths = <String>[];
  final List<int> requestedPages = <int>[];
  Completer<void>? retryGate;
  Completer<void>? detailGate;
  int reservationDetailRequests = 0;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    paths.add(path);
    lastQuery = query;
    if (path == '/api/c/v1/reservations') {
      reservationListRequests++;
      if (failFirst && reservationListRequests == 1) {
        throw StateError('network unavailable');
      }
      if (reservationListRequests > 1) await retryGate?.future;
      final page = query?['page'] as int? ?? 1;
      requestedPages.add(page);
      return {
        'list': [
          {
            'id': paginated ? 10 + page : 11,
            'reservationNo': paginated ? 'RS-PAGE-$page' : 'RS-11',
            'shop': {
              'id': 2,
              'name': page == 1 ? '柏林茶馆' : '更早的预订',
              'coverImage': '',
              'address': 'Berlin Mitte',
            },
            'reserveTime': '2026-07-20T18:00:00',
            'peopleCount': 2,
            'status': 1,
            'statusText': '已确认',
          },
        ],
        'total': paginated ? 2 : 1,
      };
    }
    if (path == '/api/c/v1/reservations/11') {
      reservationDetailRequests++;
      await detailGate?.future;
      return {
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
        'remark': '',
        'status': 1,
        'statusText': '已确认',
        'confirmMode': 1,
        'confirmModeText': '自动确认',
        'rescheduleCount': 0,
        'canCancel': true,
        'canReschedule': true,
        'timeline': const [],
      };
    }
    return const {};
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      const {};
}

void main() {
  testWidgets('reservations list retries an initial load failure', (
    tester,
  ) async {
    final api = ReservationsApi(failFirst: true);
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationsListScreen(repository: ReservationRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('预订加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('reservations-retry')));
    await tester.pumpAndSettle();

    expect(api.reservationListRequests, 2);
    expect(find.byKey(const Key('reservation-card-11')), findsOneWidget);
  });

  testWidgets('reservations list guards duplicate retries', (tester) async {
    final gate = Completer<void>();
    final api = ReservationsApi(failFirst: true)..retryGate = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationsListScreen(repository: ReservationRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('reservations-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(api.reservationListRequests, 2);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reservation-card-11')), findsOneWidget);
  });

  testWidgets('reservations list loads later filtered pages', (tester) async {
    final api = ReservationsApi(paginated: true);
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationsListScreen(
          repository: ReservationRepository(api),
          initialStatus: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reservation-card-11')), findsOneWidget);
    expect(find.byKey(const Key('reservations-load-more')), findsOneWidget);
    await tester.tap(find.byKey(const Key('reservations-load-more')));
    await tester.pumpAndSettle();

    expect(api.requestedPages, [1, 2]);
    expect(api.lastQuery?['status'], 1);
    expect(find.byKey(const Key('reservation-card-12')), findsOneWidget);
    expect(find.byKey(const Key('reservations-load-more')), findsNothing);
  });

  testWidgets('reservations list filters by status and opens detail', (
    tester,
  ) async {
    final api = ReservationsApi();
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationsListScreen(
          repository: ReservationRepository(api),
          initialStatus: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.lastQuery?['status'], 1);
    expect(find.byKey(const Key('reservation-card-11')), findsOneWidget);

    await tester.tap(find.byKey(const Key('reservation-tab-0')));
    await tester.pumpAndSettle();
    expect(api.lastQuery?['status'], 0);

    await tester.tap(find.byKey(const Key('reservation-card-11')));
    await tester.pumpAndSettle();
    expect(find.text('预订详情'), findsOneWidget);
    expect(api.paths, contains('/api/c/v1/reservations/11'));
  });

  testWidgets('reservations list guards duplicate detail navigation', (
    tester,
  ) async {
    final gate = Completer<void>();
    final api = ReservationsApi()..detailGate = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: ReservationsListScreen(repository: ReservationRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const Key('reservation-card-11'));
    await tester.tap(card);
    await tester.tap(card, warnIfMissed: false);
    await tester.pump();

    expect(api.reservationDetailRequests, 1);

    gate.complete();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(api.reservationDetailRequests, 1);
    expect(api.reservationListRequests, 2);
  });
}
