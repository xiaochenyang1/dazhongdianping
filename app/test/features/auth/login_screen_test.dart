import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/session_store.dart';
import 'package:dazhongdianping_app/features/auth/auth_controller.dart';
import 'package:dazhongdianping_app/features/auth/auth_repository.dart';
import 'package:dazhongdianping_app/features/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class LoginFakeApi implements JsonApi {
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async => {};

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async => {
    'accessToken': 'access-login',
    'refreshToken': 'refresh-login',
    'user': {
      'id': 3,
      'nickname': 'Mobile User',
      'avatar': '',
      'preferredRegion': 'EU',
    },
  };
}

void main() {
  testWidgets('password login closes screen with authenticated user', (
    tester,
  ) async {
    final controller = AuthController(
      repository: AuthRepository(LoginFakeApi()),
      store: MemorySessionStore(),
    );
    AuthUser? result;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          controller: controller,
          onAuthenticated: (user) => result = user,
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('login-account')),
      'demo@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'Demo123456',
    );
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();

    expect(result?.nickname, 'Mobile User');
    expect(find.text('登录成功'), findsOneWidget);
  });

  testWidgets('login screen opens registration', (tester) async {
    final controller = AuthController(
      repository: AuthRepository(LoginFakeApi()),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(controller: controller, onAuthenticated: (_) {}),
      ),
    );

    await tester.tap(find.text('注册账号'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, '注册账号'), findsOneWidget);
  });

  testWidgets('login screen opens password reset', (tester) async {
    final controller = AuthController(
      repository: AuthRepository(LoginFakeApi()),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(controller: controller, onAuthenticated: (_) {}),
      ),
    );

    await tester.tap(find.text('忘记密码'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, '找回密码'), findsOneWidget);
  });
}
