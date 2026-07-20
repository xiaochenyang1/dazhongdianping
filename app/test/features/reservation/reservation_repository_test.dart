import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class ReservationFakeApi implements JsonApi {
  String? path;
  Object? body;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    this.path = path;
    if (path == '/api/c/v1/reservations/11') {
      return {
        'id': 11,
        'reservationNo': 'R11',
        'shop': {
          'id': 2,
          'name': 'EU Shop',
          'coverImage': '',
          'address': 'Berlin Mitte',
        },
        'slotId': 3,
        'reserveTime': '2026-07-16T18:00:00',
        'peopleCount': 2,
        'contactName': 'Li',
        'contactPhone': '+447700900000',
        'remark': 'Window',
        'status': 1,
        'statusText': '已确认',
        'confirmMode': 1,
        'confirmModeText': '自动确认',
        'rescheduleCount': 0,
        'canCancel': true,
        'canReschedule': true,
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
    }
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
    this.path = path;
    this.body = body;
    return {
      'id': 11,
      'reservationNo': 'R11',
      'shop': {
        'id': 2,
        'name': 'EU Shop',
        'coverImage': '',
        'address': 'Berlin Mitte',
      },
      'slotId': 3,
      'reserveTime': '2026-07-16T18:00:00',
      'peopleCount': 2,
      'contactName': 'Li',
      'contactPhone': '+447700900000',
      'remark': 'Window',
      'status': path.endsWith('/cancel') ? 3 : 1,
      'statusText': path.endsWith('/cancel') ? '用户取消' : '已确认',
      'confirmMode': 1,
      'confirmModeText': '自动确认',
      'rescheduleCount': path.endsWith('/reschedule') ? 1 : 0,
      'canCancel': !path.endsWith('/cancel'),
      'canReschedule': !path.endsWith('/cancel'),
      'timeline': const [],
    };
  }
}

void main() {
  test('reservation repository loads slots and creates reservation', () async {
    final api = ReservationFakeApi();
    final repository = ReservationRepository(api);
    final slots = await repository.loadSlots(
      shopId: 2,
      date: '2026-07-16',
      peopleCount: 2,
    );
    expect(api.path, '/api/c/v1/shops/2/reservation-slots');
    expect(slots.single.startTime, '18:00');

    final reservation = await repository.create(
      shopId: 2,
      slotId: 3,
      peopleCount: 2,
      contactName: 'Li',
      contactPhone: '+447700900000',
      remark: 'Window',
    );
    expect(api.path, '/api/c/v1/reservations');
    expect((api.body as Map)['slotId'], 3);
    expect(reservation.reservationNo, 'R11');
  });

  test(
    'reservation repository loads detail, cancels and reschedules',
    () async {
      final api = ReservationFakeApi();
      final repository = ReservationRepository(api);

      final detail = await repository.loadReservation(11);
      expect(api.path, '/api/c/v1/reservations/11');
      expect(detail.shopName, 'EU Shop');
      expect(detail.timeline.single.actionText, '创建预订');

      final cancelled = await repository.cancelReservation(11);
      expect(api.path, '/api/c/v1/reservations/11/cancel');
      expect(cancelled.statusText, '用户取消');

      final rescheduled = await repository.rescheduleReservation(
        11,
        slotId: 4,
        reserveTime: '2026-07-20 19:00:00',
        reason: '用户在线改期',
      );
      expect(api.path, '/api/c/v1/reservations/11/reschedule');
      expect(api.body, {
        'slotId': 4,
        'reserveTime': '2026-07-20 19:00:00',
        'reason': '用户在线改期',
      });
      expect(rescheduled.rescheduleCount, 1);
    },
  );
}
