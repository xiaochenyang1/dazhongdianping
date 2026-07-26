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

class TopicPage {
  const TopicPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });
  final List<TopicSummary> items;
  final int total;
  final int page;
  final int pageSize;

  bool get hasMore => items.length < total;
}

class TopicRepository {
  TopicRepository(this.api);
  final JsonApi api;

  Future<List<TopicSummary>> loadRecommended() async =>
      (await loadRecommendedPage()).items;
  Future<List<TopicSummary>> loadHot() async => (await loadHotPage()).items;
  Future<List<TopicSummary>> loadFollowing() async =>
      (await loadFollowingPage()).items;

  Future<TopicPage> loadRecommendedPage({int page = 1, int pageSize = 30}) =>
      _load(
        '/api/c/v1/topics',
        query: {'sort': 'recommended', 'page': page, 'pageSize': pageSize},
        page: page,
        pageSize: pageSize,
      );

  Future<TopicPage> loadHotPage({int page = 1, int pageSize = 30}) => _load(
    '/api/c/v1/topics/hot',
    query: {'page': page, 'pageSize': pageSize},
    page: page,
    pageSize: pageSize,
  );

  Future<TopicPage> loadFollowingPage({int page = 1, int pageSize = 30}) =>
      _load(
        '/api/c/v1/topics/following',
        query: {'page': page, 'pageSize': pageSize},
        page: page,
        pageSize: pageSize,
      );

  Future<TopicPage> _load(
    String path, {
    required Map<String, Object?> query,
    required int page,
    required int pageSize,
  }) async {
    final result = await api.getJson(path, query: query);
    final items = (result['list'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(TopicSummary.fromJson)
        .toList();
    return TopicPage(
      items: items,
      total: (result['total'] as num?)?.toInt() ?? items.length,
      page: (result['page'] as num?)?.toInt() ?? page,
      pageSize: (result['pageSize'] as num?)?.toInt() ?? pageSize,
    );
  }

  Future<TopicSummary> loadDetail(int id) async =>
      TopicSummary.fromJson(await api.getJson('/api/c/v1/topics/$id'));

  Future<List<CommunityPost>> loadPosts(int id) async =>
      (await loadPostPage(id)).items;

  Future<CommunityPostPage> loadPostPage(
    int id, {
    int page = 1,
    int pageSize = 30,
  }) async {
    final result = await api.getJson(
      '/api/c/v1/topics/$id/posts',
      query: {'page': page, 'pageSize': pageSize},
    );
    final items = (result['list'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(CommunityPost.fromJson)
        .toList();
    return CommunityPostPage(
      items: items,
      total: (result['total'] as num?)?.toInt() ?? items.length,
      page: (result['page'] as num?)?.toInt() ?? page,
      pageSize: (result['pageSize'] as num?)?.toInt() ?? pageSize,
    );
  }

  Future<TopicFollowState> follow(int id) async => TopicFollowState.fromJson(
    await (api as JsonMutationApi).putJson('/api/c/v1/topics/$id/follow'),
  );

  Future<TopicFollowState> unfollow(int id) async => TopicFollowState.fromJson(
    await (api as JsonDeleteApi).deleteJson('/api/c/v1/topics/$id/follow'),
  );
}
