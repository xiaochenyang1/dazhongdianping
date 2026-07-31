import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/topic/topic_detail_screen.dart';
import 'package:dazhongdianping_app/features/topic/topic_plaza_screen.dart';
import 'package:dazhongdianping_app/features/topic/topic_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class TopicScreenApi implements JsonApi, JsonMutationApi, JsonDeleteApi {
  int followingCalls = 0;
  bool failFollow = false;
  int followCalls = 0;
  Completer<void>? followGate;
  bool paginateTopics = false;
  bool failNextRecommended = false;
  Object? topicPageError;
  Object? loadMoreTopicPageError;
  final List<int> requestedTopicPages = <int>[];
  final List<String> requestedTopicPageKeys = <String>[];
  final topicPageGates = <String, Completer<void>>{};
  bool paginatePosts = false;
  bool failNextPosts = false;
  Object? topicPostsError;
  Object? loadMoreTopicPostsError;
  final List<int> requestedPostPages = <int>[];
  Completer<void>? postRetryGate;
  int postCalls = 0;
  Completer<void>? postDetailGate;
  int postDetailCalls = 0;
  Object? followError;

  Map<String, dynamic> topic({bool followed = false, int count = 88}) => {
    'id': 31,
    'region': 'EU',
    'name': '伦敦咖啡',
    'postCount': 12,
    'followerCount': count,
    'recommended': true,
    'pinnedSort': 0,
    'followedByCurrentUser': followed,
    'hotScore': 169,
    'postCount7d': 2,
    'likeCount7d': 3,
    'commentCount7d': 4,
    'calculatedAt': '2026-07-17 19:00:00',
  };

  Map<String, dynamic> get post => {
    'id': 7,
    'userId': 9,
    'userName': '伦敦小王',
    'title': '周末咖啡地图',
    'content': '三家新店实测。',
    'contentType': 1,
    'likeCount': 2,
    'commentCount': 1,
    'auditStatus': 1,
    'auditStatusText': '审核通过',
    'auditRemark': '',
    'images': const [],
    'topics': ['伦敦咖啡'],
    'createdAt': '2026-07-17 10:00:00',
  };

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (path == '/api/c/v1/posts/7') {
      postDetailCalls++;
      await postDetailGate?.future;
      return post;
    }
    if (path == '/api/c/v1/posts/7/comments') {
      return {'list': const [], 'total': 0};
    }
    if (path == '/api/c/v1/topics/following') {
      followingCalls++;
      return {
        'list': [topic(followed: true)],
        'total': 1,
      };
    }
    if (path.endsWith('/posts')) {
      postCalls++;
      final page = query?['page'] as int? ?? 1;
      if (page == 1 && topicPostsError != null) {
        throw topicPostsError!;
      }
      if (page > 1 && loadMoreTopicPostsError != null) {
        throw loadMoreTopicPostsError!;
      }
      if (failNextPosts) {
        failNextPosts = false;
        throw StateError('post network unavailable');
      }
      await postRetryGate?.future;
      requestedPostPages.add(page);
      return {
        'list': [
          if (!paginatePosts || page == 1)
            post
          else
            {...post, 'id': 8, 'title': '更早的话题帖子'},
        ],
        'total': paginatePosts ? 2 : 1,
        'page': page,
        'pageSize': paginatePosts ? 1 : 30,
      };
    }
    if (path == '/api/c/v1/topics/31') return topic();
    if (path == '/api/c/v1/topics' && failNextRecommended) {
      failNextRecommended = false;
      throw StateError('topic network unavailable');
    }
    final page = query?['page'] as int? ?? 1;
    if (page == 1 && topicPageError != null) {
      throw topicPageError!;
    }
    if (page > 1 && loadMoreTopicPageError != null) {
      throw loadMoreTopicPageError!;
    }
    requestedTopicPages.add(page);
    final pageKey = '$path:$page';
    requestedTopicPageKeys.add(pageKey);
    await topicPageGates[pageKey]?.future;
    return {
      'list': [
        if (!paginateTopics || page == 1)
          topic()
        else
          {...topic(), 'id': 32, 'name': '巴黎甜点'},
      ],
      'total': paginateTopics ? 2 : 1,
      'page': page,
      'pageSize': paginateTopics ? 1 : 30,
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      {};

  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    followCalls++;
    await followGate?.future;
    if (followError != null) {
      throw followError!;
    }
    if (failFollow) throw const ApiException('关注失败');
    return {'topicId': 31, 'followed': true, 'followerCount': 89};
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path) async => {
    'topicId': 31,
    'followed': false,
    'followerCount': 88,
  };
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
  testWidgets('topic plaza switches English chrome', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: TopicPlazaScreen(
          repository: TopicRepository(TopicScreenApi()),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Topics'), findsOneWidget);
    expect(find.text('For you'), findsOneWidget);
    expect(find.text('Trending'), findsOneWidget);
    expect(find.text('Following'), findsOneWidget);
    expect(find.text('Heat updated 17/07/2026 19:00'), findsOneWidget);
  });

  testWidgets('topic detail localizes heat calculation time in English', (
    tester,
  ) async {
    final api = TopicScreenApi();
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: TopicDetailScreen(
          repository: TopicRepository(api),
          initial: TopicSummary.fromJson(api.topic()),
          canInteract: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Heat updated 17/07/2026 19:00'), findsOneWidget);
  });

  testWidgets('topic plaza localizes load errors in English', (tester) async {
    final api = TopicScreenApi()
      ..topicPageError = const ApiException('用户登录状态不存在');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: TopicPlazaScreen(
          repository: TopicRepository(api),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not load topics: Your sign-in session is no longer available. Please sign in again.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('用户登录状态不存在'), findsNothing);
  });

  testWidgets('topic detail retries an initial post failure', (tester) async {
    final api = TopicScreenApi()..failNextPosts = true;
    await tester.pumpWidget(
      MaterialApp(
        home: TopicDetailScreen(
          repository: TopicRepository(api),
          initial: TopicSummary.fromJson(api.topic()),
          canInteract: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('帖子加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('topic-posts-retry')));
    await tester.pumpAndSettle();

    expect(api.requestedPostPages, [1]);
    expect(find.text('周末咖啡地图'), findsOneWidget);
    expect(find.text('88 人关注'), findsOneWidget);
  });

  testWidgets('topic detail localizes post load errors in English', (
    tester,
  ) async {
    final api = TopicScreenApi()..topicPostsError = const ApiException('话题不存在');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: TopicDetailScreen(
          repository: TopicRepository(api),
          initial: TopicSummary.fromJson(api.topic()),
          canInteract: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Could not load posts: This topic could not be found.'),
      findsOneWidget,
    );
    expect(find.textContaining('话题不存在'), findsNothing);
  });

  testWidgets('topic detail guards duplicate post retries', (tester) async {
    final gate = Completer<void>();
    final api = TopicScreenApi()
      ..failNextPosts = true
      ..postRetryGate = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: TopicDetailScreen(
          repository: TopicRepository(api),
          initial: TopicSummary.fromJson(api.topic()),
          canInteract: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('topic-posts-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(api.requestedPostPages, isEmpty);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.requestedPostPages, [1]);
    expect(find.text('周末咖啡地图'), findsOneWidget);
  });

  testWidgets('topic plaza retries an initial load failure', (tester) async {
    final api = TopicScreenApi()..failNextRecommended = true;
    await tester.pumpWidget(
      MaterialApp(
        home: TopicPlazaScreen(
          repository: TopicRepository(api),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('话题加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('topic-plaza-retry')));
    await tester.pumpAndSettle();

    expect(api.requestedTopicPages, [1]);
    expect(find.text('伦敦咖啡'), findsOneWidget);
  });

  testWidgets('topic plaza guards duplicate retries per tab', (tester) async {
    final gate = Completer<void>();
    final api = TopicScreenApi()..failNextRecommended = true;
    api.topicPageGates['/api/c/v1/topics:1'] = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: TopicPlazaScreen(
          repository: TopicRepository(api),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('topic-plaza-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(
      api.requestedTopicPageKeys.where((key) => key == '/api/c/v1/topics:1'),
      hasLength(1),
    );

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('伦敦咖啡'), findsOneWidget);
  });

  testWidgets('topic detail loads later posts', (tester) async {
    final api = TopicScreenApi()..paginatePosts = true;
    await tester.pumpWidget(
      MaterialApp(
        home: TopicDetailScreen(
          repository: TopicRepository(api),
          initial: TopicSummary.fromJson(api.topic()),
          canInteract: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('topic-posts-load-more')), findsOneWidget);
    await tester.tap(find.byKey(const Key('topic-posts-load-more')));
    await tester.pumpAndSettle();

    expect(api.requestedPostPages, [1, 2]);
    expect(find.text('更早的话题帖子'), findsOneWidget);
    expect(find.byKey(const Key('topic-posts-load-more')), findsNothing);
  });

  testWidgets('topic detail localizes load more post errors in English', (
    tester,
  ) async {
    final api = TopicScreenApi()
      ..paginatePosts = true
      ..loadMoreTopicPostsError = const ApiException('话题不可用');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: TopicDetailScreen(
          repository: TopicRepository(api),
          initial: TopicSummary.fromJson(api.topic()),
          canInteract: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('topic-posts-load-more')));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not load more posts: This topic is unavailable.'),
      findsOneWidget,
    );
    expect(find.textContaining('话题不可用'), findsNothing);
  });

  testWidgets('topic plaza loads later recommended topics', (tester) async {
    final api = TopicScreenApi()..paginateTopics = true;
    await tester.pumpWidget(
      MaterialApp(
        home: TopicPlazaScreen(
          repository: TopicRepository(api),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('topic-plaza-load-more')), findsOneWidget);
    await tester.tap(find.byKey(const Key('topic-plaza-load-more')));
    await tester.pumpAndSettle();

    expect(api.requestedTopicPages, [1, 2]);
    expect(find.text('巴黎甜点'), findsOneWidget);
    expect(find.byKey(const Key('topic-plaza-load-more')), findsNothing);
  });

  testWidgets('topic plaza localizes load more errors in English', (
    tester,
  ) async {
    final api = TopicScreenApi()
      ..paginateTopics = true
      ..loadMoreTopicPageError = const ApiException('用户登录状态不存在');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: TopicPlazaScreen(
          repository: TopicRepository(api),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('topic-plaza-load-more')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not load more topics: Your sign-in session is no longer available. Please sign in again.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('用户登录状态不存在'), findsNothing);
  });

  testWidgets('topic plaza exposes three tabs and hot score composition', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TopicPlazaScreen(
          repository: TopicRepository(TopicScreenApi()),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('推荐'), findsOneWidget);
    expect(find.text('热榜'), findsOneWidget);
    expect(find.text('已关注'), findsOneWidget);
    await tester.tap(find.text('热榜'));
    await tester.pumpAndSettle();
    expect(find.text('TOP 1'), findsOneWidget);
    expect(find.text('热度 169'), findsOneWidget);
    expect(find.text('7 天：2 帖 · 3 赞 · 4 评论'), findsOneWidget);
  });

  testWidgets('topic plaza paginates tabs independently', (tester) async {
    final api = TopicScreenApi()..paginateTopics = true;
    final recommendedGate = Completer<void>();
    final hotGate = Completer<void>();
    api.topicPageGates['/api/c/v1/topics:2'] = recommendedGate;
    api.topicPageGates['/api/c/v1/topics/hot:2'] = hotGate;
    await tester.pumpWidget(
      MaterialApp(
        home: TopicPlazaScreen(
          repository: TopicRepository(api),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('topic-plaza-load-more')));
    await tester.pump();
    await tester.tap(find.text('热榜'));
    await tester.pumpAndSettle();

    final hotLoadMore = find.byKey(const Key('topic-plaza-load-more'));
    expect(tester.widget<OutlinedButton>(hotLoadMore).onPressed, isNotNull);
    await tester.tap(hotLoadMore);
    await tester.pump();
    expect(
      api.requestedTopicPageKeys,
      containsAll(<String>['/api/c/v1/topics:2', '/api/c/v1/topics/hot:2']),
    );

    recommendedGate.complete();
    hotGate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('guest following tab avoids protected request and shows guide', (
    tester,
  ) async {
    final api = TopicScreenApi();
    await tester.pumpWidget(
      MaterialApp(
        home: TopicPlazaScreen(
          repository: TopicRepository(api),
          canInteract: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('已关注'));
    await tester.pumpAndSettle();
    expect(find.textContaining('登录后查看关注的话题'), findsOneWidget);
    expect(api.followingCalls, 0);
  });

  testWidgets('topic detail renders posts and follows optimistically', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TopicPlazaScreen(
          repository: TopicRepository(TopicScreenApi()),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('伦敦咖啡'));
    await tester.pumpAndSettle();
    expect(find.text('周末咖啡地图'), findsOneWidget);
    expect(find.text('88 人关注'), findsOneWidget);
    expect(find.text('关注话题'), findsOneWidget);
    await tester.tap(find.text('关注话题'));
    await tester.pumpAndSettle();
    expect(find.text('已关注'), findsWidgets);
    expect(find.text('89 人关注'), findsOneWidget);
  });

  testWidgets('topic plaza guards duplicate detail navigation', (tester) async {
    final gate = Completer<void>();
    final api = TopicScreenApi()..postRetryGate = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: TopicPlazaScreen(
          repository: TopicRepository(api),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const Key('topic-card-31'));
    await tester.tap(card);
    await tester.tap(card, warnIfMissed: false);
    await tester.pump();

    expect(api.postCalls, 1);

    gate.complete();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(api.postCalls, 1);
  });

  testWidgets('topic detail guards duplicate follow requests', (tester) async {
    final gate = Completer<void>();
    final api = TopicScreenApi()..followGate = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: TopicDetailScreen(
          repository: TopicRepository(api),
          initial: TopicSummary.fromJson(api.topic()),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final follow = find.byKey(const Key('topic-follow-toggle'));
    await tester.tap(follow);
    await tester.tap(follow, warnIfMissed: false);
    await tester.pump();
    expect(api.followCalls, 1);
    expect(find.text('89 人关注'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.followCalls, 1);
    expect(find.text('已关注'), findsWidgets);
  });

  testWidgets('topic post opens the community post detail', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TopicDetailScreen(
          repository: TopicRepository(TopicScreenApi()),
          initial: TopicSummary.fromJson(TopicScreenApi().topic()),
          canInteract: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('周末咖啡地图'));
    await tester.pumpAndSettle();

    expect(find.text('帖子详情'), findsOneWidget);
    expect(find.text('三家新店实测。'), findsOneWidget);
  });

  testWidgets('topic detail guards duplicate post navigation', (tester) async {
    final gate = Completer<void>();
    final api = TopicScreenApi()..postDetailGate = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: TopicDetailScreen(
          repository: TopicRepository(api),
          initial: TopicSummary.fromJson(api.topic()),
          canInteract: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const Key('topic-post-card-7'));
    await tester.tap(card);
    await tester.tap(card, warnIfMissed: false);
    await tester.pump();

    expect(api.postDetailCalls, 1);

    gate.complete();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(api.postDetailCalls, 1);
    expect(api.postCalls, 1);
  });

  testWidgets('failed optimistic follow restores state and count', (
    tester,
  ) async {
    final api = TopicScreenApi()..failFollow = true;
    await tester.pumpWidget(
      MaterialApp(
        home: TopicDetailScreen(
          repository: TopicRepository(api),
          initial: TopicSummary.fromJson(api.topic()),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('关注话题'));
    await tester.pumpAndSettle();
    expect(find.text('关注话题'), findsOneWidget);
    expect(find.text('88 人关注'), findsOneWidget);
    expect(find.textContaining('关注状态更新失败'), findsOneWidget);
  });

  testWidgets('topic detail localizes follow errors in English', (
    tester,
  ) async {
    final api = TopicScreenApi()..followError = const ApiException('关注失败');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: TopicDetailScreen(
          repository: TopicRepository(api),
          initial: TopicSummary.fromJson(api.topic()),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Follow topic'));
    await tester.pumpAndSettle();

    expect(find.text('Follow topic'), findsOneWidget);
    expect(find.text('88 followers'), findsOneWidget);
    expect(
      find.text(
        'Could not update follow status: The follow request could not be completed.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('关注失败'), findsNothing);
  });
}
