import 'package:dazhongdianping_app/core/api_client.dart';

class ReservationSlot {
  const ReservationSlot({
    required this.slotId,
    required this.startTime,
    required this.endTime,
    required this.remainingCount,
    required this.available,
    required this.confirmModeText,
    required this.closedReason,
  });
  final int slotId;
  final String startTime;
  final String endTime;
  final int remainingCount;
  final bool available;
  final String confirmModeText;
  final String closedReason;

  factory ReservationSlot.fromJson(Map<String, dynamic> json) =>
      ReservationSlot(
        slotId: json['slotId'] as int,
        startTime: json['startTime'] as String? ?? '',
        endTime: json['endTime'] as String? ?? '',
        remainingCount: json['remainingCount'] as int? ?? 0,
        available: json['available'] as bool? ?? false,
        confirmModeText: json['confirmModeText'] as String? ?? '',
        closedReason: json['closedReason'] as String? ?? '',
      );
}

class ReservationTimelineItem {
  const ReservationTimelineItem({
    required this.actionText,
    required this.remark,
    required this.createdAt,
  });
  final String actionText;
  final String remark;
  final String createdAt;

  factory ReservationTimelineItem.fromJson(Map<String, dynamic> json) =>
      ReservationTimelineItem(
        actionText: json['actionText'] as String? ?? '',
        remark: json['remark'] as String? ?? '',
        createdAt: json['createdAt'] as String? ?? '',
      );
}

class ReservationDetail {
  const ReservationDetail({
    required this.id,
    required this.reservationNo,
    required this.shopId,
    required this.shopName,
    required this.address,
    required this.reserveTime,
    required this.peopleCount,
    required this.contactName,
    required this.contactPhone,
    required this.remark,
    required this.statusText,
    required this.confirmModeText,
    required this.rescheduleCount,
    required this.canCancel,
    required this.canReschedule,
    required this.timeline,
  });
  final int id;
  final String reservationNo;
  final int shopId;
  final String shopName;
  final String address;
  final String reserveTime;
  final int peopleCount;
  final String contactName;
  final String contactPhone;
  final String remark;
  final String statusText;
  final String confirmModeText;
  final int rescheduleCount;
  final bool canCancel;
  final bool canReschedule;
  final List<ReservationTimelineItem> timeline;

  factory ReservationDetail.fromJson(Map<String, dynamic> json) {
    final shop = json['shop'] as Map<String, dynamic>? ?? const {};
    return ReservationDetail(
      id: json['id'] as int,
      reservationNo: json['reservationNo'] as String? ?? '',
      shopId: shop['id'] as int? ?? 0,
      shopName: shop['name'] as String? ?? '',
      address: shop['address'] as String? ?? '',
      reserveTime: json['reserveTime'] as String? ?? '',
      peopleCount: json['peopleCount'] as int? ?? 0,
      contactName: json['contactName'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      remark: json['remark'] as String? ?? '',
      statusText: json['statusText'] as String? ?? '',
      confirmModeText: json['confirmModeText'] as String? ?? '',
      rescheduleCount: json['rescheduleCount'] as int? ?? 0,
      canCancel: json['canCancel'] as bool? ?? false,
      canReschedule: json['canReschedule'] as bool? ?? false,
      timeline: (json['timeline'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ReservationTimelineItem.fromJson)
          .toList(),
    );
  }
}

class ReservationResult {
  const ReservationResult({
    required this.id,
    required this.reservationNo,
    required this.statusText,
  });
  final int id;
  final String reservationNo;
  final String statusText;

  factory ReservationResult.fromJson(Map<String, dynamic> json) =>
      ReservationResult(
        id: json['id'] as int,
        reservationNo: json['reservationNo'] as String? ?? '',
        statusText: json['statusText'] as String? ?? '',
      );
}

class ReservationRepository {
  ReservationRepository(this.api);
  final JsonApi api;

  Future<List<ReservationSlot>> loadSlots({
    required int shopId,
    required String date,
    required int peopleCount,
  }) async {
    final result = await api.getJson(
      '/api/c/v1/shops/$shopId/reservation-slots',
      query: {'date': date, 'peopleCount': peopleCount},
    );
    final list = result['list'] as List<dynamic>? ?? const [];
    return list
        .cast<Map<String, dynamic>>()
        .map(ReservationSlot.fromJson)
        .toList();
  }

  Future<ReservationResult> create({
    required int shopId,
    required int slotId,
    required int peopleCount,
    required String contactName,
    required String contactPhone,
    required String remark,
  }) async {
    final result = await api.postJson(
      '/api/c/v1/reservations',
      body: {
        'shopId': shopId,
        'slotId': slotId,
        'peopleCount': peopleCount,
        'contactName': contactName,
        'contactPhone': contactPhone,
        'remark': remark,
      },
    );
    return ReservationResult.fromJson(result);
  }

  Future<ReservationDetail> loadReservation(int reservationId) async {
    return ReservationDetail.fromJson(
      await api.getJson('/api/c/v1/reservations/$reservationId'),
    );
  }

  Future<ReservationDetail> cancelReservation(int reservationId) async {
    return ReservationDetail.fromJson(
      await api.postJson('/api/c/v1/reservations/$reservationId/cancel'),
    );
  }

  Future<ReservationDetail> rescheduleReservation(
    int reservationId, {
    required int slotId,
    required String reserveTime,
    required String reason,
  }) async {
    return ReservationDetail.fromJson(
      await api.postJson(
        '/api/c/v1/reservations/$reservationId/reschedule',
        body: {'slotId': slotId, 'reserveTime': reserveTime, 'reason': reason},
      ),
    );
  }
}
