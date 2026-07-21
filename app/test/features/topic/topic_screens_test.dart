import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/topic/topic_detail_screen.dart';
import 'package:dazhongdianping_app/features/topic/topic_plaza_screen.dart';
import 'package:dazhongdianping_app/features/topic/topic_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TopicScreenApi implements JsonApi, JsonMutationApi, JsonDeleteApi {
  int followingCalls = 0;
  bool failFollow = false;

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
    if (path == '/api/c/v1/posts/7') return post;
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
      return {
        'list': [post],
        'total': 1,
      };
    }
    if (path == '/api/c/v1/topics/31') return topic();
    return {
      'list': [topic()],
      'total': 1,
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async => {};

  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
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

void main() {
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
}
