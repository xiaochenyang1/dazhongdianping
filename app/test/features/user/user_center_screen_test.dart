import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/session_store.dart';
import 'package:dazhongdianping_app/features/auth/auth_controller.dart';
import 'package:dazhongdianping_app/features/auth/auth_repository.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/user/user_center_screen.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CenterFakeApi implements JsonApi {
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async => {
    'id': 9,
    'nickname': 'Center User',
    'avatar': '',
    'preferredRegion': 'EU',
    'level': 4,
    'points': 120,
    'growthValue': 350,
  };

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      {};
}

class CenterBrowseRepository extends BrowseRepository {
  @override
  Future<List<ShopSummary>> loadFeaturedShops() async => const [];
}

void main() {
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
    expect(find.text('我的收藏'), findsOneWidget);
    expect(find.text('我的订单'), findsOneWidget);
    expect(find.text('我的券'), findsOneWidget);
    expect(find.text('我的预订'), findsOneWidget);
    expect(find.text('我的圈子'), findsOneWidget);
    expect(find.text('我的足迹'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('隐私中心'), 200);
    expect(find.text('隐私中心'), findsOneWidget);
  });
}
