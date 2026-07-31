import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/session_store.dart';
import 'package:dazhongdianping_app/features/auth/auth_controller.dart';
import 'package:dazhongdianping_app/features/auth/auth_repository.dart';
import 'package:dazhongdianping_app/features/auth/ban_appeal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class BanAppealFakeApi implements JsonApi {
  String? path;
  Object? body;
  int status = 0;
  String statusText = '待审核';
  Object? sendCodeError;
  Object? submitError;
  Object? queryError;
  int sendCodeRequests = 0;
  int submitRequests = 0;
  int queryRequests = 0;
  Completer<void>? sendCodeGate;
  Completer<void>? submitGate;
  Completer<void>? queryGate;

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
        'mockCode': '112233',
      };
    }
    if (path.endsWith('/auth/ban-appeals/query')) {
      queryRequests++;
      await queryGate?.future;
      if (queryError != null) throw queryError!;
      return {
        'id': 91,
        'status': 1,
        'statusText': '已通过',
        'reason': '这是误封，我没有违规内容。',
        'rejectReason': '',
        'banReason': '多次违规',
        'submittedAt': '2026-07-26 10:00:00',
        'auditedAt': '2026-07-26 12:00:00',
      };
    }
    submitRequests++;
    await submitGate?.future;
    if (submitError != null) throw submitError!;
    return {
      'id': 91,
      'status': status,
      'statusText': statusText,
      'reason': (body as Map)['reason'] as String? ?? '',
      'rejectReason': '',
      'banReason': '多次违规',
      'submittedAt': '2026-07-26 10:00:00',
      'auditedAt': '',
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
  testWidgets('ban appeal screen localizes status labels in English', (
    tester,
  ) async {
    final api = BanAppealFakeApi();
    final controller = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: BanAppealScreen(
          controller: controller,
          initialAccount: 'banned@example.com',
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('appeal-code')), '112233');
    await tester.enterText(
      find.byKey(const Key('appeal-reason')),
      'This ban was a mistake and should be reviewed again.',
    );
    await tester.tap(find.byKey(const Key('appeal-submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Pending review'), findsOneWidget);
    expect(find.text('Submitted: 26/07/2026 10:00'), findsOneWidget);
    expect(find.textContaining('待审核'), findsNothing);
  });

  testWidgets('ban appeal screen localizes backend errors in English', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = BanAppealFakeApi()
      ..sendCodeError = const ApiException('手机号格式不合法')
      ..submitError = const ApiException('已有申诉正在处理中，请耐心等待审核结果')
      ..queryError = const ApiException('该账号暂无申诉记录');
    final controller = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: BanAppealScreen(controller: controller, initialAccount: '123'),
      ),
    );

    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'The phone number format looks invalid. Check it and try again.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('手机号格式不合法'), findsNothing);

    await tester.enterText(find.byKey(const Key('appeal-code')), '112233');
    await tester.enterText(
      find.byKey(const Key('appeal-reason')),
      'This account was banned by mistake and needs a manual review.',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('appeal-submit')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('appeal-submit')));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'You already have an appeal under review. Wait for the result before submitting another.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('已有申诉正在处理中'), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const Key('appeal-query')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('appeal-query')));
    await tester.pumpAndSettle();
    expect(
      find.text('No appeal record was found for this account yet.'),
      findsOneWidget,
    );
    expect(find.textContaining('暂无申诉记录'), findsNothing);
  });

  testWidgets('ban appeal screen sends appeal verification code', (
    tester,
  ) async {
    final api = BanAppealFakeApi();
    final controller = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      localizedApp(
        home: BanAppealScreen(
          controller: controller,
          initialAccount: 'banned@example.com',
        ),
      ),
    );

    await tester.tap(find.text('发送验证码'));
    await tester.pumpAndSettle();

    expect(api.path, '/api/c/v1/auth/send-code');
    expect(api.body, {
      'scene': 'appeal',
      'type': 'email',
      'account': 'banned@example.com',
      'deviceId': 'flutter-app',
    });
    expect(find.textContaining('112233'), findsOneWidget);
  });

  testWidgets('ban appeal screen validates reason length', (tester) async {
    final api = BanAppealFakeApi();
    final controller = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      localizedApp(
        home: BanAppealScreen(
          controller: controller,
          initialAccount: 'banned@example.com',
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('appeal-code')), '112233');
    await tester.enterText(find.byKey(const Key('appeal-reason')), '太短');
    await tester.tap(find.byKey(const Key('appeal-submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('至少写 10 个字'), findsOneWidget);
    expect(api.path, isNull);
  });

  testWidgets('ban appeal screen submits and queries progress', (tester) async {
    final api = BanAppealFakeApi();
    final controller = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      localizedApp(
        home: BanAppealScreen(
          controller: controller,
          initialAccount: 'banned@example.com',
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('appeal-code')), '112233');
    await tester.enterText(
      find.byKey(const Key('appeal-reason')),
      '这是误封，我没有违规内容。',
    );
    await tester.tap(find.byKey(const Key('appeal-submit')));
    await tester.pumpAndSettle();

    expect(api.path, '/api/c/v1/auth/ban-appeals');
    expect(api.body, {
      'type': 'email',
      'account': 'banned@example.com',
      'code': '112233',
      'reason': '这是误封，我没有违规内容。',
    });
    expect(find.byKey(const Key('appeal-status-card')), findsOneWidget);
    expect(find.byKey(const Key('appeal-success')), findsOneWidget);
    expect(find.textContaining('待审核'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('appeal-code')), '998877');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('appeal-query')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('appeal-query')));
    await tester.pumpAndSettle();

    expect(api.path, '/api/c/v1/auth/ban-appeals/query');
    expect(find.textContaining('已通过'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const Key('appeal-back-login')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('appeal-back-login')), findsOneWidget);
  });

  testWidgets('ban appeal guards duplicate verification codes', (tester) async {
    final api = BanAppealFakeApi()..sendCodeGate = Completer<void>();
    final controller = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      localizedApp(
        home: BanAppealScreen(
          controller: controller,
          initialAccount: 'banned@example.com',
        ),
      ),
    );

    final sendCode = find.text('发送验证码');
    await tester.tap(sendCode);
    await tester.tap(sendCode);

    expect(api.sendCodeRequests, 1);
    api.sendCodeGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('ban appeal guards duplicate submissions', (tester) async {
    final api = BanAppealFakeApi()..submitGate = Completer<void>();
    final controller = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      localizedApp(
        home: BanAppealScreen(
          controller: controller,
          initialAccount: 'banned@example.com',
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('appeal-code')), '112233');
    await tester.enterText(
      find.byKey(const Key('appeal-reason')),
      '这是误封，我没有违规内容。',
    );
    final submit = find.byKey(const Key('appeal-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.tap(submit);

    expect(api.submitRequests, 1);
    api.submitGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('ban appeal guards duplicate progress queries', (tester) async {
    final api = BanAppealFakeApi()..queryGate = Completer<void>();
    final controller = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      localizedApp(
        home: BanAppealScreen(
          controller: controller,
          initialAccount: 'banned@example.com',
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('appeal-code')), '998877');
    final query = find.byKey(const Key('appeal-query'));
    await tester.ensureVisible(query);
    await tester.tap(query);
    await tester.tap(query);

    expect(api.queryRequests, 1);
    api.queryGate!.complete();
    await tester.pumpAndSettle();
  });
}
