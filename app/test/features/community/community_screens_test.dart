import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/community/community_feed_screen.dart';
import 'package:dazhongdianping_app/features/community/community_repository.dart';
import 'package:dazhongdianping_app/features/community/post_detail_screen.dart';
import 'package:dazhongdianping_app/features/community/post_editor_screen.dart';
import 'package:dazhongdianping_app/features/topic/topic_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CommunityScreenApi
    implements JsonApi, JsonMutationApi, JsonDeleteApi, FileUploadApi {
  String? path;
  String? postPath;
  String? deletePath;
  Object? body;
  bool reposted = false;
  int repostCount = 2;
  bool paginateFeed = false;
  bool failNextFeed = false;
  final List<int> requestedFeedPages = <int>[];
  bool paginateComments = false;
  bool failNextPost = false;
  bool failNextOwnedPost = false;
  bool failNextSave = false;
  bool failNextUpload = false;
  bool failNextLike = false;
  bool failNextComment = false;
  bool failNextCommentLoad = false;
  bool failNextReport = false;
  int postRequests = 0;
  int reportRequests = 0;
  int saveRequests = 0;
  int uploadRequests = 0;
  int ownedPostRequests = 0;
  Completer<void>? saveGate;
  Completer<void>? uploadGate;
  Completer<void>? ownedPostGate;
  final List<int> requestedCommentPages = <int>[];
  final commentPageGates = <int, Completer<void>>{};

  Map<String, dynamic> get post => {
    'id': 7,
    'userId': 9,
    'userName': '伦敦小王',
    'title': '伦敦周末市场指南',
    'content': '周六上午去选择最多，下午三点后不少摊位开始收摊。',
    'contentType': 1,
    'likeCount': 3,
    'commentCount': 1,
    'repostCount': repostCount,
    'repostedByCurrentUser': reposted,
    'auditStatus': 1,
    'auditStatusText': '审核通过',
    'auditRemark': '',
    'status': 1,
    'images': const ['https://files.example/market.jpg'],
    'topics': ['伦敦生活'],
    'createdAt': '2026-07-16 10:00:00',
  };

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    this.path = path;
    if (path.endsWith('/comments')) {
      final page = query?['page'] as int? ?? 1;
      requestedCommentPages.add(page);
      await commentPageGates[page]?.future;
      if (failNextCommentLoad) {
        failNextCommentLoad = false;
        throw StateError('comments unavailable');
      }
      return {
        'list': [
          {
            'id': page == 1 ? 11 : 13,
            'postId': 7,
            'userId': 10,
            'userName': page == 1 ? '评论用户' : '更早的用户',
            'content': page == 1 ? '收藏了。' : '更早的评论。',
            'parentId': 0,
            'replyTo': null,
            'replies': [
              {
                'id': 12,
                'postId': 7,
                'userId': 13,
                'userName': '楼中回复用户',
                'content': '我补一层楼中回复。',
                'parentId': 11,
                'replyTo': {
                  'id': 11,
                  'userId': 10,
                  'userName': '评论用户',
                  'content': '收藏了。',
                },
                'replies': [],
                'mine': false,
                'createdAt': '2026-07-16 11:10:00',
              },
            ],
            'mine': false,
            'createdAt': '2026-07-16 11:00:00',
          },
        ],
        'total': paginateComments ? 2 : 1,
        'page': page,
        'pageSize': paginateComments ? 1 : 50,
      };
    }
    if (path == '/api/c/v1/posts' || path == '/api/c/v1/posts/following') {
      if (path == '/api/c/v1/posts' && failNextFeed) {
        failNextFeed = false;
        throw StateError('feed network unavailable');
      }
      final page = query?['page'] as int? ?? 1;
      requestedFeedPages.add(page);
      return {
        'list': [
          if (!paginateFeed || page == 1)
            post
          else
            {...post, 'id': 8, 'title': '更早的社区帖子'},
        ],
        'total': paginateFeed ? 2 : 1,
        'page': page,
        'pageSize': paginateFeed ? 1 : 30,
      };
    }
    if (path == '/api/c/v1/posts/7') {
      postRequests++;
      if (failNextPost) {
        failNextPost = false;
        throw StateError('network unavailable');
      }
    }
    if (path == '/api/c/v1/user/posts/7') {
      ownedPostRequests++;
      await ownedPostGate?.future;
      if (failNextOwnedPost) {
        failNextOwnedPost = false;
        throw StateError('owned post unavailable');
      }
    }
    return post;
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    this.path = path;
    postPath = path;
    this.body = body;
    if (path.endsWith('/report')) reportRequests++;
    if (path == '/api/c/v1/posts' && failNextSave) {
      failNextSave = false;
      throw StateError('save unavailable');
    }
    if (path == '/api/c/v1/posts') {
      saveRequests++;
      await saveGate?.future;
    }
    if (path.endsWith('/like')) {
      if (failNextLike) {
        failNextLike = false;
        throw StateError('like unavailable');
      }
      return {'liked': true, 'likeCount': 4};
    }
    if (path.endsWith('/repost')) {
      reposted = true;
      repostCount = 3;
      return {'postId': 7, 'reposted': true, 'repostCount': repostCount};
    }
    if (path.endsWith('/comments')) {
      if (failNextComment) {
        failNextComment = false;
        throw StateError('comment unavailable');
      }
      return {
        'id': 12,
        'postId': 7,
        'userId': 9,
        'userName': '当前用户',
        'content': (body as Map)['content'],
        'parentId': body['replyTo'] ?? 0,
        'replyTo': body['replyTo'] == null
            ? null
            : {
                'id': body['replyTo'],
                'userId': 10,
                'userName': '评论用户',
                'content': '收藏了。',
              },
        'replies': const [],
        'mine': true,
        'createdAt': '2026-07-16 12:00:00',
      };
    }
    if (path.endsWith('/report') && failNextReport) {
      failNextReport = false;
      throw StateError('report unavailable');
    }
    return post;
  }

  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async =>
      post;
  @override
  Future<Map<String, dynamic>> deleteJson(String path) async {
    deletePath = path;
    if (path.endsWith('/repost')) {
      reposted = false;
      repostCount = 2;
      return {'postId': 7, 'reposted': false, 'repostCount': repostCount};
    }
    return const {};
  }

  @override
  Future<Map<String, dynamic>> uploadBytes(
    String path, {
    required String fieldName,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    this.path = path;
    uploadRequests++;
    await uploadGate?.future;
    if (failNextUpload) {
      failNextUpload = false;
      throw StateError('upload unavailable');
    }
    return {'url': '/uploads/$fileName'};
  }
}

class FakeCommunityImagePicker implements CommunityImagePicker {
  @override
  Future<CommunityImageUpload?> pickImage() async => CommunityImageUpload(
    bytes: base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    ),
    fileName: 'market.png',
    contentType: 'image/png',
  );
}

class FailingCommunityImagePicker implements CommunityImagePicker {
  @override
  Future<CommunityImageUpload?> pickImage() async {
    throw StateError('picker unavailable');
  }
}

class GatedCommunityImagePicker implements CommunityImagePicker {
  final gate = Completer<void>();
  int calls = 0;

  @override
  Future<CommunityImageUpload?> pickImage() async {
    calls++;
    await gate.future;
    return CommunityImageUpload(
      bytes: Uint8List.fromList([1]),
      fileName: 'gated.png',
      contentType: 'image/png',
    );
  }
}

class CommunityTopicApi extends CommunityScreenApi {
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (path.startsWith('/api/c/v1/topics')) {
      return {
        'list': [
          {
            'id': 31,
            'region': 'EU',
            'name': '伦敦咖啡',
            'postCount': 12,
            'followerCount': 88,
            'recommended': true,
            'pinnedSort': 0,
            'followedByCurrentUser': false,
            'hotScore': 169,
            'postCount7d': 2,
            'likeCount7d': 3,
            'commentCount7d': 4,
            'calculatedAt': '2026-07-17 19:00:00',
          },
        ],
        'total': 1,
      };
    }
    return super.getJson(path, query: query);
  }
}

void main() {
  testWidgets('community feed retries an initial load failure', (tester) async {
    final api = CommunityScreenApi()..failNextFeed = true;
    await tester.pumpWidget(
      MaterialApp(
        home: CommunityFeedScreen(
          repository: CommunityRepository(api),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('社区加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('community-feed-retry')));
    await tester.pumpAndSettle();

    expect(api.requestedFeedPages, [1]);
    expect(find.text('伦敦周末市场指南'), findsOneWidget);
  });

  testWidgets('post detail retries an initial load failure', (tester) async {
    final api = CommunityScreenApi()..failNextPost = true;
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          repository: CommunityRepository(api),
          postId: 7,
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('帖子加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('post-detail-retry')));
    await tester.pumpAndSettle();

    expect(api.postRequests, 2);
    expect(api.requestedCommentPages, [1, 1]);
    expect(find.text('伦敦周末市场指南'), findsOneWidget);
  });

  testWidgets('post detail loads later comment pages', (tester) async {
    final api = CommunityScreenApi()..paginateComments = true;
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          repository: CommunityRepository(api),
          postId: 7,
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('post-comments-load-more')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('post-comments-load-more')), findsOneWidget);
    await tester.tap(find.byKey(const Key('post-comments-load-more')));
    await tester.pumpAndSettle();

    expect(api.requestedCommentPages, [1, 2]);
    expect(find.text('更早的评论。'), findsOneWidget);
    expect(find.byKey(const Key('post-comments-load-more')), findsNothing);
  });

  testWidgets('new comment invalidates a pending older comment page', (
    tester,
  ) async {
    final gate = Completer<void>();
    final api = CommunityScreenApi()
      ..paginateComments = true
      ..commentPageGates[2] = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          repository: CommunityRepository(api),
          postId: 7,
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('post-comments-load-more')),
      500,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.byKey(const Key('post-comments-load-more')));
    await tester.pump();
    expect(api.requestedCommentPages, [1, 2]);

    await tester.enterText(find.byType(TextField).last, '刷新评论分页');
    await tester.tap(find.byKey(const Key('post-comment-submit')));
    await tester.pumpAndSettle();
    expect(api.requestedCommentPages, [1, 2, 1]);

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('更早的评论。'), findsNothing);
  });

  testWidgets('post detail retries an initial comment failure locally', (
    tester,
  ) async {
    final api = CommunityScreenApi()..failNextCommentLoad = true;
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          repository: CommunityRepository(api),
          postId: 7,
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.textContaining('评论加载失败'), findsOneWidget);
    expect(api.postRequests, 1);

    await tester.tap(find.byKey(const Key('post-comments-retry')));
    await tester.pumpAndSettle();

    expect(find.text('收藏了。'), findsOneWidget);
    expect(api.requestedCommentPages, [1, 1]);
    expect(api.postRequests, 1);
  });

  testWidgets('community feed loads later pages', (tester) async {
    final api = CommunityScreenApi()..paginateFeed = true;
    await tester.pumpWidget(
      MaterialApp(
        home: CommunityFeedScreen(
          repository: CommunityRepository(api),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('community-feed-load-more')), findsOneWidget);
    await tester.tap(find.byKey(const Key('community-feed-load-more')));
    await tester.pumpAndSettle();

    expect(api.requestedFeedPages, [1, 2]);
    expect(find.text('更早的社区帖子'), findsOneWidget);
    expect(find.byKey(const Key('community-feed-load-more')), findsNothing);
  });

  testWidgets('community feed opens the topic plaza entry', (tester) async {
    final api = CommunityTopicApi();
    await tester.pumpWidget(
      MaterialApp(
        home: CommunityFeedScreen(
          repository: CommunityRepository(api),
          topicRepository: TopicRepository(api),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('话题广场'));
    await tester.pumpAndSettle();
    expect(find.text('话题广场'), findsOneWidget);
    expect(find.text('伦敦咖啡'), findsOneWidget);
  });

  testWidgets(
    'community feed does not reload after disposal while editor is open',
    (tester) async {
      final showFeed = ValueNotifier(true);
      addTearDown(showFeed.dispose);
      final repository = CommunityRepository(CommunityScreenApi());
      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: showFeed,
            builder: (_, visible, _) => visible
                ? CommunityFeedScreen(repository: repository, canInteract: true)
                : const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('发帖'));
      await tester.pumpAndSettle();
      expect(find.byType(PostEditorScreen), findsOneWidget);

      showFeed.value = false;
      await tester.pump();
      expect(
        find.byType(CommunityFeedScreen, skipOffstage: false),
        findsNothing,
      );

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('community feed guards duplicate editor navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CommunityFeedScreen(
          repository: CommunityRepository(CommunityScreenApi()),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final create = find.byKey(const Key('community-create-post'));
    final openEditor = tester.widget<FloatingActionButton>(create).onPressed!;
    openEditor();
    openEditor();
    await tester.pumpAndSettle();

    expect(find.byType(PostEditorScreen, skipOffstage: false), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  });

  testWidgets('community feed opens a readable post detail', (tester) async {
    final api = CommunityScreenApi();
    final repository = CommunityRepository(api);
    await tester.pumpWidget(
      MaterialApp(
        home: CommunityFeedScreen(repository: repository, canInteract: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('伦敦周末市场指南'), findsOneWidget);
    expect(find.text('#伦敦生活'), findsOneWidget);
    await tester.tap(find.text('伦敦周末市场指南'));
    await tester.pumpAndSettle();

    expect(find.textContaining('下午三点后'), findsOneWidget);
    expect(find.byKey(const Key('post-image-0')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('收藏帖子'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('收藏帖子'));
    await tester.pumpAndSettle();
    expect(api.path, '/api/c/v1/favorites');
    expect(api.body, {'targetType': 2, 'targetId': 7});
    expect(find.text('取消收藏'), findsOneWidget);

    await tester.tap(find.text('取消收藏'));
    await tester.pumpAndSettle();
    expect(api.deletePath, '/api/c/v1/favorites?targetType=2&targetId=7');

    await tester.tap(find.text('转发 2'));
    await tester.pumpAndSettle();
    expect(api.postPath, '/api/c/v1/posts/7/repost');
    expect(find.text('取消转发 3'), findsOneWidget);

    await tester.ensureVisible(find.text('取消转发 3'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消转发 3'));
    await tester.pumpAndSettle();
    expect(api.deletePath, '/api/c/v1/posts/7/repost');
    expect(find.text('转发 2'), findsOneWidget);

    await tester.tap(find.text('举报'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('post-report-reason')),
      '内容已经过期',
    );
    await tester.tap(find.text('提交举报'));
    await tester.pumpAndSettle();
    expect(api.path, '/api/c/v1/posts/7/report');
    expect(api.body, {'reason': '内容已经过期'});

    await tester.scrollUntilVisible(
      find.text('收藏了。'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('收藏了。'), findsOneWidget);
    expect(find.text('我补一层楼中回复。'), findsOneWidget);
  });

  testWidgets('post detail can reply to a threaded comment', (tester) async {
    final api = CommunityScreenApi();
    await tester.pumpWidget(
      MaterialApp(
        home: CommunityFeedScreen(
          repository: CommunityRepository(api),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('伦敦周末市场指南'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('comment-reply-11')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('comment-reply-11')));
    await tester.pumpAndSettle();
    expect(find.textContaining('正在回复 评论用户'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '楼中回复');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(api.postPath, '/api/c/v1/posts/7/comments');
    expect(api.body, {'content': '楼中回复', 'replyTo': 11});
  });

  testWidgets('post detail recovers failed like and comment actions', (
    tester,
  ) async {
    final api = CommunityScreenApi()
      ..failNextLike = true
      ..failNextComment = true;
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          repository: CommunityRepository(api),
          postId: 7,
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('post-like-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('点赞失败'), findsOneWidget);
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('post-like-button')))
          .onPressed,
      isNotNull,
    );
    ScaffoldMessenger.of(
      tester.element(find.byKey(const Key('post-like-button'))),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('post-comment-submit')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField).last, '失败后保留的评论');
    await tester.tap(find.byKey(const Key('post-comment-submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('评论失败'), findsOneWidget);
    expect(find.text('失败后保留的评论'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('post-comment-submit')))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.byKey(const Key('post-comment-submit')));
    await tester.pumpAndSettle();
    expect(api.body, {'content': '失败后保留的评论'});
  });

  testWidgets('post detail updates like and repost without reloading itself', (
    tester,
  ) async {
    final api = CommunityScreenApi();
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          repository: CommunityRepository(api),
          postId: 7,
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('post-like-button')));
    await tester.pumpAndSettle();
    expect(find.text('点赞 4'), findsOneWidget);
    expect(api.postRequests, 1);
    ScaffoldMessenger.of(
      tester.element(find.byType(PostDetailScreen)),
    ).clearSnackBars();
    await tester.pumpAndSettle();

    await tester.tap(find.text('转发 2'));
    await tester.pumpAndSettle();
    expect(find.text('取消转发 3'), findsOneWidget);
    expect(api.postRequests, 1);
  });

  testWidgets('post detail updates comment count without reloading itself', (
    tester,
  ) async {
    final api = CommunityScreenApi();
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          repository: CommunityRepository(api),
          postId: 7,
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('post-comment-submit')),
      180,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.enterText(find.byType(TextField).last, '新增一条评论');
    await tester.tap(find.byKey(const Key('post-comment-submit')));
    await tester.pumpAndSettle();

    expect(api.body, {'content': '新增一条评论'});
    expect(api.postRequests, 1);
    expect(api.requestedCommentPages, [1, 1]);
  });

  testWidgets('post detail preserves a failed report reason for retry', (
    tester,
  ) async {
    final api = CommunityScreenApi()..failNextReport = true;
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          repository: CommunityRepository(api),
          postId: 7,
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('post-report-button')),
      180,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.byKey(const Key('post-report-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('post-report-reason')),
      '需要重试的举报理由',
    );
    await tester.tap(find.text('提交举报'));
    await tester.pumpAndSettle();
    expect(find.textContaining('举报提交失败'), findsOneWidget);

    await tester.tap(find.byKey(const Key('post-report-button')));
    await tester.pumpAndSettle();
    expect(find.text('需要重试的举报理由'), findsOneWidget);
    await tester.tap(find.text('提交举报'));
    await tester.pumpAndSettle();

    expect(api.body, {'reason': '需要重试的举报理由'});
    expect(api.reportRequests, 2);

    await tester.tap(find.byKey(const Key('post-report-button')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('post-report-reason')))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('post detail guards duplicate report dialogs', (tester) async {
    final api = CommunityScreenApi();
    await tester.pumpWidget(
      MaterialApp(
        home: PostDetailScreen(
          repository: CommunityRepository(api),
          postId: 7,
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final report = find.byKey(const Key('post-report-button'));
    await tester.scrollUntilVisible(
      report,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    final reportAction = tester.widget<TextButton>(report).onPressed!;

    reportAction();
    reportAction();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('举报帖子'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(api.reportRequests, 0);
  });

  testWidgets('community author opens the public user profile callback', (
    tester,
  ) async {
    int? openedUserId;
    await tester.pumpWidget(
      MaterialApp(
        home: CommunityFeedScreen(
          repository: CommunityRepository(CommunityScreenApi()),
          canInteract: true,
          onUserTap: (_, userId) => openedUserId = userId,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('伦敦小王'));
    expect(openedUserId, 9);
  });

  testWidgets('community feed shows recommendation and following tabs', (
    tester,
  ) async {
    final api = CommunityScreenApi();
    await tester.pumpWidget(
      MaterialApp(
        home: CommunityFeedScreen(
          repository: CommunityRepository(api),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('推荐'), findsOneWidget);
    expect(find.text('关注'), findsOneWidget);
    await tester.tap(find.text('关注'));
    await tester.pumpAndSettle();
    expect(api.path, '/api/c/v1/posts/following');
  });

  testWidgets(
    'guest following tab shows a login guide without a protected request',
    (tester) async {
      final api = CommunityScreenApi();
      await tester.pumpWidget(
        MaterialApp(
          home: CommunityFeedScreen(
            repository: CommunityRepository(api),
            canInteract: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('关注'));
      await tester.pumpAndSettle();
      expect(find.textContaining('登录后查看关注流'), findsOneWidget);
      expect(api.path, '/api/c/v1/posts');
    },
  );

  testWidgets('post editor uploads an image and submits a post', (
    tester,
  ) async {
    final api = CommunityScreenApi();
    await tester.pumpWidget(
      MaterialApp(
        home: PostEditorScreen(
          repository: CommunityRepository(api),
          imagePicker: FakeCommunityImagePicker(),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('post-title')), '柏林超市补货观察');
    await tester.enterText(find.byKey(const Key('post-content')), '周五下午选择最多。');
    await tester.enterText(find.byKey(const Key('post-topics')), '柏林生活, 亚洲超市');
    await tester.ensureVisible(find.byKey(const Key('post-add-image')));
    await tester.tap(find.byKey(const Key('post-add-image')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('post-submit')));
    await tester.tap(find.byKey(const Key('post-submit')));
    await tester.pumpAndSettle();

    expect(api.path, '/api/c/v1/posts');
    expect(api.body, containsPair('images', ['/uploads/market.png']));
  });

  testWidgets('post editor guards duplicate image picking', (tester) async {
    final api = CommunityScreenApi();
    final picker = GatedCommunityImagePicker();
    await tester.pumpWidget(
      MaterialApp(
        home: PostEditorScreen(
          repository: CommunityRepository(api),
          imagePicker: picker,
        ),
      ),
    );

    final addImage = find.byKey(const Key('post-add-image'));
    await tester.ensureVisible(addImage);
    await tester.tap(addImage);
    await tester.tap(addImage);

    expect(picker.calls, 1);
    picker.gate.complete();
    await tester.pumpAndSettle();
    expect(api.uploadRequests, 1);
    expect(find.text('已上传 1/9'), findsOneWidget);
  });

  testWidgets('post editor guards duplicate submission', (tester) async {
    final api = CommunityScreenApi()..saveGate = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(home: PostEditorScreen(repository: CommunityRepository(api))),
    );

    await tester.enterText(find.byKey(const Key('post-title')), '待提交标题');
    await tester.enterText(find.byKey(const Key('post-content')), '待提交正文');
    final submit = find.byKey(const Key('post-submit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.tap(submit);

    expect(api.saveRequests, 1);
    api.saveGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('post editor reports upload failure and remains usable', (
    tester,
  ) async {
    final api = CommunityScreenApi()..failNextUpload = true;
    await tester.pumpWidget(
      MaterialApp(
        home: PostEditorScreen(
          repository: CommunityRepository(api),
          imagePicker: FakeCommunityImagePicker(),
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('post-add-image')));
    await tester.tap(find.byKey(const Key('post-add-image')));
    await tester.pumpAndSettle();

    expect(find.textContaining('图片上传失败'), findsOneWidget);
    expect(find.text('已上传 0/9'), findsOneWidget);
    expect(find.byKey(const Key('post-add-image')), findsOneWidget);
  });

  testWidgets('post editor reports image picker failure', (tester) async {
    final api = CommunityScreenApi();
    await tester.pumpWidget(
      MaterialApp(
        home: PostEditorScreen(
          repository: CommunityRepository(api),
          imagePicker: FailingCommunityImagePicker(),
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('post-add-image')));
    await tester.tap(find.byKey(const Key('post-add-image')));
    await tester.pumpAndSettle();

    expect(find.textContaining('图片选择失败'), findsOneWidget);
    expect(find.text('已上传 0/9'), findsOneWidget);
    expect(api.path, isNull);
  });

  testWidgets('post editor reports save failure and preserves form data', (
    tester,
  ) async {
    final api = CommunityScreenApi()..failNextSave = true;
    await tester.pumpWidget(
      MaterialApp(home: PostEditorScreen(repository: CommunityRepository(api))),
    );

    await tester.enterText(find.byKey(const Key('post-title')), '待重试标题');
    await tester.enterText(find.byKey(const Key('post-content')), '待重试正文');
    await tester.ensureVisible(find.byKey(const Key('post-submit')));
    await tester.tap(find.byKey(const Key('post-submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('帖子保存失败'), findsOneWidget);
    expect(find.text('待重试标题'), findsOneWidget);
    expect(find.text('待重试正文'), findsOneWidget);
    expect(find.byKey(const Key('post-submit')), findsOneWidget);
  });

  testWidgets('post editor loads an owned post for editing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PostEditorScreen(
          repository: CommunityRepository(CommunityScreenApi()),
          postId: 7,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('编辑帖子'), findsOneWidget);
    expect(find.text('伦敦周末市场指南'), findsOneWidget);
    expect(find.textContaining('周六上午'), findsOneWidget);
  });

  testWidgets('post editor blocks an incomplete form and retries loading', (
    tester,
  ) async {
    final api = CommunityScreenApi()..failNextOwnedPost = true;
    await tester.pumpWidget(
      MaterialApp(
        home: PostEditorScreen(repository: CommunityRepository(api), postId: 7),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('帖子编辑数据加载失败'), findsOneWidget);
    expect(find.byKey(const Key('post-title')), findsNothing);
    expect(find.byKey(const Key('post-submit')), findsNothing);

    await tester.tap(find.byKey(const Key('post-editor-retry')));
    await tester.pumpAndSettle();

    expect(find.text('伦敦周末市场指南'), findsOneWidget);
    expect(find.textContaining('周六上午'), findsOneWidget);
    expect(find.byKey(const Key('post-submit')), findsOneWidget);
  });

  testWidgets('post editor guards duplicate load retries', (tester) async {
    final gate = Completer<void>();
    final api = CommunityScreenApi()..failNextOwnedPost = true;
    await tester.pumpWidget(
      MaterialApp(
        home: PostEditorScreen(repository: CommunityRepository(api), postId: 7),
      ),
    );
    await tester.pumpAndSettle();
    api.ownedPostGate = gate;

    final retry = find.byKey(const Key('post-editor-retry'));
    await tester.tap(retry);
    await tester.tap(retry);
    await tester.pump();
    expect(api.ownedPostRequests, 2);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.ownedPostRequests, 2);
    expect(find.byKey(const Key('post-submit')), findsOneWidget);
  });

  testWidgets('post editor can delete an owned post', (tester) async {
    final api = CommunityScreenApi();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              key: const Key('open-post-editor'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PostEditorScreen(
                    repository: CommunityRepository(api),
                    postId: 7,
                  ),
                ),
              ),
              child: const Text('打开帖子编辑'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-post-editor')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('post-delete-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('post-delete-confirm')));
    await tester.pumpAndSettle();

    expect(api.deletePath, '/api/c/v1/posts/7');
    expect(find.text('编辑帖子'), findsNothing);
    expect(find.byKey(const Key('open-post-editor')), findsOneWidget);
  });

  testWidgets('post editor guards duplicate delete dialogs', (tester) async {
    final api = CommunityScreenApi();
    await tester.pumpWidget(
      MaterialApp(
        home: PostEditorScreen(repository: CommunityRepository(api), postId: 7),
      ),
    );
    await tester.pumpAndSettle();

    final delete = find.byKey(const Key('post-delete-button'));
    final deleteAction = tester.widget<TextButton>(delete).onPressed!;
    deleteAction();
    deleteAction();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('删除帖子'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(api.deletePath, isNull);
  });
}
