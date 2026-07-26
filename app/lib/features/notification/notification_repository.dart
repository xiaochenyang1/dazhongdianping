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

class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<AppNotification> items;
  final int total;
  final int page;
  final int pageSize;

  bool get hasMore => items.length < total;

  NotificationPage copyWith({List<AppNotification>? items}) => NotificationPage(
    items: items ?? this.items,
    total: total,
    page: page,
    pageSize: pageSize,
  );
}

class NotificationRepository {
  NotificationRepository(this.api);

  final JsonApi api;

  Future<List<AppNotification>> load() async => (await loadPage()).items;

  Future<NotificationPage> loadPage({int page = 1, int pageSize = 30}) async {
    final result = await api.getJson(
      '/api/c/v1/notifications',
      query: {'page': page, 'pageSize': pageSize},
    );
    final list = result['list'] as List<dynamic>? ?? const [];
    final items = list
        .cast<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
    return NotificationPage(
      items: items,
      total: (result['total'] as num?)?.toInt() ?? items.length,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<int> loadUnreadCount() async {
    final result = await api.getJson('/api/c/v1/notifications/unread-count');
    return (result['count'] as num?)?.toInt() ?? 0;
  }

  Future<AppNotification> ack(int id) async {
    final result = await api.postJson('/api/c/v1/notifications/$id/ack');
    return AppNotification.fromJson(result);
  }

  Future<({int updated, int count})> markAllRead() async {
    final result = await api.postJson('/api/c/v1/notifications/read-all');
    return (
      updated: (result['updated'] as num?)?.toInt() ?? 0,
      count: (result['count'] as num?)?.toInt() ?? 0,
    );
  }
}
