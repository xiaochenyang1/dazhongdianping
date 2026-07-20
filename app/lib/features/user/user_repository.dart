import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/auth/auth_repository.dart';

enum UserCollection { reviews, posts, favorites, orders, coupons, reservations }

extension UserCollectionInfo on UserCollection {
  String get path => switch (this) {
    UserCollection.reviews => '/api/c/v1/user/reviews',
    UserCollection.posts => '/api/c/v1/user/posts',
    UserCollection.favorites => '/api/c/v1/favorites',
    UserCollection.orders => '/api/c/v1/orders',
    UserCollection.coupons => '/api/c/v1/coupons',
    UserCollection.reservations => '/api/c/v1/reservations',
  };

  String get label => switch (this) {
    UserCollection.reviews => '我的点评',
    UserCollection.posts => '我的帖子',
    UserCollection.favorites => '我的收藏',
    UserCollection.orders => '我的订单',
    UserCollection.coupons => '我的券',
    UserCollection.reservations => '我的预订',
  };
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.nickname,
    required this.avatar,
    required this.email,
    required this.phone,
    required this.hasPassword,
    required this.gender,
    required this.signature,
    required this.preferredRegion,
    required this.level,
    required this.points,
    required this.growthValue,
  });
  final int id;
  final String nickname;
  final String avatar;
  final String email;
  final String phone;
  final bool hasPassword;
  final int gender;
  final String signature;
  final String preferredRegion;
  final int level;
  final int points;
  final int growthValue;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as int,
    nickname: json['nickname'] as String? ?? '',
    avatar: json['avatar'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    hasPassword: json['hasPassword'] as bool? ?? false,
    gender: json['gender'] as int? ?? 0,
    signature: json['signature'] as String? ?? '',
    preferredRegion: json['preferredRegion'] as String? ?? 'EU',
    level: json['level'] as int? ?? 1,
    points: json['points'] as int? ?? 0,
    growthValue: json['growthValue'] as int? ?? 0,
  );
}

class UserCollectionPage {
  const UserCollectionPage({required this.items, required this.total});
  final List<Map<String, dynamic>> items;
  final int total;
}

class PublicUserProfile {
  const PublicUserProfile({
    required this.id,
    required this.nickname,
    required this.avatar,
    required this.signature,
    required this.level,
    required this.reviewCount,
    required this.followerCount,
    required this.followingCount,
    required this.followedByCurrentUser,
  });
  final int id;
  final String nickname;
  final String avatar;
  final String signature;
  final int level;
  final int reviewCount;
  final int followerCount;
  final int followingCount;
  final bool followedByCurrentUser;
  factory PublicUserProfile.fromJson(Map<String, dynamic> json) =>
      PublicUserProfile(
        id: json['id'] as int,
        nickname: json['nickname'] as String? ?? '',
        avatar: json['avatar'] as String? ?? '',
        signature: json['signature'] as String? ?? '',
        level: json['level'] as int? ?? 1,
        reviewCount: json['reviewCount'] as int? ?? 0,
        followerCount: json['followerCount'] as int? ?? 0,
        followingCount: json['followingCount'] as int? ?? 0,
        followedByCurrentUser: json['followedByCurrentUser'] as bool? ?? false,
      );
  PublicUserProfile withFollow({
    required bool following,
    required int followers,
  }) => PublicUserProfile(
    id: id,
    nickname: nickname,
    avatar: avatar,
    signature: signature,
    level: level,
    reviewCount: reviewCount,
    followerCount: followers,
    followingCount: followingCount,
    followedByCurrentUser: following,
  );
}

class SocialUserSummary {
  const SocialUserSummary({
    required this.id,
    required this.nickname,
    required this.avatar,
    required this.signature,
    required this.level,
    required this.followerCount,
    required this.followedAt,
  });
  final int id;
  final String nickname;
  final String avatar;
  final String signature;
  final int level;
  final int followerCount;
  final String followedAt;
  factory SocialUserSummary.fromJson(Map<String, dynamic> json) =>
      SocialUserSummary(
        id: json['id'] as int,
        nickname: json['nickname'] as String? ?? '',
        avatar: json['avatar'] as String? ?? '',
        signature: json['signature'] as String? ?? '',
        level: json['level'] as int? ?? 1,
        followerCount: json['followerCount'] as int? ?? 0,
        followedAt: json['followedAt'] as String? ?? '',
      );
}

class SocialUserPage {
  const SocialUserPage({required this.items, required this.total});
  final List<SocialUserSummary> items;
  final int total;
}

class FollowResult {
  const FollowResult({required this.following, required this.followerCount});
  final bool following;
  final int followerCount;
  factory FollowResult.fromJson(Map<String, dynamic> json) => FollowResult(
    following: json['following'] as bool? ?? false,
    followerCount: json['followerCount'] as int? ?? 0,
  );
}

class UserRepository {
  UserRepository(this.api);
  final JsonApi api;

  Future<UserProfile> loadProfile() async {
    return UserProfile.fromJson(await api.getJson('/api/c/v1/user/me'));
  }

  Future<PublicUserProfile> loadPublicProfile(int userId) async =>
      PublicUserProfile.fromJson(await api.getJson('/api/c/v1/user/$userId'));

  Future<SocialUserPage> loadRelationships(
    int userId, {
    required bool followers,
  }) async {
    final result = await api.getJson(
      '/api/c/v1/user/$userId/${followers ? 'followers' : 'following'}',
      query: const {'page': 1, 'pageSize': 50},
    );
    final items = (result['list'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(SocialUserSummary.fromJson)
        .toList();
    return SocialUserPage(
      items: items,
      total: result['total'] as int? ?? items.length,
    );
  }

  Future<FollowResult> follow(int userId) async => FollowResult.fromJson(
    await _mutationApi.putJson('/api/c/v1/follow/$userId'),
  );
  Future<FollowResult> unfollow(int userId) async => FollowResult.fromJson(
    await _deleteApi.deleteJson('/api/c/v1/follow/$userId'),
  );

  Future<UserProfile> updateProfile({
    required String nickname,
    required String avatar,
    required int gender,
    required String signature,
  }) async {
    final result = await _mutationApi.putJson(
      '/api/c/v1/user/profile',
      body: {
        'nickname': nickname,
        'avatar': avatar,
        'gender': gender,
        'signature': signature,
      },
    );
    return UserProfile.fromJson(result);
  }

  Future<SendCodeResult> sendBindCode({
    required String type,
    required String account,
  }) async {
    final result = await api.postJson(
      '/api/c/v1/auth/send-code',
      body: {
        'scene': 'bind',
        'type': type,
        'account': account,
        'deviceId': 'flutter-app',
      },
    );
    return SendCodeResult.fromJson(result);
  }

  Future<UserProfile> bindAccount({
    required String type,
    required String account,
    required String code,
  }) async {
    final result = await api.postJson(
      '/api/c/v1/user/bind',
      body: {'type': type, 'account': account, 'code': code},
    );
    return UserProfile.fromJson(result);
  }

  Future<void> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _mutationApi.putJson(
      '/api/c/v1/user/password',
      body: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
  }

  Future<UserCollectionPage> loadCollection(UserCollection collection) async {
    final result = await api.getJson(
      collection.path,
      query: const {'page': 1, 'pageSize': 30},
    );
    final list = (result['list'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return UserCollectionPage(
      items: list,
      total: result['total'] as int? ?? list.length,
    );
  }

  JsonMutationApi get _mutationApi {
    if (api is! JsonMutationApi) {
      throw StateError('当前 API 客户端不支持 PUT 请求');
    }
    return api as JsonMutationApi;
  }

  JsonDeleteApi get _deleteApi => api is JsonDeleteApi
      ? api as JsonDeleteApi
      : throw StateError('当前 API 客户端不支持 DELETE 请求');
}
