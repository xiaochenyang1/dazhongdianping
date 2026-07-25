import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/user/expert_certification_screen.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ExpertCertApi implements JsonApi {
  String? path;
  Object? body;
  int status = 0;
  String reason = '';

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    this.path = path;
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
      'badge': status == 2
          ? {'code': 'local_expert', 'label': '本地达人'}
          : null,
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

void main() {
  testWidgets('expert certification screen can submit application', (
    tester,
  ) async {
    final api = ExpertCertApi();
    await tester.pumpWidget(
      MaterialApp(
        home: ExpertCertificationScreen(
          repository: UserRepository(api),
        ),
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
}
