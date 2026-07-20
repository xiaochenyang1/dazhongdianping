import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/user/public_user_profile_screen.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class SocialProfileApi implements JsonApi, JsonMutationApi, JsonDeleteApi {
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (path.endsWith('/followers') || path.endsWith('/following')) {
      return {'list': const [], 'total': 0};
    }
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
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      {};
  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async => {
    'following': true,
    'followerCount': 13,
  };
  @override
  Future<Map<String, dynamic>> deleteJson(String path) async => {
    'following': false,
    'followerCount': 12,
  };
}

void main() {
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
      expect(find.text('粉丝 12'), findsOneWidget);
      expect(find.text('关注'), findsOneWidget);
      expect(find.text('发私信'), findsOneWidget);
      await tester.tap(find.text('关注'));
      await tester.pumpAndSettle();
      expect(find.text('粉丝 13'), findsOneWidget);
      expect(find.text('已关注'), findsOneWidget);
    },
  );
}
