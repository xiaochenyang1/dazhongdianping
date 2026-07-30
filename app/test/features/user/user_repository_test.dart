import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class UserFakeApi implements JsonApi, JsonMutationApi, JsonDeleteApi {
  String? path;
  Object? body;
  Map<String, Object?>? query;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    this.query = query;
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
        'expertCertification': {'code': 'local_expert', 'label': '本地达人'},
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
    if (path == '/api/c/v1/user/growth/records') {
      return {
        'list': [
          {
            'id': 1,
            'type': 1,
            'typeText': '成长值',
            'action': 'review_create',
            'actionText': '发布点评',
            'bizId': 12,
            'changeAmount': 10,
            'balanceAfter': 230,
            'remark': '发点评奖励',
            'createdAt': '2026-07-25 18:00:00',
          },
          {
            'id': 2,
            'type': 2,
            'typeText': '积分',
            'action': 'review_create',
            'actionText': '发布点评',
            'bizId': 12,
            'changeAmount': 5,
            'balanceAfter': 95,
            'remark': '发点评奖励',
            'createdAt': '2026-07-25 18:00:00',
          },
        ],
        'total': 2,
        'page': 1,
        'pageSize': 20,
        'hasMore': false,
      };
    }
    if (path == '/api/c/v1/user/expert-certification') {
      return {
        'id': 0,
        'status': 0,
        'statusText': '未申请',
        'reason': '',
        'rejectReason': '',
        'badge': null,
        'submittedAt': '',
        'reviewedAt': '',
        'effectiveStartAt': '',
        'effectiveEndAt': '',
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
    if (path == '/api/c/v1/user/expert-certification/apply') {
      return {
        'id': 8801,
        'status': 1,
        'statusText': '待审核',
        'reason': (body as Map)['reason'] ?? '',
        'rejectReason': '',
        'badge': null,
        'submittedAt': '2026-07-25 19:00:00',
        'reviewedAt': '',
        'effectiveStartAt': '',
        'effectiveEndAt': '',
      };
    }
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

class UserReadOnlyApi implements JsonApi {
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async => const {};

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      const {};
}

void main() {
  test('user repository reports unsupported write capabilities', () {
    final repository = UserRepository(UserReadOnlyApi());

    expect(
      () => repository.updateProfile(
        nickname: 'EU User',
        avatar: '',
        gender: 1,
        signature: 'Bonjour',
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          '当前 API 客户端不支持 PUT requests',
        ),
      ),
    );
    expect(
      () => repository.unfollow(9),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          '当前 API 客户端不支持 DELETE requests',
        ),
      ),
    );
  });

  test('user repository loads profile and authenticated collections', () async {
    final repository = UserRepository(UserFakeApi());
    final profile = await repository.loadProfile();
    final orders = await repository.loadCollection(UserCollection.orders);
    expect(orders.page, 1);
    expect(orders.pageSize, 30);

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
      expect(profile.expertCertificationCode, 'local_expert');
      expect(profile.expertCertificationLabel, '本地达人');
      expect(followers.items.single.nickname, '巴黎小李');
      final later = await repository.loadRelationships(
        9,
        followers: true,
        page: 2,
        pageSize: 12,
      );
      expect(api.query, {'page': 2, 'pageSize': 12});
      expect(later.page, 2);
      expect(later.pageSize, 12);
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

  test('user repository loads growth records', () async {
    final api = UserFakeApi();
    final repository = UserRepository(api);

    final page = await repository.loadGrowthRecords(page: 1, pageSize: 20);
    expect(page.total, 2);
    expect(page.items.first.actionText, '发布点评');
    expect(page.items.first.changeAmount, 10);
    expect(page.items.last.typeText, '积分');
  });

  test('user repository loads and applies expert certification', () async {
    final api = UserFakeApi();
    final repository = UserRepository(api);

    final status = await repository.loadExpertCertification();
    expect(status.status, 0);
    expect(status.canApply, isTrue);

    final applied = await repository.applyExpertCertification('长期在巴黎写探店内容。');
    expect(api.path, '/api/c/v1/user/expert-certification/apply');
    expect(applied.status, 1);
    expect(applied.statusText, '待审核');
    expect(applied.reason, '长期在巴黎写探店内容。');
  });
}
