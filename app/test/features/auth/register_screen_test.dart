import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/session_store.dart';
import 'package:dazhongdianping_app/features/auth/auth_controller.dart';
import 'package:dazhongdianping_app/features/auth/auth_repository.dart';
import 'package:dazhongdianping_app/features/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class RegisterScreenApi implements JsonApi {
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
    if (path.endsWith('/send-code')) {
      return {
        'sent': true,
        'expireSeconds': 300,
        'nextRetrySeconds': 60,
        'mockCode': '123456',
      };
    }
    return {
      'accessToken': 'register-access',
      'refreshToken': 'register-refresh',
      'user': {
        'id': 12,
        'nickname': 'New User',
        'avatar': '',
        'preferredRegion': 'EU',
      },
    };
  }
}

void main() {
  testWidgets('register screen sends a register verification code', (
    tester,
  ) async {
    final api = RegisterScreenApi();
    final controller = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterScreen(controller: controller, onAuthenticated: (_) {}),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('register-account')),
      'new@example.com',
    );
    await tester.tap(find.text('发送验证码'));
    await tester.pumpAndSettle();

    expect(api.path, '/api/c/v1/auth/send-code');
    expect(api.body, {
      'scene': 'register',
      'type': 'email',
      'account': 'new@example.com',
      'deviceId': 'flutter-app',
    });
    expect(find.textContaining('123456'), findsOneWidget);
  });

  testWidgets('register screen creates a session and authenticates user', (
    tester,
  ) async {
    final api = RegisterScreenApi();
    final controller = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    AuthUser? authenticated;
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterScreen(
          controller: controller,
          onAuthenticated: (user) => authenticated = user,
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('register-account')),
      'new@example.com',
    );
    await tester.enterText(find.byKey(const Key('register-code')), '123456');
    await tester.enterText(
      find.byKey(const Key('register-password')),
      'Demo123456',
    );
    await tester.enterText(
      find.byKey(const Key('register-nickname')),
      'New User',
    );
    await tester.tap(find.text('注册并登录'));
    await tester.pumpAndSettle();

    expect(api.path, '/api/c/v1/auth/register');
    expect(authenticated?.nickname, 'New User');
    expect(controller.currentUser?.id, 12);
  });
}
