import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/circle/circle_repository.dart';
import 'package:dazhongdianping_app/features/circle/circle_square_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CircleScreenApi implements JsonApi, JsonMutationApi, JsonDeleteApi {
  bool paginateCircles = false;
  bool failNextCircles = false;
  final List<int> requestedCirclePages = <int>[];
  Completer<void>? circleRetryGate;
  bool paginatePosts = false;
  bool failNextPosts = false;
  final List<int> requestedPostPages = <int>[];
  Completer<void>? postRetryGate;
  int postCalls = 0;
  Completer<void>? postDetailGate;
  int postDetailCalls = 0;
  bool paginateMembers = false;
  bool failNextMembers = false;
  final List<int> requestedMemberPages = <int>[];
  Completer<void>? memberRetryGate;
  int memberCalls = 0;
  Completer<void>? membershipGate;
  int membershipCalls = 0;
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
    if (path == '/api/c/v1/posts/7') {
      postDetailCalls++;
      await postDetailGate?.future;
      return post;
    }
    if (path == '/api/c/v1/posts/7/comments') {
      return {'list': const [], 'total': 0};
    }
    if (path.endsWith('/members')) {
      memberCalls++;
      if (failNextMembers) {
        failNextMembers = false;
        throw StateError('member network unavailable');
      }
      await memberRetryGate?.future;
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
      postCalls++;
      if (failNextPosts) {
        failNextPosts = false;
        throw StateError('post network unavailable');
      }
      await postRetryGate?.future;
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
    if (failNextCircles) {
      failNextCircles = false;
      throw StateError('circle network unavailable');
    }
    await circleRetryGate?.future;
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
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    membershipCalls++;
    await membershipGate?.future;
    return {'circleId': 3, 'joined': true, 'memberCount': 13};
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path) async => {
    'circleId': 3,
    'joined': false,
    'memberCount': 12,
  };
}

void main() {
  testWidgets('circle square retries an initial load failure', (tester) async {
    final api = CircleScreenApi()..failNextCircles = true;
    await tester.pumpWidget(
      MaterialApp(
        home: CircleSquareScreen(
          repository: CircleRepository(api),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('圈子加载失败'), findsOneWidget);

    await tester.tap(find.byKey(const Key('circle-square-retry')));
    await tester.pumpAndSettle();
    expect(api.requestedCirclePages, [1]);
    expect(find.text('伦敦生活圈'), findsOneWidget);
  });

  testWidgets('circle square guards duplicate retries', (tester) async {
    final gate = Completer<void>();
    final api = CircleScreenApi()
      ..failNextCircles = true
      ..circleRetryGate = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: CircleSquareScreen(
          repository: CircleRepository(api),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('circle-square-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(api.requestedCirclePages, isEmpty);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.requestedCirclePages, [1]);
    expect(find.text('伦敦生活圈'), findsOneWidget);
  });

  testWidgets('circle detail retries an initial post failure', (tester) async {
    final api = CircleScreenApi()..failNextPosts = true;
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
    expect(find.textContaining('帖子加载失败'), findsOneWidget);

    await tester.tap(find.byKey(const Key('circle-posts-retry')));
    await tester.pumpAndSettle();
    expect(api.requestedPostPages, [1]);
    expect(find.text('周末市集指南'), findsOneWidget);
  });

  testWidgets('circle detail guards duplicate post retries', (tester) async {
    final gate = Completer<void>();
    final api = CircleScreenApi()
      ..failNextPosts = true
      ..postRetryGate = gate;
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

    final retry = find.byKey(const Key('circle-posts-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(api.requestedPostPages, isEmpty);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.requestedPostPages, [1]);
    expect(find.text('周末市集指南'), findsOneWidget);
  });

  testWidgets('circle members retry an initial load failure', (tester) async {
    final api = CircleScreenApi()..failNextMembers = true;
    await tester.pumpWidget(
      MaterialApp(
        home: CircleMembersScreen(
          repository: CircleRepository(api),
          circle: AppCircle.fromJson(api.circle()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('成员加载失败'), findsOneWidget);

    await tester.tap(find.byKey(const Key('circle-members-retry')));
    await tester.pumpAndSettle();
    expect(api.requestedMemberPages, [1]);
    expect(find.text('伦敦小王'), findsOneWidget);
  });

  testWidgets('circle members guard duplicate retries', (tester) async {
    final gate = Completer<void>();
    final api = CircleScreenApi()
      ..failNextMembers = true
      ..memberRetryGate = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: CircleMembersScreen(
          repository: CircleRepository(api),
          circle: AppCircle.fromJson(api.circle()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('circle-members-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(api.requestedMemberPages, isEmpty);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.requestedMemberPages, [1]);
    expect(find.text('伦敦小王'), findsOneWidget);
  });

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

  testWidgets('circle square guards duplicate detail navigation', (
    tester,
  ) async {
    final gate = Completer<void>();
    final api = CircleScreenApi()..postRetryGate = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: CircleSquareScreen(
          repository: CircleRepository(api),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const Key('circle-card-3'));
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

  testWidgets('circle detail guards duplicate membership requests', (
    tester,
  ) async {
    final gate = Completer<void>();
    final api = CircleScreenApi()..membershipGate = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: CircleDetailScreen(
          repository: CircleRepository(api),
          initial: AppCircle.fromJson(api.circle()),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final toggle = find.byKey(const Key('circle-membership-toggle'));
    await tester.tap(toggle);
    await tester.tap(toggle, warnIfMissed: false);
    await tester.pump();
    expect(api.membershipCalls, 1);
    expect(find.textContaining('13 位成员'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.membershipCalls, 1);
    expect(find.text('已加入'), findsOneWidget);
  });

  testWidgets('circle detail guards duplicate member navigation', (
    tester,
  ) async {
    final gate = Completer<void>();
    final api = CircleScreenApi()..memberRetryGate = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: CircleDetailScreen(
          repository: CircleRepository(api),
          initial: AppCircle.fromJson(api.circle()),
          canInteract: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final members = find.byKey(const Key('circle-members-open'));
    await tester.tap(members);
    await tester.tap(members, warnIfMissed: false);
    await tester.pump();

    expect(api.memberCalls, 1);

    gate.complete();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(api.memberCalls, 1);
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

  testWidgets('circle detail guards duplicate post navigation', (tester) async {
    final gate = Completer<void>();
    final api = CircleScreenApi()..postDetailGate = gate;
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

    final card = find.byKey(const Key('circle-post-card-7'));
    await tester.tap(card);
    await tester.tap(card, warnIfMissed: false);
    await tester.pump();

    expect(api.postDetailCalls, 1);

    gate.complete();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(api.postDetailCalls, 1);
    expect(api.requestedPostPages, [1]);
  });
}
