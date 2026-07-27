import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/session_store.dart';
import 'package:dazhongdianping_app/features/auth/auth_controller.dart';
import 'package:dazhongdianping_app/features/auth/auth_repository.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/user/account_settings_screen.dart';
import 'package:dazhongdianping_app/features/user/user_center_screen.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CenterFakeApi implements JsonApi, JsonMutationApi {
  CenterFakeApi({this.failFirst = false});

  final bool failFirst;
  int profileRequests = 0;
  Completer<void>? retryGate;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    profileRequests++;
    if (failFirst && profileRequests == 1) {
      throw StateError('network unavailable');
    }
    if (profileRequests > 1) await retryGate?.future;
    return {
      'id': 9,
      'nickname': 'Center User',
      'avatar': '',
      'preferredRegion': 'EU',
      'level': 4,
      'points': 120,
      'growthValue': 350,
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      {};

  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    final payload = body! as Map<String, dynamic>;
    return {
      'id': 9,
      'nickname': payload['nickname'],
      'avatar': payload['avatar'],
      'preferredRegion': 'EU',
      'level': 4,
      'points': 120,
      'growthValue': 350,
      'gender': payload['gender'],
      'signature': payload['signature'],
    };
  }
}

class CenterBrowseRepository extends BrowseRepository {
  @override
  Future<List<ShopSummary>> loadFeaturedShops() async => const [];
}

class GatedAuthController extends AuthController {
  GatedAuthController({required this.gate, required JsonApi api})
    : super(repository: AuthRepository(api), store: MemorySessionStore());

  final Completer<void> gate;
  int logoutCalls = 0;

  @override
  Future<void> logout() async {
    logoutCalls += 1;
    await gate.future;
  }
}

void main() {
  testWidgets('user center retries an initial profile failure', (tester) async {
    final api = CenterFakeApi(failFirst: true);
    final auth = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: UserCenterScreen(
          repository: UserRepository(api),
          authController: auth,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('用户资料加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('user-center-retry')));
    await tester.pumpAndSettle();

    expect(api.profileRequests, 2);
    expect(find.text('Center User'), findsOneWidget);
  });

  testWidgets('user center guards duplicate profile retries', (tester) async {
    final gate = Completer<void>();
    final api = CenterFakeApi(failFirst: true)..retryGate = gate;
    final auth = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: UserCenterScreen(
          repository: UserRepository(api),
          authController: auth,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('user-center-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(api.profileRequests, 2);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.profileRequests, 2);
    expect(find.text('Center User'), findsOneWidget);
  });

  testWidgets('user center exposes core account destinations', (tester) async {
    final api = CenterFakeApi();
    final auth = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: UserCenterScreen(
          repository: UserRepository(api),
          authController: auth,
          browseRepository: CenterBrowseRepository(),
          onCircles: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Center User'), findsOneWidget);
    expect(find.text('账户设置'), findsOneWidget);
    expect(find.text('本地达人认证'), findsOneWidget);
    expect(find.text('成长值流水'), findsOneWidget);
    expect(find.text('我的点评'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('我的收藏'), 200);
    expect(find.text('我的收藏'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('我的订单'), 200);
    expect(find.text('我的订单'), findsOneWidget);
    expect(find.text('我的券'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('我的预订'), 200);
    expect(find.text('我的预订'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('我的圈子'), 200);
    expect(find.text('我的圈子'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('黑名单管理'), 200);
    expect(find.text('黑名单管理'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('我的足迹'), 200);
    expect(find.text('我的足迹'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('隐私中心'), 200);
    expect(find.text('隐私中心'), findsOneWidget);
  });

  testWidgets('user center reflects profile changes from account settings', (
    tester,
  ) async {
    final api = CenterFakeApi();
    final auth = AuthController(
      repository: AuthRepository(api),
      store: MemorySessionStore(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: UserCenterScreen(
          repository: UserRepository(api),
          authController: auth,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Center User'), findsOneWidget);
    await tester.tap(find.text('账户设置'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('settings-nickname')),
      'Updated Center User',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-save-profile')));
    await tester.pumpAndSettle();
    expect(auth.currentUser?.nickname, 'Updated Center User');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(AccountSettingsScreen), findsNothing);
    expect(find.text('Center User'), findsNothing);
    expect(find.text('Updated Center User'), findsOneWidget);
  });

  testWidgets('user center guards duplicate logout requests', (tester) async {
    final gate = Completer<void>();
    final api = CenterFakeApi();
    final auth = GatedAuthController(gate: gate, api: api);
    var loggedOut = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: UserCenterScreen(
          repository: UserRepository(api),
          authController: auth,
          onLoggedOut: () => loggedOut += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final logout = find.byKey(const Key('user-center-logout'));
    await tester.tap(logout);
    await tester.tap(logout);
    await tester.pump();
    expect(auth.logoutCalls, 1);
    expect(loggedOut, 0);
    expect(find.text('退出中...'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(auth.logoutCalls, 1);
    expect(loggedOut, 1);
  });
}
