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
        key: ValueKey('$expectedTitle::$expectedContent'),
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
    this.socialMentionPost = false,
    this.socialMentionComment = false,
    this.postAudit = false,
    this.topicUpdate = false,
    this.orderPaid = false,
    this.orderRefundApproved = false,
    this.orderRefundRejected = false,
    this.reservationCreated = false,
    this.reservationReminderSoon = false,
    this.reservationReminderLater = false,
    this.reservationStatusRejected = false,
    this.reservationStatusNoShow = false,
    this.couponReminder = false,
    this.couponExpired = false,
    this.couponVerified = false,
    this.reviewLike = false,
    this.reviewComment = false,
    this.reviewCommentReply = false,
    this.postLike = false,
    this.postComment = false,
    this.postCommentReply = false,
    this.postRepost = false,
    this.expertResult = false,
    this.reviewAuditApproved = false,
    this.reviewHidden = false,
    this.banAppealApproved = false,
    this.banAppealRejected = false,
    this.accountUnbanned = false,
    this.failFirstLoad = false,
    this.mixedRead = false,
    this.twoUnread = false,
    this.empty = false,
    this.paginated = false,
    this.paginatedFirstUnread = false,
  });
  final bool social;
  final bool directMessage;
  final bool socialMentionPost;
  final bool socialMentionComment;
  final bool postAudit;
  final bool topicUpdate;
  final bool orderPaid;
  final bool orderRefundApproved;
  final bool orderRefundRejected;
  final bool reservationCreated;
  final bool reservationReminderSoon;
  final bool reservationReminderLater;
  final bool reservationStatusRejected;
  final bool reservationStatusNoShow;
  final bool couponReminder;
  final bool couponExpired;
  final bool couponVerified;
  final bool reviewLike;
  final bool reviewComment;
  final bool reviewCommentReply;
  final bool postLike;
  final bool postComment;
  final bool postCommentReply;
  final bool postRepost;
  final bool expertResult;
  final bool reviewAuditApproved;
  final bool reviewHidden;
  final bool banAppealApproved;
  final bool banAppealRejected;
  final bool accountUnbanned;
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
  Object? loadError;
  Object? refreshError;
  Object? loadMoreError;
  Completer<void>? ackGate;
  final ackGates = <int, Completer<void>>{};
  final loadGates = <int, Completer<void>>{};
  int ackCalls = 0;
  Object? ackError;
  Completer<void>? loadMoreGate;
  int markAllCalls = 0;
  Object? markAllError;

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
    if (socialMentionPost) {
      return {
        'id': 1,
        'type': 'social.mention',
        'actorUserId': 9,
        'actorName': '东京阿满',
        'title': '有人@了你',
        'content': '东京阿满 在帖子《京都早餐地图》中提到了你',
        'linkUrl': '/community/posts/88',
        'aggregateCount': 1,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    if (socialMentionComment) {
      return {
        'id': 1,
        'type': 'social.mention',
        'actorUserId': 9,
        'actorName': '悉尼阿柚',
        'title': '有人@了你',
        'content': '悉尼阿柚 在帖子《曼谷夜市合集》的评论中提到了你',
        'linkUrl': '/community/posts/88',
        'aggregateCount': 1,
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
    if (topicUpdate) {
      return {
        'id': 1,
        'type': 'topic.update',
        'actorUserId': 9,
        'actorName': '马德里小许',
        'title': '关注的话题有新内容',
        'content': '马德里小许 在 #城市夜宵 发布了《首尔夜猫子路线》',
        'linkUrl': '/community/posts/88',
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
    if (orderRefundApproved) {
      return {
        'id': 1,
        'type': 'order.refund.result',
        'actorUserId': null,
        'actorName': '',
        'title': '退款已通过',
        'content': '双人套餐 · 订单 OD456 · 平台已同意退款：已按原路退回',
        'linkUrl': '/user/orders/99?refund=approved',
        'aggregateCount': 1,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    if (orderRefundRejected) {
      return {
        'id': 1,
        'type': 'order.refund.result',
        'actorUserId': null,
        'actorName': '',
        'title': '退款已驳回',
        'content': '双人套餐 · 订单 OD456 · 商户已驳回退款：券码已核销',
        'linkUrl': '/user/orders/99?refund=rejected',
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
    if (reservationReminderSoon) {
      return {
        'id': 1,
        'type': 'reservation.reminder',
        'actorUserId': null,
        'actorName': '',
        'title': '预订即将开始（30 分钟）',
        'content': '巴黎川菜馆 · 2026-07-26 18:00 · 2 人',
        'linkUrl': '/user/reservations/44?remind=30',
        'aggregateCount': 1,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    if (reservationReminderLater) {
      return {
        'id': 1,
        'type': 'reservation.reminder',
        'actorUserId': null,
        'actorName': '',
        'title': '预订提醒（2 小时）',
        'content': '巴黎川菜馆 · 2026-07-26 18:00 · 4 人',
        'linkUrl': '/user/reservations/44?remind=120',
        'aggregateCount': 1,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    if (reservationStatusRejected) {
      return {
        'id': 1,
        'type': 'reservation.status',
        'actorUserId': null,
        'actorName': '',
        'title': '预订被拒绝',
        'content': '巴黎川菜馆 · 2026-07-26 18:00 · 2 人 · 商户已拒绝你的预订：满桌',
        'linkUrl': '/user/reservations/44?status=rejected',
        'aggregateCount': 1,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    if (reservationStatusNoShow) {
      return {
        'id': 1,
        'type': 'reservation.status',
        'actorUserId': null,
        'actorName': '',
        'title': '预订已标记爽约',
        'content': '巴黎川菜馆 · 2026-07-26 18:00 · 2 人 · 商户已将本次预订标记为爽约',
        'linkUrl': '/user/reservations/44?status=no_show',
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
    if (couponExpired) {
      return {
        'id': 1,
        'type': 'coupon.expired',
        'actorUserId': null,
        'actorName': '',
        'title': '券码已过期',
        'content': '双人套餐 · 巴黎川菜馆 · 有效期至 2026-07-20 · 券码 CP-OVERDUE',
        'linkUrl': '/user/coupons?status=3&code=CP-OVERDUE',
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
    if (reviewLike) {
      return {
        'id': 1,
        'type': 'review.like',
        'actorUserId': 9,
        'actorName': '慕尼黑小李',
        'title': '点评获赞',
        'content': '慕尼黑小李 赞了你的点评：这家店也太稳了',
        'linkUrl': '/reviews/12',
        'aggregateCount': 1,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    if (reviewComment) {
      return {
        'id': 1,
        'type': 'review.comment',
        'actorUserId': 9,
        'actorName': '罗马小周',
        'title': '点评新评论',
        'content': '罗马小周 评论了你的点评：排队十分钟就能进',
        'linkUrl': '/reviews/12',
        'aggregateCount': 1,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    if (reviewCommentReply) {
      return {
        'id': 1,
        'type': 'review.comment.reply',
        'actorUserId': 9,
        'actorName': '里昂阿澄',
        'title': '评论被回复',
        'content': '里昂阿澄 回复了你：我也喜欢这个套餐',
        'linkUrl': '/reviews/12',
        'aggregateCount': 1,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    if (postLike) {
      return {
        'id': 1,
        'type': 'post.like',
        'actorUserId': 9,
        'actorName': '哥本哈根阿宁',
        'title': '帖子获赞',
        'content': '哥本哈根阿宁 赞了你的帖子《巴黎咖啡地图》',
        'linkUrl': '/community/posts/88',
        'aggregateCount': 1,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    if (postComment) {
      return {
        'id': 1,
        'type': 'post.comment',
        'actorUserId': 9,
        'actorName': '苏黎世阿飞',
        'title': '帖子新评论',
        'content': '苏黎世阿飞 评论了你的帖子：收藏了这条路线',
        'linkUrl': '/community/posts/88',
        'aggregateCount': 1,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    if (postCommentReply) {
      return {
        'id': 1,
        'type': 'post.comment.reply',
        'actorUserId': 9,
        'actorName': '米兰小顾',
        'title': '评论被回复',
        'content': '米兰小顾 回复了你：下次一起去',
        'linkUrl': '/community/posts/88',
        'aggregateCount': 1,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    if (postRepost) {
      return {
        'id': 1,
        'type': 'post.repost',
        'actorUserId': 9,
        'actorName': '阿姆斯特丹小夏',
        'title': '帖子被转发',
        'content': '阿姆斯特丹小夏 转发了你的帖子《伦敦夜宵清单》',
        'linkUrl': '/community/posts/88',
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
    if (reviewAuditApproved) {
      return {
        'id': 1,
        'type': 'review.audit.result',
        'actorUserId': null,
        'actorName': '',
        'title': '点评已通过审核',
        'content': '柏林茶馆 · 你的点评已公开展示',
        'linkUrl': '/user/reviews/12?audit=approved',
        'aggregateCount': 1,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    if (reviewHidden) {
      return {
        'id': 1,
        'type': 'review.hidden',
        'actorUserId': null,
        'actorName': '',
        'title': '点评已被隐藏',
        'content': '柏林茶馆 · 商户申诉成立，你的点评已从公开展示中隐藏：商家已提供处理凭证',
        'linkUrl': '/user/reviews/12?hidden=appeal',
        'aggregateCount': 1,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    if (banAppealApproved) {
      return {
        'id': 1,
        'type': 'account.ban_appeal',
        'actorUserId': null,
        'actorName': '',
        'title': '封禁申诉已通过',
        'content': '你的封禁申诉已通过，账号已解封，现在可以正常登录使用了。',
        'linkUrl': '',
        'aggregateCount': 1,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    if (banAppealRejected) {
      return {
        'id': 1,
        'type': 'account.ban_appeal',
        'actorUserId': null,
        'actorName': '',
        'title': '封禁申诉已驳回',
        'content': '你的封禁申诉未通过：存在刷单行为',
        'linkUrl': '',
        'aggregateCount': 1,
        'read': read,
        'createdAt': '2026-07-15 10:00:00',
      };
    }
    if (accountUnbanned) {
      return {
        'id': 1,
        'type': 'account.ban_appeal',
        'actorUserId': null,
        'actorName': '',
        'title': '账号已解封',
        'content': '管理员已解除你的账号封禁，关联的申诉已自动通过，现在可以正常登录使用了。',
        'linkUrl': '',
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
    if (page == 1 && loadCount == 1 && loadError != null) {
      throw loadError!;
    }
    if (page == 1 && loadCount > 1 && refreshError != null) {
      throw refreshError!;
    }
    if (page > 1 && loadMoreError != null) {
      throw loadMoreError!;
    }
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
      if (markAllError != null) {
        throw markAllError!;
      }
      return {'updated': 1, 'count': 0};
    }
    ackCalls += 1;
    if (ackError != null) {
      throw ackError!;
    }
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

  testWidgets('notification screen localizes supported notifications in English', (
    tester,
  ) async {
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
      api: NotificationScreenApi(socialMentionPost: true),
      expectedTitle: 'You were mentioned',
      expectedContent: '东京阿满 mentioned you in the post "京都早餐地图"',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(socialMentionComment: true),
      expectedTitle: 'You were mentioned',
      expectedContent: '悉尼阿柚 mentioned you in a comment on "曼谷夜市合集"',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(postAudit: true),
      expectedTitle: 'Post approved',
      expectedContent: '"伦敦周末早午餐避坑指南" is now public: 内容真实，可公开',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(topicUpdate: true),
      expectedTitle: 'New topic update',
      expectedContent: '马德里小许 posted "首尔夜猫子路线" in #城市夜宵',
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
      api: NotificationScreenApi(orderRefundApproved: true),
      expectedTitle: 'Refund approved',
      expectedContent:
          '双人套餐 · Order OD456 · Platform approved your refund: 已按原路退回',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(orderRefundRejected: true),
      expectedTitle: 'Refund rejected',
      expectedContent:
          '双人套餐 · Order OD456 · Merchant rejected your refund: 券码已核销',
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
      api: NotificationScreenApi(reservationReminderSoon: true),
      expectedTitle: 'Reservation starts in 30 min',
      expectedContent: '巴黎川菜馆 · 2026-07-26 18:00 · 2 guests',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(reservationReminderLater: true),
      expectedTitle: 'Reservation reminder (2 hours)',
      expectedContent: '巴黎川菜馆 · 2026-07-26 18:00 · 4 guests',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(reservationStatusRejected: true),
      expectedTitle: 'Reservation rejected',
      expectedContent:
          '巴黎川菜馆 · 2026-07-26 18:00 · 2 guests · The merchant rejected your reservation: 满桌',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(reservationStatusNoShow: true),
      expectedTitle: 'Reservation marked no-show',
      expectedContent:
          '巴黎川菜馆 · 2026-07-26 18:00 · 2 guests · The merchant marked this reservation as no-show',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(couponReminder: true),
      expectedTitle: 'Coupon reminder',
      expectedContent: 'CP-DEMO expires in 1 day',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(couponExpired: true),
      expectedTitle: 'Coupon expired',
      expectedContent:
          '双人套餐 · 巴黎川菜馆 · Valid until 2026-07-20 · Coupon CP-OVERDUE',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(couponVerified: true),
      expectedTitle: 'Coupon redeemed',
      expectedContent: 'CP-DEMO was redeemed at 柏林茶馆',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(reviewLike: true),
      expectedTitle: 'Review liked',
      expectedContent: '慕尼黑小李 liked your review: 这家店也太稳了',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(reviewComment: true),
      expectedTitle: 'New review comment',
      expectedContent: '罗马小周 commented on your review: 排队十分钟就能进',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(reviewCommentReply: true),
      expectedTitle: 'Comment reply',
      expectedContent: '里昂阿澄 replied to you: 我也喜欢这个套餐',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(postLike: true),
      expectedTitle: 'Post liked',
      expectedContent: '哥本哈根阿宁 liked your post "巴黎咖啡地图"',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(postComment: true),
      expectedTitle: 'New post comment',
      expectedContent: '苏黎世阿飞 commented on your post: 收藏了这条路线',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(postCommentReply: true),
      expectedTitle: 'Comment reply',
      expectedContent: '米兰小顾 replied to you: 下次一起去',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(postRepost: true),
      expectedTitle: 'Post reposted',
      expectedContent: '阿姆斯特丹小夏 reposted your post "伦敦夜宵清单"',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(expertResult: true),
      expectedTitle: 'Local expert certification approved',
      expectedContent: 'Your local expert certification was approved',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(reviewAuditApproved: true),
      expectedTitle: 'Review approved',
      expectedContent: '柏林茶馆 · Your review is now public',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(reviewHidden: true),
      expectedTitle: 'Review hidden',
      expectedContent:
          '柏林茶馆 · The merchant appeal was approved and your review was hidden from public view: 商家已提供处理凭证',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(banAppealApproved: true),
      expectedTitle: 'Ban appeal approved',
      expectedContent:
          'Your ban appeal was approved. Your account has been unbanned and you can sign in again.',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(banAppealRejected: true),
      expectedTitle: 'Ban appeal rejected',
      expectedContent: 'Your ban appeal was rejected: 存在刷单行为',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(accountUnbanned: true),
      expectedTitle: 'Account unbanned',
      expectedContent:
          'An admin removed your account ban. The related appeal was auto-approved and you can sign in again.',
    );
    await expectEnglishNotification(
      tester,
      api: NotificationScreenApi(),
      expectedTitle: 'Merchant reply',
      expectedContent: '谢谢支持',
    );
  });

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

    expect(find.textContaining('通知服务暂时不可用'), findsOneWidget);
    expect(find.textContaining('网络暂时不可用'), findsNothing);
    await tester.tap(find.byKey(const Key('notifications-retry')));
    await tester.pumpAndSettle();

    expect(api.loadCount, 2);
    expect(find.text('商家回复'), findsOneWidget);
  });

  testWidgets('notification screen localizes load errors in English', (
    tester,
  ) async {
    final api = NotificationScreenApi()
      ..loadError = const ApiException('网络暂时不可用');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: NotificationScreen(repository: NotificationRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not load notifications: The notification service is temporarily unavailable.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('网络暂时不可用'), findsNothing);
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

  testWidgets('notification screen localizes refresh errors in English', (
    tester,
  ) async {
    final api = NotificationScreenApi()
      ..refreshError = const ApiException('刷新网络暂时不可用');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
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

    expect(
      find.text(
        'Could not refresh notifications: Notifications could not be refreshed right now.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('刷新网络暂时不可用'), findsNothing);
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

  testWidgets('notification screen localizes load more errors in English', (
    tester,
  ) async {
    final api = NotificationScreenApi(paginated: true)
      ..loadMoreError = const ApiException('网络暂时不可用');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: NotificationScreen(repository: NotificationRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('notifications-load-more')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not load more: The notification service is temporarily unavailable.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('网络暂时不可用'), findsNothing);
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

  testWidgets('notification screen localizes mark read errors in English', (
    tester,
  ) async {
    final api = NotificationScreenApi()
      ..ackError = const ApiException('网络暂时不可用');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: NotificationScreen(repository: NotificationRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Merchant reply'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not mark as read: The notification service is temporarily unavailable.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('网络暂时不可用'), findsNothing);
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

  testWidgets('notification screen localizes mark all read errors in English', (
    tester,
  ) async {
    final api = NotificationScreenApi()
      ..markAllError = const ApiException('网络暂时不可用');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: NotificationScreen(repository: NotificationRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('notifications-mark-all')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not mark all as read: The notification service is temporarily unavailable.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('网络暂时不可用'), findsNothing);
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
