import 'package:dazhongdianping_app/core/api_client.dart';

class ActivitySummary {
  const ActivitySummary({
    required this.id,
    required this.name,
    required this.cityName,
    required this.channelText,
    required this.typeText,
    required this.cover,
    required this.startAt,
    required this.endAt,
    required this.itemCount,
  });

  final int id;
  final String name;
  final String cityName;
  final String channelText;
  final String typeText;
  final String cover;
  final String startAt;
  final String endAt;
  final int itemCount;

  factory ActivitySummary.fromJson(Map<String, dynamic> json) =>
      ActivitySummary(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        cityName: json['cityName'] as String? ?? '',
        channelText: json['channelText'] as String? ?? '',
        typeText: json['typeText'] as String? ?? '',
        cover: json['cover'] as String? ?? '',
        startAt: json['startAt'] as String? ?? '',
        endAt: json['endAt'] as String? ?? '',
        itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      );
}

class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.targetType,
    required this.targetTypeText,
    required this.targetId,
    required this.targetName,
    required this.title,
    required this.subtitle,
    required this.linkUrl,
  });

  final int id;
  final int targetType;
  final String targetTypeText;
  final int targetId;
  final String targetName;
  final String title;
  final String subtitle;
  final String linkUrl;

  factory ActivityItem.fromJson(Map<String, dynamic> json) => ActivityItem(
    id: (json['id'] as num?)?.toInt() ?? 0,
    targetType: (json['targetType'] as num?)?.toInt() ?? 0,
    targetTypeText: json['targetTypeText'] as String? ?? '',
    targetId: (json['targetId'] as num?)?.toInt() ?? 0,
    targetName: json['targetName'] as String? ?? '',
    title: json['title'] as String? ?? '',
    subtitle: json['subtitle'] as String? ?? '',
    linkUrl: json['linkUrl'] as String? ?? '',
  );
}

class ActivityDetail {
  const ActivityDetail({
    required this.id,
    required this.name,
    required this.cityName,
    required this.channelText,
    required this.typeText,
    required this.cover,
    required this.startAt,
    required this.endAt,
    required this.items,
  });

  final int id;
  final String name;
  final String cityName;
  final String channelText;
  final String typeText;
  final String cover;
  final String startAt;
  final String endAt;
  final List<ActivityItem> items;

  factory ActivityDetail.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ActivityItem.fromJson)
        .toList();
    return ActivityDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      cityName: json['cityName'] as String? ?? '',
      channelText: json['channelText'] as String? ?? '',
      typeText: json['typeText'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      startAt: json['startAt'] as String? ?? '',
      endAt: json['endAt'] as String? ?? '',
      items: items,
    );
  }
}

class ActivityRepository {
  ActivityRepository(this.api);
  final JsonApi api;

  Future<List<ActivitySummary>> loadActivities({int limit = 20}) async {
    final result = await api.getJson(
      '/api/c/v1/activities',
      query: {'limit': limit},
    );
    final raw = result['value'] ?? result['list'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ActivitySummary.fromJson)
        .where((item) => item.id > 0)
        .toList();
  }

  Future<ActivityDetail> loadActivityDetail(int activityId) async {
    final result = await api.getJson('/api/c/v1/activities/$activityId');
    return ActivityDetail.fromJson(result);
  }
}
