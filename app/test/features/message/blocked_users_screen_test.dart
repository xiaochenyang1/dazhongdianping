import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/message/blocked_users_screen.dart';
import 'package:dazhongdianping_app/features/message/message_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class BlockedUsersFakeApi implements JsonApi, JsonDeleteApi {
  final List<int> pages = [];
  final List<int> unblockedUsers = [];
  bool failNextLoad = false;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    final page = query?['page'] as int? ?? 1;
    pages.add(page);
    if (failNextLoad) {
      failNextLoad = false;
      throw Exception('blocked users network unavailable');
    }
    return {
      'list': [
        {
          'id': page == 1 ? 9 : 10,
          'nickname': page == 1 ? '伦敦小王' : '巴黎小李',
          'avatar': '',
          'blockedAt': '2026-07-26 12:00:00',
        },
      ],
      'total': 2,
      'page': page,
      'pageSize': 1,
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      {};

  @override
  Future<Map<String, dynamic>> deleteJson(String path) async {
    final userId = int.parse(path.split('/').last);
    unblockedUsers.add(userId);
    return {'userId': userId, 'blocked': false};
  }
}

void main() {
  testWidgets('blocked users load later pages and unblock a user', (
    tester,
  ) async {
    final api = BlockedUsersFakeApi();
    await tester.pumpWidget(
      MaterialApp(home: BlockedUsersScreen(repository: MessageRepository(api))),
    );
    await tester.pumpAndSettle();

    expect(find.text('伦敦小王'), findsOneWidget);
    await tester.tap(find.text('加载更多'));
    await tester.pumpAndSettle();
    expect(api.pages, [1, 2]);
    expect(find.text('巴黎小李'), findsOneWidget);

    await tester.tap(find.text('解除拉黑').first);
    await tester.pumpAndSettle();
    expect(api.unblockedUsers, [9]);
    expect(find.text('伦敦小王'), findsNothing);
    expect(find.text('巴黎小李'), findsOneWidget);
  });

  testWidgets('blocked users retry an initial load failure', (tester) async {
    final api = BlockedUsersFakeApi()..failNextLoad = true;
    await tester.pumpWidget(
      MaterialApp(home: BlockedUsersScreen(repository: MessageRepository(api))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('黑名单加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('blocked-users-retry')));
    await tester.pumpAndSettle();

    expect(api.pages, [1, 1]);
    expect(find.text('伦敦小王'), findsOneWidget);
    expect(find.textContaining('黑名单加载失败'), findsNothing);
  });

  testWidgets('failed blocked users refresh preserves loaded items', (
    tester,
  ) async {
    final api = BlockedUsersFakeApi();
    await tester.pumpWidget(
      MaterialApp(home: BlockedUsersScreen(repository: MessageRepository(api))),
    );
    await tester.pumpAndSettle();
    api.failNextLoad = true;

    await tester.drag(find.byType(ListView), const Offset(0, 320));
    await tester.pumpAndSettle();

    expect(find.text('伦敦小王'), findsOneWidget);
    expect(find.textContaining('刷新黑名单失败'), findsOneWidget);
    expect(api.pages, [1, 1]);
  });
}
