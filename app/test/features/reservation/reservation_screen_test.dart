import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ReservationScreenApi implements JsonApi {
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async => {
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

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async => {
    'id': 11,
    'reservationNo': 'R11',
    'statusText': '待确认',
  };
}

void main() {
  testWidgets('reservation screen renders available slots', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
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
}
