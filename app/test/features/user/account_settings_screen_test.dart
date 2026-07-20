import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/user/account_settings_screen.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class AccountSettingsApi implements JsonApi, JsonMutationApi {
  String? path;
  Object? body;

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
    return profile();
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
    return profile(phone: '+447700900111');
  }

  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    this.path = path;
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
}
