import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/session_store.dart';
import 'package:dazhongdianping_app/features/auth/auth_controller.dart';
import 'package:dazhongdianping_app/features/auth/auth_repository.dart';
import 'package:dazhongdianping_app/features/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class LoginFakeApi implements JsonApi {
  LoginFakeApi({this.banOnLogin = false});

  final bool banOnLogin;
  int sendCodeRequests = 0;
  int loginRequests = 0;
  Completer<void>? sendCodeGate;
  Completer<void>? loginGate;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async => {};

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    if (path.endsWith('/send-code')) {
      sendCodeRequests++;
      await sendCodeGate?.future;
      return {
        'sent': true,
        'expireSeconds': 300,
        'nextRetrySeconds': 60,
        'mockCode': '123456',
      };
    }
    loginRequests++;
    await loginGate?.future;
    if (banOnLogin && path.endsWith('/login/password')) {
      throw const ApiException(
        '账号已被封禁',
        statusCode: 401,
        messageKey: 'auth.user_banned',
      );
    }
    return {
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
}


Widget localizedApp({
  required Widget home,
  Locale locale = const Locale('zh', 'CN'),
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );
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
      localizedApp(
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
      localizedApp(
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
      localizedApp(
        home: LoginScreen(controller: controller, onAuthenticated: (_) {}),
      ),
    );

    await tester.tap(find.text('忘记密码'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, '找回密码'), findsOneWidget);
  });

  testWidgets('banned login surfaces appeal entry and opens appeal screen', (
    tester,
  ) async {
    final controller = AuthController(
      repository: AuthRepository(LoginFakeApi(banOnLogin: true)),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      localizedApp(
        home: LoginScreen(controller: controller, onAuthenticated: (_) {}),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('login-account')),
      'banned@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'Demo123456',
    );
    await tester.tap(find.text('登录'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-ban-appeal-cta')), findsOneWidget);
    expect(find.textContaining('banned@example.com'), findsWidgets);

    await tester.tap(find.byKey(const Key('login-open-ban-appeal')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, '封禁申诉'), findsOneWidget);
    expect(find.byKey(const Key('appeal-account')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('appeal-account')))
          .controller
          ?.text,
      'banned@example.com',
    );
  });

  testWidgets('login screen opens ban appeal entry directly', (tester) async {
    final controller = AuthController(
      repository: AuthRepository(LoginFakeApi()),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      localizedApp(
        home: LoginScreen(controller: controller, onAuthenticated: (_) {}),
      ),
    );

    await tester.tap(find.byKey(const Key('login-ban-appeal-entry')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, '封禁申诉'), findsOneWidget);
  });

  testWidgets('login screen guards duplicate verification codes', (
    tester,
  ) async {
    final api = LoginFakeApi()..sendCodeGate = Completer<void>();
    final controller = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      localizedApp(
        home: LoginScreen(controller: controller, onAuthenticated: (_) {}),
      ),
    );
    await tester.tap(find.text('验证码登录'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('login-account')),
      'demo@example.com',
    );

    final sendCode = find.text('发送验证码');
    await tester.tap(sendCode);
    await tester.tap(sendCode);

    expect(api.sendCodeRequests, 1);
    api.sendCodeGate!.complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('123456'), findsOneWidget);
  });

  testWidgets('login screen guards duplicate submissions', (tester) async {
    final api = LoginFakeApi()..loginGate = Completer<void>();
    final controller = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    var authenticatedCalls = 0;
    await tester.pumpWidget(
      localizedApp(
        home: LoginScreen(
          controller: controller,
          onAuthenticated: (_) => authenticatedCalls++,
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

    final login = find.text('登录');
    await tester.tap(login);
    await tester.tap(login);

    expect(api.loginRequests, 1);
    api.loginGate!.complete();
    await tester.pumpAndSettle();
    expect(authenticatedCalls, 1);
  });
}
