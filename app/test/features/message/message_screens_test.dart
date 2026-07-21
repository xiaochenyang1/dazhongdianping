import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/message/conversation_list_screen.dart';
import 'package:dazhongdianping_app/features/message/message_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ScreenMessageApi implements JsonApi, JsonMutationApi, JsonDeleteApi {
  int conversationCalls = 0;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (path.endsWith('/blocks')) return {'list': const [], 'total': 0};
    if (path.endsWith('/conversations')) {
      conversationCalls += 1;
      return {
        'list': [
          {
            'id': 3,
            'peerUserId': 9,
            'peerNickname': '伦敦小王',
            'peerAvatar': '',
            'lastMessagePreview': '周末探店？',
            'lastMessageAt': '10:00',
            'unreadCount': 2,
          },
        ],
        'total': 1,
      };
    }
    return {
      'list': [
        {
          'id': 7,
          'conversationId': 3,
          'fromUserId': 9,
          'toUserId': 8,
          'content': '周末探店？',
          'read': false,
          'createdAt': '10:00',
        },
      ],
      'total': 1,
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      path.endsWith('/read')
      ? {'conversationId': 3, 'markedReadCount': 2}
      : {
          'id': 8,
          'conversationId': 3,
          'fromUserId': 8,
          'toUserId': 9,
          'content': '走起',
          'read': false,
          'createdAt': '10:01',
        };
  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async => {
    'userId': 9,
    'blocked': true,
  };
  @override
  Future<Map<String, dynamic>> deleteJson(String path) async => {
    'userId': 9,
    'blocked': false,
  };
}

void main() {
  testWidgets('conversation list opens chat and sends text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConversationListScreen(
          repository: MessageRepository(ScreenMessageApi()),
          currentUserId: 8,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('伦敦小王'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.text('伦敦小王'));
    await tester.pumpAndSettle();
    expect(find.text('周末探店？'), findsWidgets);
    await tester.enterText(find.byType(TextField), '走起');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();
    expect(find.text('走起'), findsOneWidget);
  });

  testWidgets('conversation refresh replaces the future without async setState errors', (tester) async {
    final api = ScreenMessageApi();
    await tester.pumpWidget(
      MaterialApp(
        home: ConversationListScreen(
          repository: MessageRepository(api),
          currentUserId: 8,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(api.conversationCalls, 1);

    await tester.drag(find.byType(ListView), const Offset(0, 320));
    await tester.pumpAndSettle();

    expect(api.conversationCalls, 2);
    expect(find.text('伦敦小王'), findsOneWidget);
  });
}
