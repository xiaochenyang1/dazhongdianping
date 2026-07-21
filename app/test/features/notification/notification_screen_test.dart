import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/notification/notification_repository.dart';
import 'package:dazhongdianping_app/features/notification/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class NotificationScreenApi implements JsonApi {
  NotificationScreenApi({this.social = false, this.directMessage = false});
  final bool social;
  final bool directMessage;
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
          'type': social
              ? 'social.follow'
              : (directMessage ? 'message.direct' : 'review.reply'),
          'actorUserId': social || directMessage ? 9 : null,
          'actorName': social
              ? '伦敦小王'
              : (directMessage ? '巴黎小陈' : 'Maison Sichuan'),
          'title': social ? '新增关注' : (directMessage ? '收到私信' : '商家回复'),
          'content': social
              ? '伦敦小王关注了你'
              : (directMessage ? '巴黎小陈：第二条私信提醒' : '谢谢支持'),
          'linkUrl': social
              ? '/users/9'
              : (directMessage ? '/messages/conversations/7' : '/reviews/1'),
          'aggregateCount': directMessage ? 2 : 1,
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
      'type': social
          ? 'social.follow'
          : (directMessage ? 'message.direct' : 'review.reply'),
      'actorUserId': social || directMessage ? 9 : null,
      'actorName': social
          ? '伦敦小王'
          : (directMessage ? '巴黎小陈' : 'Maison Sichuan'),
      'title': social ? '新增关注' : (directMessage ? '收到私信' : '商家回复'),
      'content': social
          ? '伦敦小王关注了你'
          : (directMessage ? '巴黎小陈：第二条私信提醒' : '谢谢支持'),
      'linkUrl': social
          ? '/users/9'
          : (directMessage ? '/messages/conversations/7' : '/reviews/1'),
      'aggregateCount': directMessage ? 2 : 1,
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

  testWidgets('notification screen renders aggregate count badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationScreen(
          repository: NotificationRepository(
            NotificationScreenApi(directMessage: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('收到私信'), findsOneWidget);
    expect(find.text('x2'), findsOneWidget);
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

  testWidgets('direct message notification opens the conversation callback', (
    tester,
  ) async {
    final api = NotificationScreenApi(directMessage: true);
    int? openedConversationId;
    int? openedPeerUserId;
    String? openedPeerName;

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationScreen(
          repository: NotificationRepository(api),
          onConversationTap: (conversationId, peerUserId, peerName) {
            openedConversationId = conversationId;
            openedPeerUserId = peerUserId;
            openedPeerName = peerName;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('收到私信'));
    await tester.pumpAndSettle();

    expect(api.postedPath, '/api/c/v1/notifications/1/ack');
    expect(openedConversationId, 7);
    expect(openedPeerUserId, 9);
    expect(openedPeerName, '巴黎小陈');
  });
}
