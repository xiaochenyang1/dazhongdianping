import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/community/community_repository.dart';

class AppCircle {
  const AppCircle({
    required this.id,
    required this.region,
    required this.name,
    required this.description,
    required this.coverUrl,
    required this.memberCount,
    required this.postCount,
    required this.sort,
    required this.status,
    required this.joined,
  });
  final int id, memberCount, postCount, sort, status;
  final String region, name, description, coverUrl;
  final bool joined;
  factory AppCircle.fromJson(Map<String, dynamic> json) => AppCircle(
    id: json['id'] as int,
    region: json['region'] as String? ?? '',
    name: json['name'] as String? ?? '',
    description: json['description'] as String? ?? '',
    coverUrl: json['coverUrl'] as String? ?? '',
    memberCount: json['memberCount'] as int? ?? 0,
    postCount: json['postCount'] as int? ?? 0,
    sort: json['sort'] as int? ?? 0,
    status: json['status'] as int? ?? 1,
    joined: json['joinedByCurrentUser'] as bool? ?? false,
  );
  AppCircle withMembership(bool value, int count) => AppCircle(
    id: id,
    region: region,
    name: name,
    description: description,
    coverUrl: coverUrl,
    memberCount: count,
    postCount: postCount,
    sort: sort,
    status: status,
    joined: value,
  );
}

class CircleMember {
  const CircleMember({
    required this.id,
    required this.nickname,
    required this.avatar,
    required this.signature,
    required this.level,
    required this.joinedAt,
  });
  final int id, level;
  final String nickname, avatar, signature, joinedAt;
  factory CircleMember.fromJson(Map<String, dynamic> json) => CircleMember(
    id: json['id'] as int,
    nickname: json['nickname'] as String? ?? '',
    avatar: json['avatar'] as String? ?? '',
    signature: json['signature'] as String? ?? '',
    level: json['level'] as int? ?? 1,
    joinedAt: json['joinedAt'] as String? ?? '',
  );
}

class CircleMembership {
  const CircleMembership(this.joined, this.memberCount);
  final bool joined;
  final int memberCount;
}

class CircleRepository {
  CircleRepository(this.api);
  final JsonApi api;
  Future<List<AppCircle>> loadCircles() => _circles('/api/c/v1/groups');
  Future<List<AppCircle>> loadMyCircles() => _circles(
    '/api/c/v1/groups',
    query: const {'joined': true, 'page': 1, 'pageSize': 30},
  );
  Future<List<AppCircle>> _circles(
    String path, {
    Map<String, Object?> query = const {'page': 1, 'pageSize': 30},
  }) async =>
      ((await api.getJson(path, query: query))['list'] as List<dynamic>? ??
              const [])
          .cast<Map<String, dynamic>>()
          .map(AppCircle.fromJson)
          .toList();
  Future<AppCircle> loadDetail(int id) async =>
      AppCircle.fromJson(await api.getJson('/api/c/v1/groups/$id'));
  Future<List<CircleMember>> loadMembers(int id) async =>
      ((await api.getJson(
                    '/api/c/v1/groups/$id/members',
                    query: const {'page': 1, 'pageSize': 50},
                  ))['list']
                  as List<dynamic>? ??
              const [])
          .cast<Map<String, dynamic>>()
          .map(CircleMember.fromJson)
          .toList();
  Future<List<CommunityPost>> loadPosts(int id) async =>
      ((await api.getJson(
                    '/api/c/v1/groups/$id/posts',
                    query: const {'page': 1, 'pageSize': 30},
                  ))['list']
                  as List<dynamic>? ??
              const [])
          .cast<Map<String, dynamic>>()
          .map(CommunityPost.fromJson)
          .toList();
  Future<CircleMembership> join(int id) async {
    final d = await (api as JsonMutationApi).putJson(
      '/api/c/v1/groups/$id/membership',
    );
    return CircleMembership(d['joined'] as bool, d['memberCount'] as int);
  }

  Future<CircleMembership> leave(int id) async {
    final d = await (api as JsonDeleteApi).deleteJson(
      '/api/c/v1/groups/$id/membership',
    );
    return CircleMembership(d['joined'] as bool, d['memberCount'] as int);
  }
}
