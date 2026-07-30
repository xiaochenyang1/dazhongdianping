import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/notification/notification_repository.dart';
import 'package:dazhongdianping_app/features/notification/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

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

Future<void> expectEnglishNotification(
  WidgetTester tester, {
  required NotificationScreenApi api,
  required String expectedTitle,
  required String expectedContent,
}) async {
  await tester.pumpWidget(
    localizedApp(
      locale: const Locale('en'),
      home: NotificationScreen(
        key: ValueKey(expectedTitle),
        repository: NotificationRepository(api),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text(expectedTitle), findsOneWidget);
  expect(find.text(expectedContent), findsOneWidget);
}

class NotificationScreenApi implements JsonApi {
  NotificationScreenApi({
    this.social = false,
    this.directMessage = false,
    this.postAudit = false,
    this.orderPaid = false,
    this.reservationCreated = false,
    this.couponReminder = false,
    this.couponVerified = false,
    this.expertResult = false,
    this.failFirstLoad = false,
    this.mixedRead = false,
    this.twoUnread = false,
    this.empty = false,
    this.paginated = false,
    this.paginatedFirstUnread = false,
  });
  final bool social;
  final bool directMessage;
  final bool postAudit;
  final bool orderPaid;
  final bool reservationCreated;
  final bool couponReminder;
  final bool couponVerified;
  final bool expertResult;
  final bool failFirstLoad;
  final bool mixedRead;
  final bool twoUnread;
  final bool empty;
  final bool paginated;
  final bool paginatedFirstUnread;
  String? postedPath;
  int loadCount = 0;
  final requestedPages = <int>[];
  bool failNextLoad = false;
  Completer<void>? ackGate;
  final ackGates = <int, Completer<void>>{};
  final loadGates = <int, Completer<void>>{};
  int ackCalls = 0;
  Completer<void>? loadMoreGate;
  int markAllCalls = 0;

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
    if (couponReminder) {
      return {
        'id': 1,
        'type': 'coupon.reminder',
        'actorUserId': null,
        'actorName': '',
        'title': '券码即将到期',
        'content': 'CP-DEMO 将在 1 天后过期',
        'linkUrl': '/user/coupons?status=1&code=CP-DEMO&remind=1',
        'aggregateCount': 1,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    if (couponVerified) {
      return {
        'id': 1,
        'type': 'coupon.verified',
        'actorUserId': null,
        'actorName': '',
        'title': '券码已核销',
        'content': 'CP-DEMO 已在柏林茶馆核销',
        'linkUrl': '/user/coupons/CP-DEMO',
        'aggregateCount': 1,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    if (expertResult) {
      return {
        'id': 1,
        'type': 'expert.certification.result',
        'actorUserId': null,
        'actorName': '',
        'title': '本地达人认证已通过',
        'content': '你的本地达人认证已审核通过',
        'linkUrl': '/user/profile?expert=approved',
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
    loadCount += 1;
    final page = query?['page'] as int? ?? 1;
    requestedPages.add(page);
    await loadGates[loadCount]?.future;
    if (failNextLoad) {
      failNextLoad = false;
      throw const ApiException('刷新网络暂时不可用');
    }
    if (failFirstLoad && loadCount == 1) {
      throw const ApiException('网络暂时不可用');
    }
    if (empty) {
      return {'list': const [], 'total': 0};
    }
    if (paginated) {
      if (page > 1) await loadMoreGate?.future;
      return {
        'list': [
          {
            ..._item(read: paginatedFirstUnread ? false : page == 1),
            'id': page,
            'title': page == 1 ? '已读新通知' : '更早未读通知',
          },
        ],
        'total': 2,
      };
    }
    if (mixedRead) {
      return {
        'list': [
          _item(read: false),
          {..._item(read: true), 'id': 2, 'title': '已读通知'},
        ],
        'total': 2,
      };
    }
    if (twoUnread) {
      return {
        'list': [
          _item(read: false),
          {..._item(read: false), 'id': 2, 'title': '第二条未读通知'},
        ],
        'total': 2,
      };
    }
    return {
      'list': [_item(read: false)],
      'total': 1,
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postedPath = path;
    if (path == '/api/c/v1/notifications/read-all') {
      markAllCalls += 1;
      return {'updated': 1, 'count': 0};
    }
    ackCalls += 1;
    final id = int.parse(path.split('/').reversed.elementAt(1));
    await ackGate?.future;
    await ackGates[id]?.future;
    return {..._item(read: true), 'id': id};
  }
}

void main() {
  testWidgets('notification screen switches English chrome', (tester) async {
    final api = NotificationScreenApi(mixedRead: true);
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: NotificationScreen(repository: NotificationRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Unread only'), findsOneWidget);
    expect(find.text('Unread'), findsOneWidget);
    expect(find.text('Mark all read (1)'), findsOneWidget);
    expect(find.text('Merchant reply'), findsOneWidget);
    expect(find.text('已读通知'), findsOneWidget);
  });

  testWidgets(
    'notification screen localizes supported notifications in English',
    (tester) async {
      await expectEnglishNotification(
        tester,
        api: NotificationScreenApi(social: true),
        expectedTitle: 'New follower',
        expectedContent: '伦敦小王 followed you',
      );
      await expectEnglishNotification(
        tester,
        api: NotificationScreenApi(directMessage: true),
        expectedTitle: 'New direct message',
        expectedContent: '巴黎小陈: 第二条私信提醒',
      );
      await expectEnglishNotification(
        tester,
        api: NotificationScreenApi(postAudit: true),
        expectedTitle: 'Post approved',
        expectedContent: '"伦敦周末早午餐避坑指南" is now public: 内容真实，可公开',
      );
      await expectEnglishNotification(
        tester,
        api: NotificationScreenApi(orderPaid: true),
        expectedTitle: 'Payment successful',
        expectedContent:
            '双人套餐 · Order OD456 · 88.00 CNY · Coupons are ready in My coupons',
      );
      await expectEnglishNotification(
        tester,
        api: NotificationScreenApi(reservationCreated: true),
        expectedTitle: 'Reservation auto-confirmed',
        expectedContent:
            '巴黎川菜馆 · 2026-07-26 18:00 · 2 guests · Your reservation was automatically confirmed',
      );
      await expectEnglishNotification(
        tester,
        api: NotificationScreenApi(couponReminder: true),
        expectedTitle: 'Coupon reminder',
        expectedContent: 'CP-DEMO expires in 1 day',
      );
      await expectEnglishNotification(
        tester,
        api: NotificationScreenApi(couponVerified: true),
        expectedTitle: 'Coupon redeemed',
        expectedContent: 'CP-DEMO was redeemed at 柏林茶馆',
      );
      await expectEnglishNotification(
        tester,
        api: NotificationScreenApi(expertResult: true),
        expectedTitle: 'Local expert certification approved',
        expectedContent: 'Your local expert certification was approved',
      );
      await expectEnglishNotification(
        tester,
        api: NotificationScreenApi(),
        expectedTitle: 'Merchant reply',
        expectedContent: '谢谢支持',
      );
    },
  );

  testWidgets('notification screen filters unread messages locally', (
    tester,
  ) async {
    final api = NotificationScreenApi(mixedRead: true);
    await tester.pumpWidget(
      localizedApp(
        home: NotificationScreen(repository: NotificationRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('商家回复'), findsOneWidget);
    expect(find.text('已读通知'), findsOneWidget);

    await tester.tap(find.text('只看未读'));
    await tester.pumpAndSettle();

    expect(find.text('商家回复'), findsOneWidget);
    expect(find.text('已读通知'), findsNothing);
  });

  testWidgets('notification screen retries after an initial load failure', (
    tester,
  ) async {
    final api = NotificationScreenApi(failFirstLoad: true);
    await tester.pumpWidget(
      localizedApp(
        home: NotificationScreen(repository: NotificationRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('网络暂时不可用'), findsOneWidget);
    await tester.tap(find.byKey(const Key('notifications-retry')));
    await tester.pumpAndSettle();

    expect(api.loadCount, 2);
    expect(find.text('商家回复'), findsOneWidget);
  });

  testWidgets('notification screen guards duplicate retries', (tester) async {
    final gate = Completer<void>();
    final api = NotificationScreenApi(failFirstLoad: true);
    await tester.pumpWidget(
      localizedApp(
        home: NotificationScreen(repository: NotificationRepository(api)),
      ),
    );
    await tester.pumpAndSettle();
    api.loadGates[2] = gate;

    final retry = find.byKey(const Key('notifications-retry'));
    await tester.tap(retry);
    await tester.tap(retry);
    await tester.pump();

    expect(api.loadCount, 2);
    expect(find.text('处理中...'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.loadCount, 2);
    expect(find.text('商家回复'), findsOneWidget);
  });

  testWidgets('pull to refresh reloads notifications', (tester) async {
    final api = NotificationScreenApi();
    await tester.pumpWidget(
      localizedApp(
        home: NotificationScreen(repository: NotificationRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(
      find.byKey(const Key('notification-list')),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    expect(api.loadCount, 2);
    expect(find.text('商家回复'), findsOneWidget);
  });

  testWidgets('failed notification refresh preserves loaded messages', (
    tester,
  ) async {
    final api = NotificationScreenApi();
    await tester.pumpWidget(
      localizedApp(
        home: NotificationScreen(repository: NotificationRepository(api)),
      ),
    );
    await tester.pumpAndSettle();
    api.failNextLoad = true;

    await tester.fling(
      find.byKey(const Key('notification-list')),
      const Offset(0, 300),
      1000,
    );
    await tester.pumpAndSettle();

    expect(api.loadCount, 2);
    expect(find.text('商家回复'), findsOneWidget);
    expect(find.textContaining('刷新消息失败'), findsOneWidget);
    expect(find.textContaining('消息加载失败'), findsNothing);
  });

  testWidgets('empty notification state can refresh', (tester) async {
    final api = NotificationScreenApi(empty: true);
    await tester.pumpWidget(
      localizedApp(
        home: NotificationScreen(repository: NotificationRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('暂无消息'), findsOneWidget);
    await tester.tap(find.byKey(const Key('notifications-empty-refresh')));
    await tester.pumpAndSettle();

    expect(api.loadCount, 2);
  });

  testWidgets('unread filter can load later pages to find unread messages', (
    tester,
  ) async {
    final api = NotificationScreenApi(paginated: true);
    await tester.pumpWidget(
      localizedApp(
        home: NotificationScreen(repository: NotificationRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('已读新通知'), findsOneWidget);
    await tester.tap(find.text('只看未读'));
    await tester.pumpAndSettle();

    expect(find.text('已读新通知'), findsNothing);
    expect(find.text('继续查找未读消息'), findsOneWidget);
    await tester.tap(find.byKey(const Key('notifications-load-more')));
    await tester.pumpAndSettle();

    expect(api.requestedPages, [1, 2]);
    expect(find.text('更早未读通知'), findsOneWidget);
    expect(find.byKey(const Key('notifications-load-more')), findsNothing);
  });

  testWidgets('notification screen renders an unread message', (tester) async {
    await tester.pumpWidget(
      localizedApp(
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
      localizedApp(
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
      localizedApp(
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
        localizedApp(
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

  testWidgets('notification ignores duplicate taps while ack is pending', (
    tester,
  ) async {
    final gate = Completer<void>();
    final api = NotificationScreenApi(social: true)..ackGate = gate;
    var openedCount = 0;
    await tester.pumpWidget(
      localizedApp(
        home: NotificationScreen(
          repository: NotificationRepository(api),
          onUserTap: (_) => openedCount += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tile = find.byKey(const Key('notification-1'));
    await tester.tap(tile);
    await tester.tap(tile);
    expect(api.ackCalls, 1);
    expect(openedCount, 0);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.ackCalls, 1);
    expect(openedCount, 1);
  });

  testWidgets('concurrent notification acknowledgements preserve both reads', (
    tester,
  ) async {
    final firstGate = Completer<void>();
    final secondGate = Completer<void>();
    final api = NotificationScreenApi(twoUnread: true)
      ..ackGates[1] = firstGate
      ..ackGates[2] = secondGate;
    await tester.pumpWidget(
      localizedApp(
        home: NotificationScreen(repository: NotificationRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('notification-1')));
    await tester.tap(find.byKey(const Key('notification-2')));
    expect(api.ackCalls, 2);

    secondGate.complete();
    await tester.pump();
    firstGate.complete();
    await tester.pumpAndSettle();

    expect(find.text('未读'), findsNothing);
  });

  testWidgets('direct message notification opens the conversation callback', (
    tester,
  ) async {
    final api = NotificationScreenApi(directMessage: true);
    int? openedConversationId;
    int? openedPeerUserId;
    String? openedPeerName;

    await tester.pumpWidget(
      localizedApp(
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
        localizedApp(
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
        localizedApp(
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
        localizedApp(
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

  testWidgets(
    'merchant reply notification acknowledges then opens public review detail',
    (tester) async {
      final api = NotificationScreenApi();
      int? openedReviewId;
      bool? openedOwned;
      await tester.pumpWidget(
        localizedApp(
          home: NotificationScreen(
            repository: NotificationRepository(api),
            onReviewTap: (reviewId, {required owned}) {
              openedReviewId = reviewId;
              openedOwned = owned;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('商家回复'));
      await tester.pumpAndSettle();
      expect(api.postedPath, '/api/c/v1/notifications/1/ack');
      expect(openedReviewId, 1);
      expect(openedOwned, isFalse);
    },
  );

  testWidgets(
    'coupon reminder notification opens coupon list with status and code',
    (tester) async {
      final api = NotificationScreenApi(couponReminder: true);
      int? openedStatus;
      String? openedCode;
      await tester.pumpWidget(
        localizedApp(
          home: NotificationScreen(
            repository: NotificationRepository(api),
            onCouponListTap: ({status, code}) {
              openedStatus = status;
              openedCode = code;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('券码即将到期'));
      await tester.pumpAndSettle();
      expect(api.postedPath, '/api/c/v1/notifications/1/ack');
      expect(openedStatus, 1);
      expect(openedCode, 'CP-DEMO');
    },
  );

  testWidgets('coupon verified notification opens coupon detail by code', (
    tester,
  ) async {
    final api = NotificationScreenApi(couponVerified: true);
    String? openedCode;
    await tester.pumpWidget(
      localizedApp(
        home: NotificationScreen(
          repository: NotificationRepository(api),
          onCouponDetailTap: (code) => openedCode = code,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('券码已核销'));
    await tester.pumpAndSettle();
    expect(api.postedPath, '/api/c/v1/notifications/1/ack');
    expect(openedCode, 'CP-DEMO');
  });

  testWidgets(
    'expert certification notification opens expert certification page',
    (tester) async {
      final api = NotificationScreenApi(expertResult: true);
      String? openedResult;
      await tester.pumpWidget(
        localizedApp(
          home: NotificationScreen(
            repository: NotificationRepository(api),
            onExpertCertificationTap: (result) => openedResult = result,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('本地达人认证已通过'));
      await tester.pumpAndSettle();
      expect(api.postedPath, '/api/c/v1/notifications/1/ack');
      expect(openedResult, 'approved');
    },
  );

  testWidgets('notification screen can mark all notifications read', (
    tester,
  ) async {
    final api = NotificationScreenApi();
    await tester.pumpWidget(
      localizedApp(
        home: NotificationScreen(repository: NotificationRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('未读'), findsOneWidget);
    await tester.tap(find.byKey(const Key('notifications-mark-all')));
    await tester.pumpAndSettle();

    expect(api.postedPath, '/api/c/v1/notifications/read-all');
    expect(find.text('未读'), findsNothing);
    expect(find.text('全部通知已标记为已读'), findsOneWidget);
  });

  testWidgets('notification serializes pagination and mark-all actions', (
    tester,
  ) async {
    final gate = Completer<void>();
    final api = NotificationScreenApi(
      paginated: true,
      paginatedFirstUnread: true,
    )..loadMoreGate = gate;
    await tester.pumpWidget(
      localizedApp(
        home: NotificationScreen(repository: NotificationRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('notifications-load-more')));
    await tester.tap(find.byKey(const Key('notifications-mark-all')));
    expect(api.requestedPages, [1, 2]);
    expect(api.markAllCalls, 0);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('更早未读通知'), findsOneWidget);
    expect(api.markAllCalls, 0);
  });

  testWidgets('notification refresh invalidates a pending next page', (
    tester,
  ) async {
    final nextPageGate = Completer<void>();
    final api = NotificationScreenApi(paginated: true)
      ..loadGates[2] = nextPageGate;
    await tester.pumpWidget(
      localizedApp(
        home: NotificationScreen(repository: NotificationRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('notifications-load-more')));
    await tester.pump();
    await tester.fling(
      find.byKey(const Key('notification-list')),
      const Offset(0, 300),
      1000,
    );
    for (var i = 0; i < 20 && api.loadCount < 3; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(api.requestedPages, [1, 2, 1]);

    await tester.pumpAndSettle();
    nextPageGate.complete();
    await tester.pumpAndSettle();

    expect(find.text('已读新通知'), findsOneWidget);
    expect(find.text('更早未读通知'), findsNothing);
  });

  testWidgets('late refresh cannot restore unread notifications', (
    tester,
  ) async {
    final refreshGate = Completer<void>();
    final api = NotificationScreenApi()..loadGates[2] = refreshGate;
    await tester.pumpWidget(
      localizedApp(
        home: NotificationScreen(repository: NotificationRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(
      find.byKey(const Key('notification-list')),
      const Offset(0, 300),
      1000,
    );
    for (var i = 0; i < 20 && api.loadCount == 1; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(api.loadCount, 2);
    await tester.tap(find.byKey(const Key('notifications-mark-all')));
    await tester.pump();
    expect(find.text('未读'), findsNothing);

    refreshGate.complete();
    await tester.pumpAndSettle();

    expect(api.loadCount, 2);
    expect(find.text('未读'), findsNothing);
  });
}
