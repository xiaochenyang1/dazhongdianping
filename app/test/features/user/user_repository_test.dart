import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class UserFakeApi implements JsonApi, JsonMutationApi, JsonDeleteApi {
  String? path;
  Object? body;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (path == '/api/c/v1/user/me') {
      return {
        'id': 8,
        'nickname': 'EU User',
        'avatar': '',
        'email': 'eu@example.com',
        'phone': '+33123456789',
        'hasPassword': true,
        'gender': 2,
        'signature': 'Bonjour',
        'preferredRegion': 'EU',
        'level': 3,
        'points': 90,
        'growthValue': 220,
      };
    }
    if (path == '/api/c/v1/user/9') {
      return {
        'id': 9,
        'nickname': '伦敦小王',
        'avatar': '',
        'signature': '咖啡探店',
        'preferredRegion': 'EU',
        'level': 4,
        'points': 8,
        'growthValue': 360,
        'reviewCount': 5,
        'followerCount': 12,
        'followingCount': 7,
        'followedByCurrentUser': false,
      };
    }
    if (path.endsWith('/followers') || path.endsWith('/following')) {
      return {
        'list': [
          {
            'id': 10,
            'nickname': '巴黎小李',
            'avatar': '',
            'signature': '',
            'level': 2,
            'followerCount': 3,
            'followedByCurrentUser': false,
            'followedAt': '2026-07-17 09:00:00',
          },
        ],
        'total': 1,
      };
    }
    return {
      'list': [
        {'id': 1, 'title': 'Example'},
      ],
      'total': 1,
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    this.path = path;
    this.body = body;
    if (path == '/api/c/v1/auth/send-code') {
      return {
        'sent': true,
        'expireSeconds': 300,
        'nextRetrySeconds': 60,
        'mockCode': '112233',
      };
    }
    if (path == '/api/c/v1/user/bind') {
      return {
        'id': 8,
        'nickname': 'EU User',
        'avatar': '',
        'email': 'eu@example.com',
        'phone': '+447700900111',
        'hasPassword': true,
        'gender': 2,
        'signature': 'Bonjour',
        'preferredRegion': 'EU',
        'level': 3,
        'points': 90,
        'growthValue': 220,
      };
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    this.path = path;
    this.body = body;
    if (path == '/api/c/v1/follow/9') {
      return {'userId': 9, 'following': true, 'followerCount': 13};
    }
    return {
      'id': 8,
      'nickname': 'Updated User',
      'avatar': 'avatar.png',
      'email': 'eu@example.com',
      'phone': '+33123456789',
      'hasPassword': true,
      'gender': 1,
      'signature': 'Updated signature',
      'preferredRegion': 'EU',
      'level': 3,
      'points': 90,
      'growthValue': 220,
    };
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path) async {
    this.path = path;
    return {'userId': 9, 'following': false, 'followerCount': 12};
  }
}

void main() {
  test('user repository loads profile and authenticated collections', () async {
    final repository = UserRepository(UserFakeApi());
    final profile = await repository.loadProfile();
    final orders = await repository.loadCollection(UserCollection.orders);

    expect(profile.nickname, 'EU User');
    expect(profile.email, 'eu@example.com');
    expect(profile.phone, '+33123456789');
    expect(profile.hasPassword, isTrue);
    expect(profile.gender, 2);
    expect(profile.signature, 'Bonjour');
    expect(profile.level, 3);
    expect(orders.total, 1);
    expect(orders.items.single['title'], 'Example');
  });

  test('user repository updates the complete editable profile', () async {
    final api = UserFakeApi();
    final repository = UserRepository(api);

    final profile = await repository.updateProfile(
      nickname: 'Updated User',
      avatar: 'avatar.png',
      gender: 1,
      signature: 'Updated signature',
    );

    expect(api.path, '/api/c/v1/user/profile');
    expect(api.body, {
      'nickname': 'Updated User',
      'avatar': 'avatar.png',
      'gender': 1,
      'signature': 'Updated signature',
    });
    expect(profile.nickname, 'Updated User');
  });

  test('user repository sends a binding verification code', () async {
    final api = UserFakeApi();
    final repository = UserRepository(api);

    final result = await repository.sendBindCode(
      type: 'phone',
      account: '+447700900111',
    );

    expect(api.path, '/api/c/v1/auth/send-code');
    expect(api.body, {
      'scene': 'bind',
      'type': 'phone',
      'account': '+447700900111',
      'deviceId': 'flutter-app',
    });
    expect(result.mockCode, '112233');
  });

  test('user repository binds a verified account', () async {
    final api = UserFakeApi();
    final repository = UserRepository(api);

    final profile = await repository.bindAccount(
      type: 'phone',
      account: '+447700900111',
      code: '112233',
    );

    expect(api.path, '/api/c/v1/user/bind');
    expect(api.body, {
      'type': 'phone',
      'account': '+447700900111',
      'code': '112233',
    });
    expect(profile.phone, '+447700900111');
  });

  test('user repository updates the login password', () async {
    final api = UserFakeApi();
    final repository = UserRepository(api);

    await repository.updatePassword(
      oldPassword: 'OldPass123',
      newPassword: 'NewPass123',
    );

    expect(api.path, '/api/c/v1/user/password');
    expect(api.body, {
      'oldPassword': 'OldPass123',
      'newPassword': 'NewPass123',
    });
  });

  test(
    'user repository loads public social profile and relationships',
    () async {
      final api = UserFakeApi();
      final repository = UserRepository(api);
      final profile = await repository.loadPublicProfile(9);
      final followers = await repository.loadRelationships(9, followers: true);
      expect(profile.followerCount, 12);
      expect(profile.followingCount, 7);
      expect(followers.items.single.nickname, '巴黎小李');
    },
  );

  test('user repository follows and unfollows explicitly', () async {
    final api = UserFakeApi();
    final repository = UserRepository(api);
    final followed = await repository.follow(9);
    expect(followed.following, isTrue);
    expect(api.path, '/api/c/v1/follow/9');
    final unfollowed = await repository.unfollow(9);
    expect(unfollowed.following, isFalse);
  });
}
