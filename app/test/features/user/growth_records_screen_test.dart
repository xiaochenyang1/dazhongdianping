import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/user/growth_records_screen.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class GrowthRecordsApi implements JsonApi {
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (path == '/api/c/v1/user/me') {
      return {
        'id': 8,
        'nickname': 'Growth User',
        'avatar': '',
        'email': 'growth@example.com',
        'phone': '',
        'hasPassword': true,
        'gender': 0,
        'signature': '',
        'preferredRegion': 'EU',
        'level': 3,
        'points': 95,
        'growthValue': 230,
      };
    }
    if (path == '/api/c/v1/user/growth/records') {
      return {
        'list': [
          {
            'id': 1,
            'type': 1,
            'typeText': '成长值',
            'action': 'review_create',
            'actionText': '发布点评',
            'bizId': 12,
            'changeAmount': 10,
            'balanceAfter': 230,
            'remark': '发点评奖励',
            'createdAt': '2026-07-25 18:00:00',
          },
          {
            'id': 2,
            'type': 2,
            'typeText': '积分',
            'action': 'review_create',
            'actionText': '发布点评',
            'bizId': 12,
            'changeAmount': 5,
            'balanceAfter': 95,
            'remark': '发点评奖励',
            'createdAt': '2026-07-25 18:00:00',
          },
        ],
        'total': 2,
        'page': 1,
        'pageSize': 20,
        'hasMore': false,
      };
    }
    return const {};
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      const {};
}

void main() {
  testWidgets('growth records screen renders profile and ledger entries', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GrowthRecordsScreen(repository: UserRepository(GrowthRecordsApi())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('成长值流水'), findsOneWidget);
    expect(find.text('Growth User'), findsOneWidget);
    expect(find.textContaining('成长值 230'), findsOneWidget);
    expect(find.text('发布点评'), findsNWidgets(2));
    expect(find.text('+10'), findsOneWidget);
    expect(find.text('+5'), findsOneWidget);
  });
}
