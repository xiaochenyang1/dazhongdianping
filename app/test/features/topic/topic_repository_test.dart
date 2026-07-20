import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/topic/topic_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class TopicApi implements JsonApi, JsonMutationApi, JsonDeleteApi {
  String path = '';
  Map<String, Object?>? query;

  Map<String, dynamic> topic({bool followed = false}) => {
    'id': 31,
    'region': 'EU',
    'name': '伦敦咖啡',
    'postCount': 12,
    'followerCount': 88,
    'recommended': true,
    'pinnedSort': 0,
    'followedByCurrentUser': followed,
    'hotScore': 169,
    'postCount7d': 2,
    'likeCount7d': 3,
    'commentCount7d': 4,
    'calculatedAt': '2026-07-17 19:00:00',
  };

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    this.path = path;
    this.query = query;
    if (path.endsWith('/posts')) return {'list': const [], 'total': 0};
    if (path == '/api/c/v1/topics/31') return topic();
    return {
      'list': [topic(followed: path.endsWith('/following'))],
      'total': 1,
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async => {};

  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    this.path = path;
    return {'topicId': 31, 'followed': true, 'followerCount': 89};
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path) async {
    this.path = path;
    return {'topicId': 31, 'followed': false, 'followerCount': 88};
  }
}

void main() {
  test('topic repository covers plaza detail posts and follow state', () async {
    final api = TopicApi();
    final repository = TopicRepository(api);

    expect((await repository.loadRecommended()).single.name, '伦敦咖啡');
    expect(api.path, '/api/c/v1/topics');
    expect(api.query?['sort'], 'recommended');
    expect((await repository.loadHot()).single.hotScore, 169);
    expect(api.path, '/api/c/v1/topics/hot');
    expect(api.query?['pageSize'], 30);
    expect((await repository.loadFollowing()).single.followed, isTrue);
    expect(api.path, '/api/c/v1/topics/following');
    expect((await repository.loadDetail(31)).followerCount, 88);
    expect(await repository.loadPosts(31), isEmpty);
    expect((await repository.follow(31)).followerCount, 89);
    expect(api.path, '/api/c/v1/topics/31/follow');
    expect((await repository.unfollow(31)).followed, isFalse);
  });
}
