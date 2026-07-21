import 'package:dazhongdianping_app/core/api_client.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.actorUserId,
    required this.actorName,
    required this.title,
    required this.content,
    required this.linkUrl,
    required this.aggregateCount,
    required this.read,
    required this.createdAt,
  });

  final int id;
  final String type;
  final int? actorUserId;
  final String actorName;
  final String title;
  final String content;
  final String linkUrl;
  final int aggregateCount;
  final bool read;
  final String createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      actorUserId: json['actorUserId'] as int?,
      actorName: json['actorName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      linkUrl: json['linkUrl'] as String? ?? '',
      aggregateCount: json['aggregateCount'] as int? ?? 1,
      read: json['read'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class NotificationRepository {
  NotificationRepository(this.api);

  final JsonApi api;

  Future<List<AppNotification>> load() async {
    final result = await api.getJson(
      '/api/c/v1/notifications',
      query: const {'page': 1, 'pageSize': 30},
    );
    final list = result['list'] as List<dynamic>? ?? const [];
    return list
        .cast<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
  }

  Future<AppNotification> ack(int id) async {
    final result = await api.postJson('/api/c/v1/notifications/$id/ack');
    return AppNotification.fromJson(result);
  }
}
