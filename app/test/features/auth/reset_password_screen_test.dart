import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/session_store.dart';
import 'package:dazhongdianping_app/features/auth/auth_controller.dart';
import 'package:dazhongdianping_app/features/auth/auth_repository.dart';
import 'package:dazhongdianping_app/features/auth/reset_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ResetScreenApi implements JsonApi {
  String? path;
  Object? body;
  int sendCodeRequests = 0;
  int resetRequests = 0;
  Completer<void>? sendCodeGate;
  Completer<void>? resetGate;

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
      return {
        'sent': true,
        'expireSeconds': 300,
        'nextRetrySeconds': 60,
        'mockCode': '654321',
      };
    }
    resetRequests++;
    await resetGate?.future;
    return {};
  }
}

void main() {
  testWidgets('reset password screen sends a reset verification code', (
    tester,
  ) async {
    final api = ResetScreenApi();
    final controller = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ResetPasswordScreen(controller: controller, onReset: () {}),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('reset-account')),
      '+447700900999',
    );
    await tester.tap(find.text('发送验证码'));
    await tester.pumpAndSettle();

    expect(api.path, '/api/c/v1/auth/send-code');
    expect(api.body, {
      'scene': 'reset',
      'type': 'phone',
      'account': '+447700900999',
      'deviceId': 'flutter-app',
    });
    expect(find.textContaining('654321'), findsOneWidget);
  });

  testWidgets('reset password screen submits matching new passwords', (
    tester,
  ) async {
    final api = ResetScreenApi();
    final controller = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    var reset = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ResetPasswordScreen(
          controller: controller,
          onReset: () => reset = true,
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('reset-account')),
      'user@example.com',
    );
    await tester.enterText(find.byKey(const Key('reset-code')), '654321');
    await tester.enterText(
      find.byKey(const Key('reset-password')),
      'NewPass123',
    );
    await tester.enterText(
      find.byKey(const Key('reset-confirm-password')),
      'NewPass123',
    );
    await tester.tap(find.text('重置密码'));
    await tester.pumpAndSettle();

    expect(api.path, '/api/c/v1/auth/password/reset');
    expect(api.body, {
      'type': 'email',
      'account': 'user@example.com',
      'code': '654321',
      'newPassword': 'NewPass123',
    });
    expect(reset, isTrue);
  });

  testWidgets('reset password screen rejects mismatched new passwords', (
    tester,
  ) async {
    final api = ResetScreenApi();
    final controller = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ResetPasswordScreen(controller: controller, onReset: () {}),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('reset-account')),
      'user@example.com',
    );
    await tester.enterText(find.byKey(const Key('reset-code')), '654321');
    await tester.enterText(
      find.byKey(const Key('reset-password')),
      'NewPass123',
    );
    await tester.enterText(
      find.byKey(const Key('reset-confirm-password')),
      'Different123',
    );
    await tester.tap(find.text('重置密码'));
    await tester.pumpAndSettle();

    expect(api.path, isNull);
    expect(find.text('两次输入的新密码对不上'), findsOneWidget);
  });

  testWidgets('reset password guards duplicate verification codes', (
    tester,
  ) async {
    final api = ResetScreenApi()..sendCodeGate = Completer<void>();
    final controller = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ResetPasswordScreen(controller: controller, onReset: () {}),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('reset-account')),
      'user@example.com',
    );

    final sendCode = find.text('发送验证码');
    await tester.tap(sendCode);
    await tester.tap(sendCode);

    expect(api.sendCodeRequests, 1);
    api.sendCodeGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('reset password guards duplicate submissions', (tester) async {
    final api = ResetScreenApi()..resetGate = Completer<void>();
    final controller = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    var resetCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ResetPasswordScreen(
          controller: controller,
          onReset: () => resetCalls++,
        ),
      ),
    );
    await tester.enterText(
      find.byKey(const Key('reset-account')),
      'user@example.com',
    );
    await tester.enterText(find.byKey(const Key('reset-code')), '654321');
    await tester.enterText(
      find.byKey(const Key('reset-password')),
      'NewPass123',
    );
    await tester.enterText(
      find.byKey(const Key('reset-confirm-password')),
      'NewPass123',
    );

    final submit = find.text('重置密码');
    await tester.tap(submit);
    await tester.tap(submit);

    expect(api.resetRequests, 1);
    api.resetGate!.complete();
    await tester.pumpAndSettle();
    expect(resetCalls, 1);
  });
}
