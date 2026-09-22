import 'package:dazhongdianping_app/core/api_client.dart';

/// 投诉处理日志。
class ComplaintLog {
  const ComplaintLog({
    required this.id,
    required this.actorTypeText,
    required this.actionText,
    required this.remark,
    this.createdAt,
  });

  final int id;
  final String actorTypeText;
  final String actionText;
  final String remark;
  final String? createdAt;

  factory ComplaintLog.fromJson(Map<String, dynamic> json) => ComplaintLog(
        id: (json['id'] as num?)?.toInt() ?? 0,
        actorTypeText: json['actorTypeText'] as String? ?? '',
        actionText: json['actionText'] as String? ?? '',
        remark: json['remark'] as String? ?? '',
        createdAt: json['createdAt'] as String?,
      );
}

/// 投诉工单。status：1待受理 2处理中 3已解决 4已驳回。
class ComplaintTicket {
  const ComplaintTicket({
    required this.id,
    required this.ticketNo,
    required this.shopId,
    required this.shopName,
    required this.orderId,
    required this.type,
    required this.typeText,
    required this.title,
    required this.content,
    required this.status,
    required this.statusText,
    required this.merchantReply,
    required this.resolution,
    this.createdAt,
    this.logs = const [],
  });

  final int id;
  final String ticketNo;
  final int shopId;
  final String shopName;
  final int orderId;
  final int type;
  final String typeText;
  final String title;
  final String content;
  final int status;
  final String statusText;
  final String merchantReply;
  final String resolution;
  final String? createdAt;
  final List<ComplaintLog> logs;

  factory ComplaintTicket.fromJson(Map<String, dynamic> json) => ComplaintTicket(
        id: (json['id'] as num?)?.toInt() ?? 0,
        ticketNo: json['ticketNo'] as String? ?? '',
        shopId: (json['shopId'] as num?)?.toInt() ?? 0,
        shopName: json['shopName'] as String? ?? '',
        orderId: (json['orderId'] as num?)?.toInt() ?? 0,
        type: (json['type'] as num?)?.toInt() ?? 1,
        typeText: json['typeText'] as String? ?? '',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        status: (json['status'] as num?)?.toInt() ?? 1,
        statusText: json['statusText'] as String? ?? '',
        merchantReply: json['merchantReply'] as String? ?? '',
        resolution: json['resolution'] as String? ?? '',
        createdAt: json['createdAt'] as String?,
        logs: (json['logs'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(ComplaintLog.fromJson)
            .toList(),
      );
}

/// C端投诉仓库：发起、我的投诉、详情。
class ComplaintRepository {
  ComplaintRepository(this.api);

  final JsonApi api;

  Future<ComplaintTicket> createComplaint({
    required int shopId,
    int? orderId,
    required int type,
    required String title,
    required String content,
  }) async {
    final result = await api.postJson('/api/c/v1/complaints', body: {
      'shopId': shopId,
      if (orderId != null) 'orderId': orderId,
      'type': type,
      'title': title,
      'content': content,
    });
    return ComplaintTicket.fromJson(result);
  }

  Future<List<ComplaintTicket>> loadMyComplaints({int? status}) async {
    final query = <String, Object?>{'page': 1, 'pageSize': 50};
    if (status != null) query['status'] = status;
    final result = await api.getJson('/api/c/v1/complaints', query: query);
    final raw = result['list'] ?? result['value'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ComplaintTicket.fromJson)
        .toList();
  }

  Future<ComplaintTicket> loadComplaint(int id) async {
    return ComplaintTicket.fromJson(await api.getJson('/api/c/v1/complaints/$id'));
  }
}
