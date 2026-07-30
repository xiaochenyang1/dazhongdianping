import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/user/expert_certification_screen.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class ExpertCertApi implements JsonApi {
  String? path;
  Object? body;
  int status = 0;
  String reason = '';
  Object? loadError;
  Object? applyError;
  int failLoads = 0;
  int loadRequests = 0;
  Completer<void>? loadGate;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    this.path = path;
    loadRequests++;
    if (loadError != null) {
      throw loadError!;
    }
    if (failLoads > 0) {
      failLoads--;
      throw StateError('certification unavailable');
    }
    await loadGate?.future;
    return {
      'id': status == 0 ? 0 : 8801,
      'status': status,
      'statusText': switch (status) {
        1 => '待审核',
        2 => '已通过',
        3 => '已驳回',
        _ => '未申请',
      },
      'reason': reason,
      'rejectReason': status == 3 ? '内容贡献不足' : '',
      'badge': status == 2 ? {'code': 'local_expert', 'label': '本地达人'} : null,
      'submittedAt': status == 0 ? '' : '2026-07-25 19:00:00',
      'reviewedAt': status == 2 || status == 3 ? '2026-07-26 10:00:00' : '',
      'effectiveStartAt': status == 2 ? '2026-07-26 10:00:00' : '',
      'effectiveEndAt': '',
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    this.path = path;
    this.body = body;
    if (applyError != null) throw applyError!;
    status = 1;
    reason = (body as Map)['reason'] as String? ?? '';
    return {
      'id': 8801,
      'status': 1,
      'statusText': '待审核',
      'reason': reason,
      'rejectReason': '',
      'badge': null,
      'submittedAt': '2026-07-25 19:00:00',
      'reviewedAt': '',
      'effectiveStartAt': '',
      'effectiveEndAt': '',
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
  testWidgets('expert certification screen can submit application', (
    tester,
  ) async {
    final api = ExpertCertApi();
    await tester.pumpWidget(
      localizedApp(
        home: ExpertCertificationScreen(repository: UserRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('本地达人认证'), findsOneWidget);
    expect(find.text('未申请'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('expert-cert-reason')),
      '长期在巴黎写探店和避坑内容。',
    );
    await tester.tap(find.text('提交申请'));
    await tester.pumpAndSettle();

    expect(api.path, '/api/c/v1/user/expert-certification/apply');
    expect(find.text('待审核'), findsOneWidget);
    expect(find.text('申请审核中，请耐心等待结果。'), findsOneWidget);
  });

  testWidgets('expert certification retries an initial load failure', (
    tester,
  ) async {
    final api = ExpertCertApi()..failLoads = 1;
    await tester.pumpWidget(
      localizedApp(
        home: ExpertCertificationScreen(repository: UserRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('认证状态加载失败'), findsOneWidget);

    await tester.tap(find.byKey(const Key('expert-cert-retry')));
    await tester.pumpAndSettle();

    expect(find.text('未申请'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expert certification guards duplicate load retries', (
    tester,
  ) async {
    final gate = Completer<void>();
    final api = ExpertCertApi()
      ..failLoads = 1
      ..loadGate = gate;
    await tester.pumpWidget(
      localizedApp(
        home: ExpertCertificationScreen(repository: UserRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('expert-cert-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(api.loadRequests, 2);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.loadRequests, 2);
    expect(find.text('未申请'), findsOneWidget);
  });

  testWidgets('expert certification ignores a load completed after disposal', (
    tester,
  ) async {
    final gate = Completer<void>();
    final api = ExpertCertApi()
      ..reason = '已有的申请理由'
      ..loadGate = gate;
    await tester.pumpWidget(
      localizedApp(
        home: ExpertCertificationScreen(repository: UserRepository(api)),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(localizedApp(home: const SizedBox.shrink()));
    gate.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('expert certification localizes backend errors in English', (
    tester,
  ) async {
    final api = ExpertCertApi()
      ..applyError = const ApiException('当前已有待审核达人认证申请');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: ExpertCertificationScreen(repository: UserRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('expert-cert-reason')),
      'I regularly publish local reviews and practical neighborhood guides.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'You already have a local expert application under review. Wait for the current result first.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('待审核达人认证申请'), findsNothing);
  });

  testWidgets('expert certification localizes load errors in English', (
    tester,
  ) async {
    final api = ExpertCertApi()..loadError = const ApiException('用户登录状态不存在');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: ExpertCertificationScreen(repository: UserRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not load certification status: Your sign-in session is no longer available. Please sign in again.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('用户登录状态不存在'), findsNothing);
  });
}
