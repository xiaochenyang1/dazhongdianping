import 'package:dazhongdianping_app/core/api_client.dart';

/// 排队候位条目。status：1排队中 2已叫号 3已入座 4已过号 5已取消。
class WaitlistEntry {
  const WaitlistEntry({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.tableType,
    required this.tableTypeText,
    required this.partySize,
    required this.queueNo,
    required this.status,
    required this.statusText,
    required this.aheadCount,
  });

  final int id;
  final int shopId;
  final String shopName;
  final int tableType;
  final String tableTypeText;
  final int partySize;
  final int queueNo;
  final int status;
  final String statusText;
  final int aheadCount;

  factory WaitlistEntry.fromJson(Map<String, dynamic> json) => WaitlistEntry(
        id: (json['id'] as num?)?.toInt() ?? 0,
        shopId: (json['shopId'] as num?)?.toInt() ?? 0,
        shopName: json['shopName'] as String? ?? '',
        tableType: (json['tableType'] as num?)?.toInt() ?? 1,
        tableTypeText: json['tableTypeText'] as String? ?? '',
        partySize: (json['partySize'] as num?)?.toInt() ?? 1,
        queueNo: (json['queueNo'] as num?)?.toInt() ?? 0,
        status: (json['status'] as num?)?.toInt() ?? 1,
        statusText: json['statusText'] as String? ?? '',
        aheadCount: (json['aheadCount'] as num?)?.toInt() ?? 0,
      );
}

/// C端排队候位仓库。
class WaitlistRepository {
  WaitlistRepository(this.api);

  final JsonApi api;

  Future<WaitlistEntry> join(int shopId, {required int tableType, required int partySize}) async {
    final result = await api.postJson(
      '/api/c/v1/shops/$shopId/waitlist',
      body: {'tableType': tableType, 'partySize': partySize},
    );
    return WaitlistEntry.fromJson(result);
  }

  Future<List<WaitlistEntry>> loadMine() async {
    final result = await api.getJson('/api/c/v1/waitlist/mine');
    final raw = result['value'] ?? result['list'];
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map(WaitlistEntry.fromJson).toList();
  }

  Future<WaitlistEntry> cancel(int id) async {
    final result = await api.postJson('/api/c/v1/waitlist/$id/cancel');
    return WaitlistEntry.fromJson(result);
  }
}
