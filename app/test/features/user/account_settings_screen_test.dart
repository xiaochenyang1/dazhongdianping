import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/user/account_settings_screen.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class AccountSettingsApi implements JsonApi, JsonMutationApi {
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
    return profile();
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    this.path = path;
    paths.add(path);
    this.body = body;
    if (path == '/api/c/v1/auth/send-code') {
      return {
        'sent': true,
        'expireSeconds': 300,
        'nextRetrySeconds': 60,
        'mockCode': '112233',
      };
    }
    return profile(phone: '+447700900111');
  }

  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    this.path = path;
    paths.add(path);
    this.body = body;
    return profile(nickname: 'Updated User');
  }
}

void main() {
  testWidgets('account settings renders profile and security sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
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
      MaterialApp(
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
      MaterialApp(home: AccountSettingsScreen(repository: UserRepository(api))),
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
}
