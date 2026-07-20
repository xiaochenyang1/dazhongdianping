import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/notification/notification_repository.dart';
import 'package:dazhongdianping_app/features/notification/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class NotificationScreenApi implements JsonApi {
  NotificationScreenApi({this.social = false});
  final bool social;
  String? postedPath;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    return {
      'list': [
        {
          'id': 1,
          'type': social ? 'social.follow' : 'review.reply',
          'title': social ? '新增关注' : '商家回复',
          'content': social ? '伦敦小王关注了你' : '谢谢支持',
          'linkUrl': social ? '/users/9' : '/reviews/1',
          'read': false,
          'createdAt': '2026-07-15 10:00:00',
        },
      ],
      'total': 1,
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postedPath = path;
    return {
      'id': 1,
      'type': 'review.reply',
      'title': '商家回复',
      'content': '谢谢支持',
      'linkUrl': '/reviews/1',
      'read': true,
      'createdAt': '2026-07-15 10:00:00',
    };
  }
}

void main() {
  testWidgets('notification screen renders an unread message', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationScreen(
          repository: NotificationRepository(NotificationScreenApi()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('商家回复'), findsOneWidget);
    expect(find.text('谢谢支持'), findsOneWidget);
    expect(find.text('未读'), findsOneWidget);
  });

  testWidgets('tapping an unread message acknowledges it', (tester) async {
    final api = NotificationScreenApi();
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationScreen(repository: NotificationRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('商家回复'));
    await tester.pumpAndSettle();

    expect(api.postedPath, '/api/c/v1/notifications/1/ack');
    expect(find.text('未读'), findsNothing);
  });

  testWidgets(
    'social follow notification acknowledges then opens the public profile',
    (tester) async {
      final api = NotificationScreenApi(social: true);
      int? openedUserId;
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationScreen(
            repository: NotificationRepository(api),
            onUserTap: (userId) => openedUserId = userId,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('新增关注'));
      await tester.pumpAndSettle();
      expect(api.postedPath, '/api/c/v1/notifications/1/ack');
      expect(openedUserId, 9);
    },
  );
}
