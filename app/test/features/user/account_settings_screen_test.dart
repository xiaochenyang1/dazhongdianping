import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/user/account_settings_screen.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class AccountSettingsApi implements JsonApi, JsonMutationApi {
  AccountSettingsApi({this.failFirst = false});

  final bool failFirst;
  Object? profileError;
  Object? saveProfileError;
  Object? sendBindCodeError;
  Object? bindError;
  Object? updatePasswordError;
  int profileRequests = 0;
  Completer<void>? retryGate;
  String? path;
  Object? body;
  final List<String> paths = [];

  Map<String, dynamic> profile({
    String nickname = 'EU User',
    String phone = '+33123456789',
  }) => {
    'id': 8,
    'nickname': nickname,
    'avatar': 'avatar.png',
    'email': 'eu@example.com',
    'phone': phone,
    'hasPassword': true,
    'gender': 2,
    'signature': 'Bonjour',
    'preferredRegion': 'EU',
    'level': 3,
    'points': 90,
    'growthValue': 220,
  };

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    this.path = path;
    paths.add(path);
    profileRequests++;
    if (profileError != null) {
      throw profileError!;
    }
    if (failFirst && profileRequests == 1) {
      throw StateError('network unavailable');
    }
    if (profileRequests > 1) await retryGate?.future;
    return profile();
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    this.path = path;
    paths.add(path);
    this.body = body;
    if (path == '/api/c/v1/auth/send-code') {
      if (sendBindCodeError != null) throw sendBindCodeError!;
      return {
        'sent': true,
        'expireSeconds': 300,
        'nextRetrySeconds': 60,
        'mockCode': '112233',
      };
    }
    if (path == '/api/c/v1/user/bind' && bindError != null) {
      throw bindError!;
    }
    return profile(phone: '+447700900111');
  }

  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    this.path = path;
    paths.add(path);
    this.body = body;
    if (path == '/api/c/v1/user/profile' && saveProfileError != null) {
      throw saveProfileError!;
    }
    if (path == '/api/c/v1/user/password' && updatePasswordError != null) {
      throw updatePasswordError!;
    }
    return profile(nickname: 'Updated User');
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
  testWidgets('account settings retries an initial profile failure', (
    tester,
  ) async {
    final api = AccountSettingsApi(failFirst: true);
    await tester.pumpWidget(
      localizedApp(
        home: AccountSettingsScreen(repository: UserRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('账户资料加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('account-settings-retry')));
    await tester.pumpAndSettle();

    expect(api.profileRequests, 2);
    expect(find.text('基础资料'), findsOneWidget);
  });

  testWidgets('account settings guards duplicate profile retries', (
    tester,
  ) async {
    final gate = Completer<void>();
    final api = AccountSettingsApi(failFirst: true)..retryGate = gate;
    await tester.pumpWidget(
      localizedApp(
        home: AccountSettingsScreen(repository: UserRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('account-settings-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(api.profileRequests, 2);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.profileRequests, 2);
    expect(find.text('基础资料'), findsOneWidget);
  });

  testWidgets('account settings renders profile and security sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        home: AccountSettingsScreen(
          repository: UserRepository(AccountSettingsApi()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('基础资料'), findsOneWidget);
    final signatureField = tester.widget<TextField>(
      find.byKey(const Key('settings-signature')),
    );
    expect(signatureField.controller?.text, 'Bonjour');
    await tester.scrollUntilVisible(
      find.text('账号绑定'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('账号绑定'), findsOneWidget);
    expect(find.textContaining('eu@example.com'), findsOneWidget);
    expect(find.textContaining('+33123456789'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('修改密码'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('修改密码'), findsOneWidget);
  });

  testWidgets('account settings saves profile and binds an account', (
    tester,
  ) async {
    final api = AccountSettingsApi();
    UserProfile? changedProfile;
    await tester.pumpWidget(
      localizedApp(
        home: AccountSettingsScreen(
          repository: UserRepository(api),
          onProfileChanged: (profile) => changedProfile = profile,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('settings-nickname')),
      'Updated User',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-save-profile')));
    await tester.pumpAndSettle();
    expect(api.path, '/api/c/v1/user/profile');
    expect((api.body as Map<String, dynamic>)['nickname'], 'Updated User');

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-confirm-bind')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('settings-bind-account')),
      '+447700900111',
    );
    await tester.tap(find.byKey(const Key('settings-send-bind-code')));
    await tester.pumpAndSettle();
    expect(api.path, '/api/c/v1/auth/send-code');
    expect(api.body, {
      'scene': 'bind',
      'type': 'email',
      'account': '+447700900111',
      'deviceId': 'flutter-app',
    });

    await tester.enterText(
      find.byKey(const Key('settings-bind-code')),
      '112233',
    );
    await tester.tap(find.byKey(const Key('settings-confirm-bind')));
    await tester.pumpAndSettle();
    expect(api.path, '/api/c/v1/user/bind');
    expect(changedProfile?.phone, '+447700900111');
  });

  testWidgets('account settings validates and updates password', (
    tester,
  ) async {
    final api = AccountSettingsApi();
    await tester.pumpWidget(
      localizedApp(
        home: AccountSettingsScreen(repository: UserRepository(api)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-update-password')),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.enterText(
      find.byKey(const Key('settings-old-password')),
      'old-password',
    );
    await tester.enterText(
      find.byKey(const Key('settings-new-password')),
      'new-password',
    );
    await tester.enterText(
      find.byKey(const Key('settings-confirm-password')),
      'different',
    );
    await tester.tap(find.byKey(const Key('settings-update-password')));
    await tester.pumpAndSettle();
    expect(find.text('两次输入的新密码不一致'), findsOneWidget);
    expect(api.paths, isNot(contains('/api/c/v1/user/password')));

    await tester.enterText(
      find.byKey(const Key('settings-confirm-password')),
      'new-password',
    );
    await tester.tap(find.byKey(const Key('settings-update-password')));
    await tester.pumpAndSettle();
    expect(api.path, '/api/c/v1/user/password');
    expect(api.body, {
      'oldPassword': 'old-password',
      'newPassword': 'new-password',
    });
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('settings-new-password')))
          .controller
          ?.text,
      isEmpty,
    );
  });

  testWidgets('account settings localizes auth backend errors in English', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = AccountSettingsApi()
      ..saveProfileError = const ApiException('nickname 不能超过 64 字')
      ..sendBindCodeError = const ApiException('验证码发送太频繁，请稍后再试')
      ..bindError = const ApiException('该邮箱已被其他账号绑定')
      ..updatePasswordError = const ApiException('旧密码不正确');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: AccountSettingsScreen(repository: UserRepository(api)),
      ),
    );
    await tester.pumpAndSettle();
    final messenger = tester.state<ScaffoldMessengerState>(
      find.byType(ScaffoldMessenger),
    );

    await tester.tap(find.byKey(const Key('settings-save-profile')));
    await tester.pump();
    expect(
      find.text(
        'Could not save profile: Nickname must be 64 characters or fewer.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('nickname 不能超过 64 字'), findsNothing);
    messenger.removeCurrentSnackBar();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-confirm-bind')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('settings-bind-account')),
      'other@example.com',
    );
    await tester.tap(find.byKey(const Key('settings-send-bind-code')));
    await tester.pump();
    expect(
      find.text(
        'Could not send code: Verification codes are being sent too often. Wait a bit and try again.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('验证码发送太频繁'), findsNothing);
    messenger.removeCurrentSnackBar();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('settings-bind-code')),
      '112233',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-confirm-bind')));
    await tester.pump();
    expect(api.path, '/api/c/v1/user/bind');
    expect(
      find.text(
        'Could not bind account: This email is already bound to another account.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('其他账号绑定'), findsNothing);
    messenger.removeCurrentSnackBar();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-update-password')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const Key('settings-old-password')),
      'wrong-old-password',
    );
    await tester.enterText(
      find.byKey(const Key('settings-new-password')),
      'new-password',
    );
    await tester.enterText(
      find.byKey(const Key('settings-confirm-password')),
      'new-password',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-update-password')));
    await tester.pump();
    expect(
      find.text(
        'Could not update password: The current password is incorrect.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('旧密码不正确'), findsNothing);
  });

  testWidgets('account settings localizes profile load errors in English', (
    tester,
  ) async {
    final api = AccountSettingsApi()
      ..profileError = const ApiException('用户不存在');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: AccountSettingsScreen(repository: UserRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not load account profile: Your account could not be found. Please sign in again.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('用户不存在'), findsNothing);
  });
}
