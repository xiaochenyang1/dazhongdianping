import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/circle/circle_repository.dart';
import 'package:dazhongdianping_app/features/circle/circle_square_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CircleScreenApi implements JsonApi, JsonMutationApi, JsonDeleteApi {
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
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (path.endsWith('/members')) return {'list': const [], 'total': 0};
    if (path.endsWith('/posts')) {
      return {
        'list': [
          {
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
          },
        ],
        'total': 1,
      };
    }
    if (path.endsWith('/3')) return circle();
    return {
      'list': [circle()],
      'total': 1,
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
}
