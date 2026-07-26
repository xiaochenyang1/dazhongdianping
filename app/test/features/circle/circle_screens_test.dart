import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/circle/circle_repository.dart';
import 'package:dazhongdianping_app/features/circle/circle_square_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CircleScreenApi implements JsonApi, JsonMutationApi, JsonDeleteApi {
  bool paginateCircles = false;
  final List<int> requestedCirclePages = <int>[];
  bool paginatePosts = false;
  final List<int> requestedPostPages = <int>[];
  bool paginateMembers = false;
  final List<int> requestedMemberPages = <int>[];
  Map<String, dynamic> circle({bool joined = false, int count = 12}) => {
    'id': 3,
    'region': 'EU',
    'name': '伦敦生活圈',
    'description': '英国华人本地生活',
    'coverUrl': '',
    'memberCount': count,
    'postCount': 8,
    'sort': 20,
    'status': 1,
    'joinedByCurrentUser': joined,
  };
  Map<String, dynamic> get post => {
    'id': 7,
    'userId': 9,
    'userName': '伦敦小王',
    'circleId': 3,
    'circleName': '伦敦生活圈',
    'title': '周末市集指南',
    'content': '本周六开放',
    'contentType': 1,
    'likeCount': 2,
    'commentCount': 1,
    'auditStatus': 1,
    'auditStatusText': '审核通过',
    'auditRemark': '',
    'images': const [],
    'topics': const [],
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
    if (path.endsWith('/members')) {
      final page = query?['page'] as int? ?? 1;
      requestedMemberPages.add(page);
      return {
        'list': [
          {
            'id': page == 1 ? 9 : 10,
            'nickname': page == 1 ? '伦敦小王' : '巴黎小李',
            'avatar': '',
            'signature': '探店',
            'level': 4,
            'joinedAt': '2026-07-17 10:00:00',
          },
        ],
        'total': paginateMembers ? 2 : 1,
        'page': page,
        'pageSize': paginateMembers ? 1 : 50,
      };
    }
    if (path.endsWith('/posts')) {
      final page = query?['page'] as int? ?? 1;
      requestedPostPages.add(page);
      return {
        'list': [
          if (!paginatePosts || page == 1)
            post
          else
            {...post, 'id': 8, 'title': '更早的圈子帖子'},
        ],
        'total': paginatePosts ? 2 : 1,
        'page': page,
        'pageSize': paginatePosts ? 1 : 30,
      };
    }
    if (path.endsWith('/3')) return circle();
    final page = query?['page'] as int? ?? 1;
    requestedCirclePages.add(page);
    return {
      'list': [
        if (!paginateCircles || page == 1)
          circle()
        else
          {...circle(), 'id': 4, 'name': '巴黎生活圈'},
      ],
      'total': paginateCircles ? 2 : 1,
      'page': page,
      'pageSize': paginateCircles ? 1 : 30,
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      {};
  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async => {
    'circleId': 3,
    'joined': true,
    'memberCount': 13,
  };
  @override
  Future<Map<String, dynamic>> deleteJson(String path) async => {
    'circleId': 3,
    'joined': false,
    'memberCount': 12,
  };
}

void main() {
  testWidgets('circle members screen loads later members', (tester) async {
    final api = CircleScreenApi()..paginateMembers = true;
    await tester.pumpWidget(
      MaterialApp(
        home: CircleMembersScreen(
          repository: CircleRepository(api),
          circle: AppCircle.fromJson(api.circle()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('circle-members-load-more')), findsOneWidget);
    await tester.tap(find.byKey(const Key('circle-members-load-more')));
    await tester.pumpAndSettle();

    expect(api.requestedMemberPages, [1, 2]);
    expect(find.text('巴黎小李'), findsOneWidget);
    expect(find.byKey(const Key('circle-members-load-more')), findsNothing);
  });

  testWidgets('circle detail loads later posts', (tester) async {
    final api = CircleScreenApi()..paginatePosts = true;
    await tester.pumpWidget(
      MaterialApp(
        home: CircleDetailScreen(
          repository: CircleRepository(api),
          initial: AppCircle.fromJson(api.circle()),
          canInteract: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('circle-posts-load-more')), findsOneWidget);
    await tester.tap(find.byKey(const Key('circle-posts-load-more')));
    await tester.pumpAndSettle();

    expect(api.requestedPostPages, [1, 2]);
    expect(find.text('更早的圈子帖子'), findsOneWidget);
    expect(find.byKey(const Key('circle-posts-load-more')), findsNothing);
  });

  testWidgets('circle square loads later circles', (tester) async {
    final api = CircleScreenApi()..paginateCircles = true;
    await tester.pumpWidget(
      MaterialApp(
        home: CircleSquareScreen(
          repository: CircleRepository(api),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('circle-square-load-more')), findsOneWidget);
    await tester.tap(find.byKey(const Key('circle-square-load-more')));
    await tester.pumpAndSettle();

    expect(api.requestedCirclePages, [1, 2]);
    expect(find.text('巴黎生活圈'), findsOneWidget);
    expect(find.byKey(const Key('circle-square-load-more')), findsNothing);
  });

  testWidgets('circle square opens detail and joins optimistically', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CircleSquareScreen(
          repository: CircleRepository(CircleScreenApi()),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('伦敦生活圈'), findsOneWidget);
    expect(find.textContaining('12 位成员'), findsOneWidget);
    await tester.tap(find.text('伦敦生活圈'));
    await tester.pumpAndSettle();
    expect(find.text('加入圈子'), findsOneWidget);
    expect(find.text('周末市集指南'), findsOneWidget);
    await tester.tap(find.text('加入圈子'));
    await tester.pumpAndSettle();
    expect(find.text('已加入'), findsOneWidget);
    expect(find.textContaining('13 位成员'), findsOneWidget);
  });

  testWidgets('circle post opens the community post detail', (tester) async {
    final api = CircleScreenApi();
    await tester.pumpWidget(
      MaterialApp(
        home: CircleDetailScreen(
          repository: CircleRepository(api),
          initial: AppCircle.fromJson(api.circle()),
          canInteract: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('周末市集指南'));
    await tester.pumpAndSettle();

    expect(find.text('帖子详情'), findsOneWidget);
    expect(find.text('本周六开放'), findsOneWidget);
  });
}
