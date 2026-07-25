import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/reservation/reservations_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ReservationsApi implements JsonApi {
  Map<String, Object?>? lastQuery;
  final List<String> paths = <String>[];

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    paths.add(path);
    lastQuery = query;
    if (path == '/api/c/v1/reservations') {
      return {
        'list': [
          {
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
            'status': 1,
            'statusText': '已确认',
          },
        ],
        'total': 1,
      };
    }
    if (path == '/api/c/v1/reservations/11') {
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
}
