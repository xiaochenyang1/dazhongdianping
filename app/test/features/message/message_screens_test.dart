import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/message/conversation_list_screen.dart';
import 'package:dazhongdianping_app/features/message/message_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class ScreenMessageApi implements JsonApi, JsonMutationApi, JsonDeleteApi {
  int conversationCalls = 0;
  final List<int> conversationPages = [];
  final List<int> messagePages = [];
  bool failNextMessageLoad = false;
  int readCalls = 0;
  bool failNextRead = false;
  bool failNextConversationLoad = false;
  Completer<void>? blockGate;
  int blockCalls = 0;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (path.endsWith('/blocks')) return {'list': const [], 'total': 0};
    if (path.endsWith('/conversations')) {
      conversationCalls += 1;
      final page = query?['page'] as int? ?? 1;
      conversationPages.add(page);
      if (failNextConversationLoad) {
        failNextConversationLoad = false;
        throw Exception('conversation network unavailable');
      }
      return {
        'list': [
          {
            'id': page == 1 ? 3 : 4,
            'peerUserId': page == 1 ? 9 : 10,
            'peerNickname': page == 1 ? '伦敦小王' : '巴黎小李',
            'peerAvatar': '',
            'lastMessagePreview': '周末探店？',
            'lastMessageAt': '10:00',
            'unreadCount': 2,
          },
        ],
        'total': 2,
        'page': page,
        'pageSize': 1,
      };
    }
    final page = query?['page'] as int? ?? 1;
    messagePages.add(page);
    if (failNextMessageLoad) {
      failNextMessageLoad = false;
      throw Exception('network unavailable');
    }
    return {
      'list': [
        {
          'id': page == 1 ? 7 : 6,
          'conversationId': 3,
          'fromUserId': 9,
          'toUserId': 8,
          'content': page == 1 ? '周末探店？' : '上周那家也不错',
          'read': false,
          'createdAt': '10:00',
        },
      ],
      'total': 2,
      'page': page,
      'pageSize': 1,
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    if (path.endsWith('/read')) {
      readCalls += 1;
      if (failNextRead) {
        failNextRead = false;
        throw Exception('read unavailable');
      }
      return {'conversationId': 3, 'markedReadCount': 2};
    }
    return {
      'id': 8,
      'conversationId': 3,
      'fromUserId': 8,
      'toUserId': 9,
      'content': '走起',
      'read': false,
      'createdAt': '10:01',
    };
  }

  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    blockCalls += 1;
    await blockGate?.future;
    return {'userId': 9, 'blocked': true};
  }

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

  testWidgets(
    'conversation refresh replaces the future without async setState errors',
    (tester) async {
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
      expect(api.conversationPages, [1, 1]);
      expect(find.text('伦敦小王'), findsOneWidget);
    },
  );

  testWidgets('conversation list loads and merges the next page', (
    tester,
  ) async {
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

    expect(find.text('伦敦小王'), findsOneWidget);
    expect(find.text('加载更多'), findsOneWidget);
    await tester.tap(find.text('加载更多'));
    await tester.pumpAndSettle();

    expect(api.conversationPages, [1, 2]);
    expect(find.text('伦敦小王'), findsOneWidget);
    expect(find.text('巴黎小李'), findsOneWidget);
    expect(find.text('加载更多'), findsNothing);
  });

  testWidgets('conversation list retries an initial load failure', (
    tester,
  ) async {
    final api = ScreenMessageApi()..failNextConversationLoad = true;
    await tester.pumpWidget(
      MaterialApp(
        home: ConversationListScreen(
          repository: MessageRepository(api),
          currentUserId: 8,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('会话加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('conversation-list-retry')));
    await tester.pumpAndSettle();

    expect(api.conversationPages, [1, 1]);
    expect(find.text('伦敦小王'), findsOneWidget);
    expect(find.textContaining('会话加载失败'), findsNothing);
  });

  testWidgets('failed conversation refresh preserves loaded items', (
    tester,
  ) async {
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
    api.failNextConversationLoad = true;

    await tester.drag(find.byType(ListView), const Offset(0, 320));
    await tester.pumpAndSettle();

    expect(find.text('伦敦小王'), findsOneWidget);
    expect(find.textContaining('刷新会话失败'), findsOneWidget);
    expect(api.conversationPages, [1, 1]);
  });

  testWidgets('chat loads earlier messages before the current history', (
    tester,
  ) async {
    final api = ScreenMessageApi();
    const conversation = ConversationSummary(
      id: 3,
      peerUserId: 9,
      peerNickname: '伦敦小王',
      peerAvatar: '',
      lastMessagePreview: '周末探店？',
      lastMessageAt: '10:00',
      unreadCount: 2,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          repository: MessageRepository(api),
          conversation: conversation,
          currentUserId: 8,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('周末探店？'), findsOneWidget);
    expect(find.text('加载更早消息'), findsOneWidget);
    await tester.tap(find.text('加载更早消息'));
    await tester.pumpAndSettle();

    expect(api.messagePages, [1, 2]);
    expect(find.text('上周那家也不错'), findsOneWidget);
    expect(find.text('周末探店？'), findsOneWidget);
    expect(find.text('加载更早消息'), findsNothing);
  });

  testWidgets('chat exposes initial load failure and retries safely', (
    tester,
  ) async {
    final api = ScreenMessageApi()..failNextMessageLoad = true;
    const conversation = ConversationSummary(
      id: 3,
      peerUserId: 9,
      peerNickname: '伦敦小王',
      peerAvatar: '',
      lastMessagePreview: '周末探店？',
      lastMessageAt: '10:00',
      unreadCount: 2,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          repository: MessageRepository(api),
          conversation: conversation,
          currentUserId: 8,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('聊天记录加载失败'), findsOneWidget);
    expect(find.byKey(const Key('chat-history-retry')), findsOneWidget);
    expect(api.readCalls, 0);

    await tester.tap(find.byKey(const Key('chat-history-retry')));
    await tester.pumpAndSettle();

    expect(find.text('周末探店？'), findsOneWidget);
    expect(find.textContaining('聊天记录加载失败'), findsNothing);
    expect(api.messagePages, [1, 1]);
    expect(api.readCalls, 1);
  });

  testWidgets('chat preserves history when marking messages read fails', (
    tester,
  ) async {
    final api = ScreenMessageApi()..failNextRead = true;
    const conversation = ConversationSummary(
      id: 3,
      peerUserId: 9,
      peerNickname: '伦敦小王',
      peerAvatar: '',
      lastMessagePreview: '周末探店？',
      lastMessageAt: '10:00',
      unreadCount: 2,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          repository: MessageRepository(api),
          conversation: conversation,
          currentUserId: 8,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('周末探店？'), findsOneWidget);
    expect(find.textContaining('已读状态同步失败'), findsOneWidget);
    expect(find.textContaining('聊天记录加载失败'), findsNothing);
    expect(api.messagePages, [1]);
    expect(api.readCalls, 1);
  });

  testWidgets('chat blocks duplicate conversation actions while pending', (
    tester,
  ) async {
    final gate = Completer<void>();
    final api = ScreenMessageApi()..blockGate = gate;
    const conversation = ConversationSummary(
      id: 3,
      peerUserId: 9,
      peerNickname: '伦敦小王',
      peerAvatar: '',
      lastMessagePreview: '周末探店？',
      lastMessageAt: '10:00',
      unreadCount: 2,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ChatScreen(
          repository: MessageRepository(api),
          conversation: conversation,
          currentUserId: 8,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('拉黑用户'));
    await tester.pump();

    expect(api.blockCalls, 1);
    expect(
      tester
          .widget<PopupMenuButton<String>>(find.byType(PopupMenuButton<String>))
          .enabled,
      isFalse,
    );

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.blockCalls, 1);
    expect(
      tester
          .widget<PopupMenuButton<String>>(find.byType(PopupMenuButton<String>))
          .enabled,
      isTrue,
    );
  });
}
