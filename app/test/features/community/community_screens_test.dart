import 'dart:convert';
import 'dart:typed_data';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/community/community_feed_screen.dart';
import 'package:dazhongdianping_app/features/community/community_repository.dart';
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
      return {
        'list': [
          {
            'id': 11,
            'postId': 7,
            'userId': 10,
            'userName': '评论用户',
            'content': '收藏了。',
            'createdAt': '2026-07-16 11:00:00',
          },
        ],
        'total': 1,
      };
    }
    if (path == '/api/c/v1/posts' || path == '/api/c/v1/posts/following') {
      return {
        'list': [post],
        'total': 1,
      };
    }
    return post;
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    this.path = path;
    postPath = path;
    this.body = body;
    if (path.endsWith('/like')) return {'liked': true, 'likeCount': 4};
    if (path.endsWith('/repost')) {
      reposted = true;
      repostCount = 3;
      return {'postId': 7, 'reposted': true, 'repostCount': repostCount};
    }
    if (path.endsWith('/comments')) {
      return {
        'id': 12,
        'postId': 7,
        'userId': 9,
        'userName': '当前用户',
        'content': (body as Map)['content'],
        'createdAt': '2026-07-16 12:00:00',
      };
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
}
