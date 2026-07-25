import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/notification/notification_repository.dart';
import 'package:dazhongdianping_app/features/notification/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class NotificationScreenApi implements JsonApi {
  NotificationScreenApi({
    this.social = false,
    this.directMessage = false,
    this.postAudit = false,
    this.orderPaid = false,
    this.reservationCreated = false,
  });
  final bool social;
  final bool directMessage;
  final bool postAudit;
  final bool orderPaid;
  final bool reservationCreated;
  String? postedPath;

  Map<String, dynamic> _item({required bool read}) {
    if (social) {
      return {
        'id': 1,
        'type': 'social.follow',
        'actorUserId': 9,
        'actorName': '伦敦小王',
        'title': '新增关注',
        'content': '伦敦小王关注了你',
        'linkUrl': '/users/9',
        'aggregateCount': 1,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    if (directMessage) {
      return {
        'id': 1,
        'type': 'message.direct',
        'actorUserId': 9,
        'actorName': '巴黎小陈',
        'title': '收到私信',
        'content': '巴黎小陈：第二条私信提醒',
        'linkUrl': '/messages/conversations/7',
        'aggregateCount': 2,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    if (postAudit) {
      return {
        'id': 1,
        'type': 'post.audit.result',
        'actorUserId': null,
        'actorName': '',
        'title': '帖子已通过审核',
        'content': '《伦敦周末早午餐避坑指南》 已公开：内容真实，可公开',
        'linkUrl': '/community/posts/88?audit=approved',
        'aggregateCount': 1,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    if (orderPaid) {
      return {
        'id': 1,
        'type': 'order.paid',
        'actorUserId': null,
        'actorName': '',
        'title': '支付成功',
        'content': '双人套餐 · 订单 OD456 · 88.00 CNY · 券码已发放，可在我的券查看',
        'linkUrl': '/user/orders/99?paid=1',
        'aggregateCount': 1,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    if (reservationCreated) {
      return {
        'id': 1,
        'type': 'reservation.created',
        'actorUserId': null,
        'actorName': '',
        'title': '预订已自动确认',
        'content': '巴黎川菜馆 · 2026-07-26 18:00 · 2 人 · 系统已自动确认你的预订',
        'linkUrl': '/user/reservations/44?status=confirmed',
        'aggregateCount': 1,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    return {
      'id': 1,
      'type': 'review.reply',
      'actorUserId': null,
      'actorName': 'Maison Sichuan',
      'title': '商家回复',
      'content': '谢谢支持',
      'linkUrl': '/reviews/1',
      'aggregateCount': 1,
      'read': read,
      'createdAt': '2026-07-15 10:00:00',
    };
  }

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    return {
      'list': [_item(read: false)],
      'total': 1,
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postedPath = path;
    return _item(read: true);
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

  testWidgets(
    'post audit notification acknowledges then opens the post detail',
    (tester) async {
      final api = NotificationScreenApi(postAudit: true);
      int? openedPostId;
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationScreen(
            repository: NotificationRepository(api),
            onPostTap: (postId) => openedPostId = postId,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('帖子已通过审核'));
      await tester.pumpAndSettle();
      expect(api.postedPath, '/api/c/v1/notifications/1/ack');
      expect(openedPostId, 88);
    },
  );

  testWidgets(
    'payment success notification acknowledges then opens the order detail',
    (tester) async {
      final api = NotificationScreenApi(orderPaid: true);
      int? openedOrderId;
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationScreen(
            repository: NotificationRepository(api),
            onOrderTap: (orderId) => openedOrderId = orderId,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('支付成功'));
      await tester.pumpAndSettle();
      expect(api.postedPath, '/api/c/v1/notifications/1/ack');
      expect(openedOrderId, 99);
    },
  );

  testWidgets(
    'reservation created notification acknowledges then opens the reservation detail',
    (tester) async {
      final api = NotificationScreenApi(reservationCreated: true);
      int? openedReservationId;
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationScreen(
            repository: NotificationRepository(api),
            onReservationTap: (reservationId) =>
                openedReservationId = reservationId,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('预订已自动确认'));
      await tester.pumpAndSettle();
      expect(api.postedPath, '/api/c/v1/notifications/1/ack');
      expect(openedReservationId, 44);
    },
  );
}
