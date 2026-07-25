import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/activity/activity_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class ActivityFakeApi implements JsonApi {
  String? path;
  Map<String, Object?>? query;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    this.path = path;
    this.query = query;
    if (path == '/api/c/v1/activities') {
      return {
        'value': [
          {
            'id': 9001,
            'name': '暑期火锅节',
            'cityName': '上海',
            'channelText': 'C端',
            'typeText': '专题',
            'cover': '',
            'startAt': '2026-07-01',
            'endAt': '2026-08-31',
            'itemCount': 3,
          },
        ],
      };
    }
    if (path == '/api/c/v1/activities/9001') {
      return {
        'id': 9001,
        'name': '暑期火锅节',
        'cityName': '上海',
        'channelText': 'C端',
        'typeText': '专题',
        'cover': '',
        'startAt': '2026-07-01',
        'endAt': '2026-08-31',
        'items': [
          {
            'id': 1,
            'targetType': 1,
            'targetTypeText': '店铺',
            'targetId': 10001,
            'targetName': '渝里火锅徐汇店',
            'title': '榜单同款火锅',
            'subtitle': '徐汇店',
            'linkUrl': '/shops/10001',
          },
        ],
      };
    }
    return const {};
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      const {};
}

void main() {
  test('activity repository loads list and detail', () async {
    final api = ActivityFakeApi();
    final repository = ActivityRepository(api);

    final activities = await repository.loadActivities(limit: 12);
    expect(api.path, '/api/c/v1/activities');
    expect(api.query?['limit'], 12);
    expect(activities.single.name, '暑期火锅节');

    final detail = await repository.loadActivityDetail(9001);
    expect(api.path, '/api/c/v1/activities/9001');
    expect(detail.items.single.targetName, '渝里火锅徐汇店');
    expect(detail.items.single.targetType, 1);
  });
}
