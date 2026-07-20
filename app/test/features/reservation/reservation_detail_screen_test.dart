import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_detail_screen.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ReservationDetailApi implements JsonApi {
  String? path;
  Object? body;

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
      return {
        'list': [
          {
            'slotId': 4,
            'startTime': '19:00:00',
            'endTime': '21:00:00',
            'remainingCount': 3,
            'available': true,
            'confirmModeText': '自动确认',
            'closedReason': '',
          },
        ],
      };
    }
    return detail();
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    this.path = path;
    this.body = body;
    return detail(statusText: path.endsWith('/cancel') ? '用户取消' : '已确认');
  }
}

void main() {
  testWidgets('reservation detail cancels after confirmation', (tester) async {
    final api = ReservationDetailApi();
    await tester.pumpWidget(
      MaterialApp(
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
      MaterialApp(
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
}
