import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/user/public_user_profile_screen.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class SocialProfileApi implements JsonApi, JsonMutationApi, JsonDeleteApi {
  bool paginateFollowers = false;
  bool failNextProfile = false;
  bool failNextFollowers = false;
  Object? profileError;
  Object? relationshipError;
  Object? loadMoreFollowersError;
  Object? followError;
  int profileRequests = 0;
  Completer<void>? profileRetryGate;
  final List<int> requestedFollowerPages = <int>[];
  int relationshipRequests = 0;
  Completer<void>? relationshipRetryGate;
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (path.endsWith('/followers')) {
      relationshipRequests++;
      final page = query?['page'] as int? ?? 1;
      if (page == 1 && relationshipError != null) {
        throw relationshipError!;
      }
      if (page > 1 && loadMoreFollowersError != null) {
        throw loadMoreFollowersError!;
      }
      if (failNextFollowers) {
        failNextFollowers = false;
        throw StateError('relationship network unavailable');
      }
      await relationshipRetryGate?.future;
      requestedFollowerPages.add(page);
      return {
        'list': [
          {
            'id': page == 1 ? 21 : 22,
            'nickname': page == 1 ? '巴黎小陈' : '柏林小周',
            'avatar': '',
            'signature': '周末探店',
            'level': 3,
            'followerCount': 4,
            'followedAt': '2026-07-20 10:00:00',
          },
        ],
        'total': paginateFollowers ? 2 : 1,
        'page': page,
        'pageSize': paginateFollowers ? 1 : 50,
      };
    }
    if (path.endsWith('/following')) {
      return {'list': const [], 'total': 0};
    }
    if (path == '/api/c/v1/user/21') {
      if (profileError != null) {
        throw profileError!;
      }
      return {
        'id': 21,
        'nickname': '巴黎小陈',
        'avatar': '',
        'signature': '周末探店',
        'level': 3,
        'reviewCount': 2,
        'followerCount': 4,
        'followingCount': 1,
        'followedByCurrentUser': false,
      };
    }
    profileRequests++;
    if (profileError != null) {
      throw profileError!;
    }
    if (failNextProfile) {
      failNextProfile = false;
      throw StateError('profile network unavailable');
    }
    await profileRetryGate?.future;
    return {
      'id': 9,
      'nickname': '伦敦小王',
      'avatar': '',
      'signature': '咖啡探店',
      'level': 4,
      'reviewCount': 5,
      'followerCount': 12,
      'followingCount': 7,
      'followedByCurrentUser': false,
      'expertCertification': {'code': 'local_expert', 'label': '本地达人'},
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      {};
  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    if (followError != null) {
      throw followError!;
    }
    return {'following': true, 'followerCount': 13};
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path) async => {
    'following': false,
    'followerCount': 12,
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
  testWidgets('public profile retries an initial load failure', (tester) async {
    final api = SocialProfileApi()..failNextProfile = true;
    await tester.pumpWidget(
      MaterialApp(
        home: PublicUserProfileScreen(
          repository: UserRepository(api),
          userId: 9,
          canFollow: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('用户主页加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('public-profile-retry')));
    await tester.pumpAndSettle();

    expect(api.profileRequests, 2);
    expect(find.text('伦敦小王'), findsOneWidget);
  });

  testWidgets('public profile guards duplicate retries', (tester) async {
    final gate = Completer<void>();
    final api = SocialProfileApi()
      ..failNextProfile = true
      ..profileRetryGate = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: PublicUserProfileScreen(
          repository: UserRepository(api),
          userId: 9,
          canFollow: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('public-profile-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(api.profileRequests, 2);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.profileRequests, 2);
    expect(find.text('伦敦小王'), findsOneWidget);
  });

  testWidgets('relationship list retries an initial load failure', (
    tester,
  ) async {
    final api = SocialProfileApi()..failNextFollowers = true;
    await tester.pumpWidget(
      MaterialApp(
        home: UserRelationshipsScreen(
          repository: UserRepository(api),
          userId: 9,
          followers: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('关系列表加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('relationships-retry')));
    await tester.pumpAndSettle();

    expect(api.requestedFollowerPages, [1]);
    expect(find.text('巴黎小陈'), findsOneWidget);
  });

  testWidgets('relationship list guards duplicate retries', (tester) async {
    final gate = Completer<void>();
    final api = SocialProfileApi()
      ..failNextFollowers = true
      ..relationshipRetryGate = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: UserRelationshipsScreen(
          repository: UserRepository(api),
          userId: 9,
          followers: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('relationships-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(api.requestedFollowerPages, isEmpty);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.requestedFollowerPages, [1]);
    expect(find.text('巴黎小陈'), findsOneWidget);
  });

  testWidgets('relationship list loads later users', (tester) async {
    final api = SocialProfileApi()..paginateFollowers = true;
    await tester.pumpWidget(
      MaterialApp(
        home: UserRelationshipsScreen(
          repository: UserRepository(api),
          userId: 9,
          followers: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('relationships-load-more')), findsOneWidget);
    await tester.tap(find.byKey(const Key('relationships-load-more')));
    await tester.pumpAndSettle();

    expect(api.requestedFollowerPages, [1, 2]);
    expect(find.text('柏林小周'), findsOneWidget);
    expect(find.byKey(const Key('relationships-load-more')), findsNothing);
  });

  testWidgets(
    'public profile follows explicitly and updates the visible count',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PublicUserProfileScreen(
            repository: UserRepository(SocialProfileApi()),
            userId: 9,
            canFollow: true,
            currentUserId: 8,
            onMessage: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('本地达人'), findsOneWidget);
      expect(find.text('粉丝 12'), findsOneWidget);
      expect(find.text('关注'), findsOneWidget);
      expect(find.text('发私信'), findsOneWidget);
      await tester.tap(find.text('关注'));
      await tester.pumpAndSettle();
      expect(find.text('粉丝 13'), findsOneWidget);
      expect(find.text('已关注'), findsOneWidget);
    },
  );

  testWidgets('public profile localizes load errors in English', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: PublicUserProfileScreen(
          repository: UserRepository(
            SocialProfileApi()..profileError = const ApiException('用户不存在'),
          ),
          userId: 9,
          canFollow: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Could not load profile: This user could not be found.'),
      findsOneWidget,
    );
    expect(find.textContaining('用户不存在'), findsNothing);
  });

  testWidgets('public profile localizes follow errors in English', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: PublicUserProfileScreen(
          repository: UserRepository(
            SocialProfileApi()..followError = const ApiException('用户登录状态不存在'),
          ),
          userId: 9,
          canFollow: true,
          currentUserId: 8,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final followButton = find.text('Following', skipOffstage: false);
    await tester.ensureVisible(followButton);
    await tester.tap(followButton);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not update follow status: Your sign-in session is no longer available. Please sign in again.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('用户登录状态不存在'), findsNothing);
  });

  testWidgets('relationship list localizes load errors in English', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: UserRelationshipsScreen(
          repository: UserRepository(
            SocialProfileApi()..relationshipError = const ApiException('用户不存在'),
          ),
          userId: 9,
          followers: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Could not load relation list: This user could not be found.'),
      findsOneWidget,
    );
    expect(find.textContaining('用户不存在'), findsNothing);
  });

  testWidgets('relationship list localizes load more errors in English', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: UserRelationshipsScreen(
          repository: UserRepository(
            SocialProfileApi()
              ..paginateFollowers = true
              ..loadMoreFollowersError = const ApiException('用户不存在'),
          ),
          userId: 9,
          followers: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final loadMoreButton = find.byKey(
      const Key('relationships-load-more'),
      skipOffstage: false,
    );
    await tester.ensureVisible(loadMoreButton);
    await tester.tap(loadMoreButton);
    await tester.pumpAndSettle();

    expect(
      find.text('Could not load more users: This user could not be found.'),
      findsOneWidget,
    );
    expect(find.textContaining('用户不存在'), findsNothing);
  });

  testWidgets('public profile guards duplicate relationship navigation', (
    tester,
  ) async {
    final gate = Completer<void>();
    final api = SocialProfileApi()..relationshipRetryGate = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: PublicUserProfileScreen(
          repository: UserRepository(api),
          userId: 9,
          canFollow: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final followers = find.byKey(const Key('public-profile-followers'));
    await tester.tap(followers);
    await tester.tap(followers, warnIfMissed: false);
    await tester.pump();
    expect(api.relationshipRequests, 1);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.relationshipRequests, 1);
    expect(find.text('巴黎小陈'), findsOneWidget);
  });

  testWidgets('relationship list opens nested public profile', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PublicUserProfileScreen(
          repository: UserRepository(SocialProfileApi()),
          userId: 9,
          canFollow: true,
          currentUserId: 8,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('粉丝 12'));
    await tester.pumpAndSettle();
    expect(find.text('粉丝'), findsWidgets);
    expect(find.text('巴黎小陈'), findsOneWidget);

    await tester.tap(find.text('巴黎小陈'));
    await tester.pumpAndSettle();
    expect(find.text('周末探店'), findsOneWidget);
    expect(find.text('粉丝 4'), findsOneWidget);
  });
}
