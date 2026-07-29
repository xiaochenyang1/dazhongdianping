import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/review/review_detail_screen.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class DetailFakeApi implements JsonApi, JsonDeleteApi {
  final List<String> posts = <String>[];
  final List<String> deletedPaths = <String>[];
  bool liked = false;
  int likeCount = 3;
  bool paginateComments = false;
  bool failNextDetail = false;
  bool failNextComments = false;
  bool failNextReport = false;
  int reportRequests = 0;
  int detailRequests = 0;
  Completer<void>? commentRetryGate;
  Completer<void>? detailRetryGate;
  final List<int> requestedCommentPages = <int>[];
  final List<Map<String, dynamic>> comments = [
    {
      'id': 81,
      'reviewId': 12,
      'userId': 2,
      'userName': '小李',
      'content': '说得对',
      'parentId': 0,
      'replyTo': null,
      'replies': const [],
      'mine': false,
      'createdAt': '2026-07-19 19:00:00',
    },
  ];

  Map<String, dynamic> detail({bool owned = false}) => {
    'id': 12,
    'shopId': 7,
    'shopName': '柏林茶馆',
    'userId': 9,
    'userName': '阿遥',
    'content': '茶香很足，服务也利落。',
    'scoreOverall': 4.5,
    'scoreTaste': 5,
    'scoreEnv': 4,
    'scoreService': 4.5,
    'cost': 18.5,
    'currency': 'EUR',
    'likeCount': likeCount,
    'commentCount': comments.length,
    'likedByCurrentUser': liked,
    'auditStatus': owned ? 0 : 1,
    'auditStatusText': owned ? '待审核' : '审核通过',
    'auditRemark': owned ? '请补充菜品细节' : '',
    'status': 1,
    'statusText': '正常',
    'authorCertification': {'code': 'local_expert', 'label': '本地达人'},
    'tags': ['中文服务'],
    'images': [
      {'id': 1, 'url': '/uploads/tea-1.png'},
    ],
    'merchantReply': {
      'merchantName': '柏林茶馆',
      'content': '谢谢支持',
      'repliedAt': '2026-07-20 12:00:00',
      'updatedAt': '2026-07-20 12:00:00',
    },
    'createdAt': '2026-07-19 18:00:00',
    'updatedAt': '2026-07-19 18:00:00',
  };

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (path == '/api/c/v1/user/reviews/12') {
      return detail(owned: true);
    }
    if (path == '/api/c/v1/reviews/12/comments') {
      if (failNextComments) {
        failNextComments = false;
        throw StateError('comment network unavailable');
      }
      await commentRetryGate?.future;
      final page = query?['page'] as int? ?? 1;
      requestedCommentPages.add(page);
      final pageComments = !paginateComments
          ? comments
          : page == 1
          ? comments.take(1).toList()
          : [
              {
                'id': 82,
                'reviewId': 12,
                'userId': 3,
                'userName': '更早的用户',
                'content': '更早的点评评论',
                'parentId': 0,
                'replyTo': null,
                'replies': const [],
                'mine': false,
                'createdAt': '2026-07-18 19:00:00',
              },
            ];
      return {
        'list': pageComments,
        'total': paginateComments ? 2 : comments.length,
        'page': page,
        'pageSize': paginateComments ? 1 : 50,
      };
    }
    if (path == '/api/c/v1/reviews/12') {
      detailRequests++;
      if (failNextDetail) {
        failNextDetail = false;
        throw StateError('network unavailable');
      }
      await detailRetryGate?.future;
      return detail();
    }
    throw StateError('unexpected path $path');
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path) async {
    deletedPaths.add(path);
    return const {};
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    posts.add(path);
    if (path == '/api/c/v1/reviews/12/like') {
      liked = !liked;
      likeCount += liked ? 1 : -1;
      return {'reviewId': 12, 'liked': liked, 'likeCount': likeCount};
    }
    if (path == '/api/c/v1/reviews/12/comments') {
      final content = (body as Map)['content'] as String;
      comments.add({
        'id': 100 + comments.length,
        'reviewId': 12,
        'userId': 1,
        'userName': '我',
        'content': content,
        'parentId': 0,
        'replyTo': null,
        'replies': const [],
        'mine': true,
        'createdAt': '2026-07-25 12:00:00',
      });
      return comments.last;
    }
    if (path == '/api/c/v1/reviews/12/report') {
      reportRequests++;
      if (failNextReport) {
        failNextReport = false;
        throw StateError('report unavailable');
      }
      return {
        'id': 1,
        'reviewId': 12,
        'reason': (body as Map)['reason'],
        'status': 0,
        'statusText': '待处理',
        'createdAt': '2026-07-25 12:00:00',
      };
    }
    throw StateError('unexpected post $path');
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
  testWidgets('public review detail retries an initial comment failure', (
    tester,
  ) async {
    final api = DetailFakeApi()..failNextComments = true;
    await tester.pumpWidget(
      localizedApp(
        home: ReviewDetailScreen(
          repository: ReviewRepository(api),
          reviewId: 12,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('review-comments-retry')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('评论加载失败'), findsOneWidget);

    await tester.tap(find.byKey(const Key('review-comments-retry')));
    await tester.pumpAndSettle();
    expect(api.requestedCommentPages, [1]);
    expect(find.text('说得对'), findsOneWidget);
  });

  testWidgets('public review guards duplicate comment retries', (tester) async {
    final gate = Completer<void>();
    final api = DetailFakeApi()
      ..failNextComments = true
      ..commentRetryGate = gate;
    await tester.pumpWidget(
      localizedApp(
        home: ReviewDetailScreen(
          repository: ReviewRepository(api),
          reviewId: 12,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('review-comments-retry')),
      500,
      scrollable: find.byType(Scrollable).first,
    );

    final retry = find.byKey(const Key('review-comments-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(api.requestedCommentPages, isEmpty);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.requestedCommentPages, [1]);
    expect(find.text('说得对'), findsOneWidget);
  });

  testWidgets('public review detail retries an initial load failure', (
    tester,
  ) async {
    final api = DetailFakeApi()..failNextDetail = true;
    await tester.pumpWidget(
      localizedApp(
        home: ReviewDetailScreen(
          repository: ReviewRepository(api),
          reviewId: 12,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('点评详情加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('review-detail-retry')));
    await tester.pumpAndSettle();

    expect(api.detailRequests, 2);
    expect(find.text('柏林茶馆'), findsOneWidget);
    expect(api.requestedCommentPages, [1]);
  });

  testWidgets('public review guards duplicate detail retries', (tester) async {
    final gate = Completer<void>();
    final api = DetailFakeApi()
      ..failNextDetail = true
      ..detailRetryGate = gate;
    await tester.pumpWidget(
      localizedApp(
        home: ReviewDetailScreen(
          repository: ReviewRepository(api),
          reviewId: 12,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('review-detail-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(api.detailRequests, 2);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.detailRequests, 2);
    expect(find.text('柏林茶馆'), findsOneWidget);
  });

  testWidgets('public review detail localizes English chrome', (tester) async {
    final api = DetailFakeApi();
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: ReviewDetailScreen(
          repository: ReviewRepository(api),
          reviewId: 12,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Review details'), findsOneWidget);
    expect(
      find.text('Taste 5.0 · Environment 4.0 · Service 4.5 · Avg spend EUR 19'),
      findsOneWidget,
    );
    expect(find.textContaining('3 likes · 1 comments'), findsOneWidget);
  });

  testWidgets('public review detail loads later comment pages', (tester) async {
    final api = DetailFakeApi()..paginateComments = true;
    await tester.pumpWidget(
      localizedApp(
        home: ReviewDetailScreen(
          repository: ReviewRepository(api),
          reviewId: 12,
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('review-comments-load-more')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('review-comments-load-more')));
    await tester.pumpAndSettle();

    expect(api.requestedCommentPages, [1, 2]);
    expect(find.text('更早的点评评论'), findsOneWidget);
    expect(find.byKey(const Key('review-comments-load-more')), findsNothing);
  });

  testWidgets('public review detail supports like comment and report', (
    tester,
  ) async {
    final api = DetailFakeApi();
    await tester.pumpWidget(
      localizedApp(
        home: ReviewDetailScreen(
          repository: ReviewRepository(api),
          reviewId: 12,
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('柏林茶馆'), findsOneWidget);
    expect(find.text('本地达人'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('说得对'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('说得对'), findsOneWidget);
    expect(find.textContaining('商家回复：柏林茶馆：谢谢支持'), findsOneWidget);

    await tester.tap(find.byKey(const Key('review-like-button')));
    await tester.pumpAndSettle();
    expect(api.posts, contains('/api/c/v1/reviews/12/like'));
    expect(find.text('已点赞'), findsWidgets);
    ScaffoldMessenger.of(
      tester.element(find.byType(ReviewDetailScreen)),
    ).clearSnackBars();
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('review-comment-input')), '同意');
    await tester.tap(find.byKey(const Key('review-comment-submit')));
    await tester.pumpAndSettle();
    expect(api.posts, contains('/api/c/v1/reviews/12/comments'));
    expect(find.text('同意'), findsOneWidget);
    ScaffoldMessenger.of(
      tester.element(find.byType(ReviewDetailScreen)),
    ).clearSnackBars();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('review-report-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('review-report-reason')),
      '疑似广告',
    );
    await tester.tap(find.text('提交举报'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(api.posts, contains('/api/c/v1/reviews/12/report'));
    expect(find.text('举报已提交'), findsOneWidget);
  });

  testWidgets('guest public review detail is read-only', (tester) async {
    final api = DetailFakeApi();
    await tester.pumpWidget(
      localizedApp(
        home: ReviewDetailScreen(
          repository: ReviewRepository(api),
          reviewId: 12,
          canInteract: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('登录后可点赞、评论和举报这条点评。'), findsOneWidget);
    expect(find.byKey(const Key('review-like-button')), findsNothing);
    expect(find.byKey(const Key('review-comment-input')), findsNothing);
  });

  testWidgets('public review guards duplicate report dialogs', (tester) async {
    final api = DetailFakeApi();
    await tester.pumpWidget(
      localizedApp(
        home: ReviewDetailScreen(
          repository: ReviewRepository(api),
          reviewId: 12,
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final report = find.byKey(const Key('review-report-button'));
    await tester.scrollUntilVisible(
      report,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final reportAction = tester.widget<OutlinedButton>(report).onPressed!;

    reportAction();
    reportAction();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('举报点评'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(api.reportRequests, 0);
  });

  testWidgets('public review preserves a failed report reason for retry', (
    tester,
  ) async {
    final api = DetailFakeApi()..failNextReport = true;
    await tester.pumpWidget(
      localizedApp(
        home: ReviewDetailScreen(
          repository: ReviewRepository(api),
          reviewId: 12,
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('review-report-button')),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.byKey(const Key('review-report-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('review-report-reason')),
      '需要重试的点评举报',
    );
    await tester.tap(find.text('提交举报'));
    await tester.pumpAndSettle();
    expect(find.textContaining('举报失败'), findsOneWidget);

    await tester.tap(find.byKey(const Key('review-report-button')));
    await tester.pumpAndSettle();
    expect(find.text('需要重试的点评举报'), findsOneWidget);
    await tester.tap(find.text('提交举报'));
    await tester.pumpAndSettle();
    expect(api.reportRequests, 2);

    await tester.tap(find.byKey(const Key('review-report-button')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('review-report-reason')))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('owned review detail shows audit remark and edit entry', (
    tester,
  ) async {
    final api = DetailFakeApi();
    await tester.pumpWidget(
      localizedApp(
        home: ReviewDetailScreen(
          repository: ReviewRepository(api),
          reviewId: 12,
          owned: true,
          canInteract: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('我的点评详情'), findsOneWidget);
    expect(find.textContaining('审核备注：请补充菜品细节'), findsOneWidget);
    expect(find.text('编辑'), findsOneWidget);
    expect(find.byKey(const Key('review-like-button')), findsNothing);
  });

  testWidgets('owned review detail can delete the review', (tester) async {
    final api = DetailFakeApi();
    await tester.pumpWidget(
      localizedApp(
        home: ReviewDetailScreen(
          repository: ReviewRepository(api),
          reviewId: 12,
          owned: true,
          canInteract: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('review-delete-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('review-delete-confirm')));
    await tester.pumpAndSettle();

    expect(api.deletedPaths, contains('/api/c/v1/reviews/12'));
    expect(find.text('我的点评详情'), findsNothing);
  });

  testWidgets('owned review guards duplicate delete dialogs', (tester) async {
    final api = DetailFakeApi();
    await tester.pumpWidget(
      localizedApp(
        home: ReviewDetailScreen(
          repository: ReviewRepository(api),
          reviewId: 12,
          owned: true,
          canInteract: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final delete = find.byKey(const Key('review-delete-button'));
    final deleteAction = tester.widget<TextButton>(delete).onPressed!;
    deleteAction();
    deleteAction();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('删除点评'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(api.deletedPaths, isEmpty);
  });
}
