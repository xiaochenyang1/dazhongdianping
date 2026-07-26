import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/auth/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class AuthFakeApi implements JsonApi {
  String? path;
  Object? body;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async => {};

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    this.path = path;
    this.body = body;
    if (path.endsWith('/login/password') || path.endsWith('/register')) {
      return {
        'accessToken': 'access-1',
        'refreshToken': 'refresh-1',
        'user': {
          'id': 1,
          'nickname': 'Demo',
          'avatar': '',
          'preferredRegion': 'EU',
        },
      };
    }
    if (path.endsWith('/auth/ban-appeals') ||
        path.endsWith('/auth/ban-appeals/query')) {
      return {
        'id': 88,
        'status': 0,
        'statusText': '待审核',
        'reason': '这是误封，我没有违规内容。',
        'rejectReason': '',
        'banReason': '多次违规',
        'submittedAt': '2026-07-26 10:00:00',
        'auditedAt': '',
      };
    }
    return {
      'sent': true,
      'expireSeconds': 300,
      'nextRetrySeconds': 60,
      'mockCode': '123456',
    };
  }
}

void main() {
  test('password login maps session response and payload', () async {
    final api = AuthFakeApi();
    final repository = AuthRepository(api);
    final session = await repository.loginWithPassword(
      account: 'demo@example.com',
      password: 'Demo123456',
    );

    expect(api.path, '/api/c/v1/auth/login/password');
    expect((api.body as Map)['account'], 'demo@example.com');
    expect(session.accessToken, 'access-1');
    expect(session.user.nickname, 'Demo');
  });

  test('registration maps session response and complete payload', () async {
    final api = AuthFakeApi();
    final repository = AuthRepository(api);

    final session = await repository.register(
      type: 'email',
      account: 'new@example.com',
      code: '123456',
      password: 'Demo123456',
      nickname: 'New User',
      preferredRegion: 'EU',
    );

    expect(api.path, '/api/c/v1/auth/register');
    expect(api.body, {
      'type': 'email',
      'account': 'new@example.com',
      'code': '123456',
      'password': 'Demo123456',
      'nickname': 'New User',
      'preferredRegion': 'EU',
    });
    expect(session.accessToken, 'access-1');
  });

  test('password reset sends the reset verification payload', () async {
    final api = AuthFakeApi();
    final repository = AuthRepository(api);

    await repository.resetPassword(
      type: 'phone',
      account: '+447700900999',
      code: '654321',
      newPassword: 'NewPass123',
    );

    expect(api.path, '/api/c/v1/auth/password/reset');
    expect(api.body, {
      'type': 'phone',
      'account': '+447700900999',
      'code': '654321',
      'newPassword': 'NewPass123',
    });
  });

  test('ban appeal submit and query map status responses', () async {
    final api = AuthFakeApi();
    final repository = AuthRepository(api);

    final submitted = await repository.submitBanAppeal(
      type: 'email',
      account: 'banned@example.com',
      code: '123456',
      reason: '这是误封，我没有违规内容。',
    );

    expect(api.path, '/api/c/v1/auth/ban-appeals');
    expect(api.body, {
      'type': 'email',
      'account': 'banned@example.com',
      'code': '123456',
      'reason': '这是误封，我没有违规内容。',
    });
    expect(submitted.id, 88);
    expect(submitted.status, 0);
    expect(submitted.statusText, '待审核');
    expect(submitted.isPending, isTrue);

    final queried = await repository.queryBanAppeal(
      type: 'email',
      account: 'banned@example.com',
      code: '654321',
    );

    expect(api.path, '/api/c/v1/auth/ban-appeals/query');
    expect(api.body, {
      'type': 'email',
      'account': 'banned@example.com',
      'code': '654321',
    });
    expect(queried.id, 88);
    expect(queried.statusText, '待审核');
  });
}
