import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/user/growth_records_screen.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class GrowthRecordsApi implements JsonApi {
  GrowthRecordsApi({this.paginated = false});

  final bool paginated;
  bool failNextRecordsLoad = false;
  final List<int> requestedPages = [];

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
      final page = query?['page'] as int? ?? 1;
      requestedPages.add(page);
      if (failNextRecordsLoad) {
        failNextRecordsLoad = false;
        throw const ApiException('growth records network unavailable');
      }
      if (paginated) {
        return {
          'list': [
            {
              'id': page == 1 ? 1 : 2,
              'type': 1,
              'typeText': '成长值',
              'action': 'review_create',
              'actionText': page == 1 ? '发布点评' : '完善资料',
              'changeAmount': page == 1 ? 10 : 5,
              'balanceAfter': 230,
              'remark': '',
              'createdAt': '2026-07-25 18:00:00',
            },
            if (page == 2)
              {
                'id': 1,
                'type': 1,
                'typeText': '成长值',
                'action': 'review_create',
                'actionText': '发布点评',
                'changeAmount': 10,
                'balanceAfter': 230,
                'remark': '',
                'createdAt': '2026-07-25 18:00:00',
              },
          ],
          'total': 2,
          'page': page,
          'pageSize': 1,
          'hasMore': page == 1,
        };
      }
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
        home: GrowthRecordsScreen(
          repository: UserRepository(GrowthRecordsApi()),
        ),
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

  testWidgets('growth records load later pages without duplicate ids', (
    tester,
  ) async {
    final api = GrowthRecordsApi(paginated: true);
    await tester.pumpWidget(
      MaterialApp(home: GrowthRecordsScreen(repository: UserRepository(api))),
    );
    await tester.pumpAndSettle();

    expect(find.text('发布点评'), findsOneWidget);
    await tester.tap(find.text('加载更多'));
    await tester.pumpAndSettle();

    expect(api.requestedPages, [1, 2]);
    expect(find.text('发布点评'), findsOneWidget);
    expect(find.text('完善资料'), findsOneWidget);
  });

  testWidgets('failed growth records refresh preserves loaded entries', (
    tester,
  ) async {
    final api = GrowthRecordsApi();
    await tester.pumpWidget(
      MaterialApp(home: GrowthRecordsScreen(repository: UserRepository(api))),
    );
    await tester.pumpAndSettle();
    api.failNextRecordsLoad = true;

    await tester.drag(find.byType(ListView), const Offset(0, 320));
    await tester.pumpAndSettle();

    expect(find.text('发布点评'), findsNWidgets(2));
    expect(find.textContaining('刷新流水失败'), findsOneWidget);
    expect(api.requestedPages, [1, 1]);
  });
}
