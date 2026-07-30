import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/session_store.dart';
import 'package:dazhongdianping_app/features/auth/auth_controller.dart';
import 'package:dazhongdianping_app/features/auth/auth_repository.dart';
import 'package:dazhongdianping_app/features/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class RegisterScreenApi implements JsonApi {
  String? path;
  Object? body;
  Object? sendCodeError;
  Object? registerError;
  int sendCodeRequests = 0;
  int registerRequests = 0;
  Completer<void>? sendCodeGate;
  Completer<void>? registerGate;

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
      sendCodeRequests++;
      await sendCodeGate?.future;
      if (sendCodeError != null) throw sendCodeError!;
      return {
        'sent': true,
        'expireSeconds': 300,
        'nextRetrySeconds': 60,
        'mockCode': '123456',
      };
    }
    registerRequests++;
    await registerGate?.future;
    if (registerError != null) throw registerError!;
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
  testWidgets('register screen sends a register verification code', (
    tester,
  ) async {
    final api = RegisterScreenApi();
    final controller = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      localizedApp(
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
      localizedApp(
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

  testWidgets('register screen localizes backend errors in English', (
    tester,
  ) async {
    final api = RegisterScreenApi()
      ..sendCodeError = const ApiException('验证码发送太频繁，请稍后再试')
      ..registerError = const ApiException('账号已注册');
    final controller = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: RegisterScreen(controller: controller, onAuthenticated: (_) {}),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('register-account')),
      'new@example.com',
    );
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Verification codes are being sent too often. Wait a bit and try again.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('验证码发送太频繁'), findsNothing);

    await tester.enterText(find.byKey(const Key('register-code')), '123456');
    await tester.enterText(
      find.byKey(const Key('register-password')),
      'Demo123456',
    );
    await tester.tap(find.text('Register and sign in'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'This account is already registered. Sign in or reset the password instead.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('账号已注册'), findsNothing);
  });

  testWidgets('register screen guards duplicate verification codes', (
    tester,
  ) async {
    final api = RegisterScreenApi()..sendCodeGate = Completer<void>();
    final controller = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      localizedApp(
        home: RegisterScreen(controller: controller, onAuthenticated: (_) {}),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('register-account')),
      'new@example.com',
    );

    final sendCode = find.text('发送验证码');
    await tester.tap(sendCode);
    await tester.tap(sendCode);

    expect(api.sendCodeRequests, 1);
    api.sendCodeGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('register screen guards duplicate submissions', (tester) async {
    final api = RegisterScreenApi()..registerGate = Completer<void>();
    final controller = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      localizedApp(
        home: RegisterScreen(controller: controller, onAuthenticated: (_) {}),
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

    final submit = find.text('注册并登录');
    await tester.tap(submit);
    await tester.tap(submit);

    expect(api.registerRequests, 1);
    api.registerGate!.complete();
    await tester.pumpAndSettle();
  });
}
