import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/circle/circle_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class CircleApi implements JsonApi, JsonMutationApi, JsonDeleteApi {
  String path = '';
  Map<String, Object?>? query;
  Object? body;
  Map<String, dynamic> circle() => {
    'id': 3,
    'region': 'EU',
    'name': '伦敦生活圈',
    'description': '英国华人本地生活',
    'coverUrl': '',
    'memberCount': 12,
    'postCount': 8,
    'sort': 20,
    'status': 1,
    'joinedByCurrentUser': false,
  };
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    this.path = path;
    this.query = query;
    if (path.endsWith('/members')) {
      return {
        'list': [
          {
            'id': 9,
            'nickname': '伦敦小王',
            'avatar': '',
            'signature': '探店',
            'level': 4,
            'joinedAt': '2026-07-17 10:00:00',
          },
        ],
        'total': 1,
      };
    }
    if (path.endsWith('/posts')) return {'list': const [], 'total': 0};
    if (path == '/api/c/v1/groups/3') return circle();
    return {
      'list': [circle()],
      'total': 1,
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      {};
  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    this.path = path;
    return {'circleId': 3, 'joined': true, 'memberCount': 13};
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path) async {
    this.path = path;
    return {'circleId': 3, 'joined': false, 'memberCount': 12};
  }
}

void main() {
  test(
    'circle repository covers list detail members posts and membership',
    () async {
      final api = CircleApi(), repo = CircleRepository(api);
      expect((await repo.loadCircles()).single.name, '伦敦生活圈');
      expect((await repo.loadMyCircles()).single.id, 3);
      expect(api.query?['joined'], true);
      expect((await repo.loadDetail(3)).memberCount, 12);
      expect((await repo.loadMembers(3)).single.nickname, '伦敦小王');
      expect(await repo.loadPosts(3), isEmpty);
      expect((await repo.join(3)).memberCount, 13);
      expect((await repo.leave(3)).joined, isFalse);
    },
  );
}
