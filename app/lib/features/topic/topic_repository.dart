import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/community/community_repository.dart';

class TopicSummary {
  const TopicSummary({
    required this.id,
    required this.region,
    required this.name,
    required this.postCount,
    required this.followerCount,
    required this.recommended,
    required this.pinnedSort,
    required this.followed,
    required this.hotScore,
    required this.postCount7d,
    required this.likeCount7d,
    required this.commentCount7d,
    required this.calculatedAt,
  });

  final int id, postCount, followerCount, pinnedSort;
  final int hotScore, postCount7d, likeCount7d, commentCount7d;
  final String region, name, calculatedAt;
  final bool recommended, followed;

  factory TopicSummary.fromJson(Map<String, dynamic> json) => TopicSummary(
    id: json['id'] as int,
    region: json['region'] as String? ?? '',
    name: json['name'] as String? ?? '',
    postCount: json['postCount'] as int? ?? 0,
    followerCount: json['followerCount'] as int? ?? 0,
    recommended: json['recommended'] as bool? ?? false,
    pinnedSort: json['pinnedSort'] as int? ?? 0,
    followed: json['followedByCurrentUser'] as bool? ?? false,
    hotScore: json['hotScore'] as int? ?? 0,
    postCount7d: json['postCount7d'] as int? ?? 0,
    likeCount7d: json['likeCount7d'] as int? ?? 0,
    commentCount7d: json['commentCount7d'] as int? ?? 0,
    calculatedAt: json['calculatedAt'] as String? ?? '',
  );

  TopicSummary withFollow(bool value, int count) => TopicSummary(
    id: id,
    region: region,
    name: name,
    postCount: postCount,
    followerCount: count,
    recommended: recommended,
    pinnedSort: pinnedSort,
    followed: value,
    hotScore: hotScore,
    postCount7d: postCount7d,
    likeCount7d: likeCount7d,
    commentCount7d: commentCount7d,
    calculatedAt: calculatedAt,
  );
}

class TopicFollowState {
  const TopicFollowState({
    required this.topicId,
    required this.followed,
    required this.followerCount,
  });
  final int topicId, followerCount;
  final bool followed;
  factory TopicFollowState.fromJson(Map<String, dynamic> json) =>
      TopicFollowState(
        topicId: json['topicId'] as int,
        followed: json['followed'] as bool,
        followerCount: json['followerCount'] as int,
      );
}

class TopicRepository {
  TopicRepository(this.api);
  final JsonApi api;

  Future<List<TopicSummary>> loadRecommended() => _load(
    '/api/c/v1/topics',
    query: const {'sort': 'recommended', 'page': 1, 'pageSize': 30},
  );

  Future<List<TopicSummary>> loadHot() => _load(
    '/api/c/v1/topics/hot',
    query: const {'page': 1, 'pageSize': 30},
  );

  Future<List<TopicSummary>> loadFollowing() => _load(
    '/api/c/v1/topics/following',
    query: const {'page': 1, 'pageSize': 30},
  );

  Future<List<TopicSummary>> _load(
    String path, {
    required Map<String, Object?> query,
  }) async =>
      ((await api.getJson(path, query: query))['list'] as List<dynamic>? ??
              const [])
          .cast<Map<String, dynamic>>()
          .map(TopicSummary.fromJson)
          .toList();

  Future<TopicSummary> loadDetail(int id) async =>
      TopicSummary.fromJson(await api.getJson('/api/c/v1/topics/$id'));

  Future<List<CommunityPost>> loadPosts(int id) async =>
      ((await api.getJson(
                    '/api/c/v1/topics/$id/posts',
                    query: const {'page': 1, 'pageSize': 30},
                  ))['list']
                  as List<dynamic>? ??
              const [])
          .cast<Map<String, dynamic>>()
          .map(CommunityPost.fromJson)
          .toList();

  Future<TopicFollowState> follow(int id) async => TopicFollowState.fromJson(
    await (api as JsonMutationApi).putJson('/api/c/v1/topics/$id/follow'),
  );

  Future<TopicFollowState> unfollow(int id) async =>
      TopicFollowState.fromJson(
        await (api as JsonDeleteApi).deleteJson(
          '/api/c/v1/topics/$id/follow',
        ),
      );
}
