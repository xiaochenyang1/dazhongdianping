import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/message/message_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class MessageFakeApi implements JsonApi, JsonMutationApi, JsonDeleteApi {
  String path = '';
  Object? body;
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    this.path = path;
    if (path.endsWith('/blocks')) return {'list': const [], 'total': 0};
    if (path.endsWith('/conversations')) {
      return {
        'list': [
          {
            'id': 3,
            'peerUserId': 9,
            'peerNickname': '伦敦小王',
            'peerAvatar': '',
            'lastMessagePreview': '周末探店？',
            'lastMessageAt': '2026-07-17 10:00:00',
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
          'createdAt': '2026-07-17 10:00:00',
        },
      ],
      'total': 1,
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    this.path = path;
    this.body = body;
    if (path.endsWith('/read')) {
      return {'conversationId': 3, 'markedReadCount': 2};
    }
    if (path.endsWith('/report')) {
      return {'id': 1, 'targetType': 2, 'targetId': 3, 'status': 'pending'};
    }
    return {
      'id': 8,
      'conversationId': 3,
      'fromUserId': 8,
      'toUserId': 9,
      'content': '走起',
      'read': false,
      'createdAt': '2026-07-17 10:01:00',
    };
  }

  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    this.path = path;
    return {'userId': 9, 'blocked': true};
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path) async {
    this.path = path;
    return {'userId': 9, 'blocked': false};
  }
}

void main() {
  test(
    'message repository covers conversations chat send read report and block',
    () async {
      final api = MessageFakeApi();
      final repository = MessageRepository(api);
      expect((await repository.loadConversations()).single.unreadCount, 2);
      expect((await repository.loadMessages(3)).single.content, '周末探店？');
      expect((await repository.send(9, '走起')).content, '走起');
      expect((await repository.markRead(3)), 2);
      await repository.reportConversation(3, '骚扰');
      expect(api.path, '/api/c/v1/messages/report');
      expect((await repository.block(9)).blocked, isTrue);
      expect((await repository.unblock(9)).blocked, isFalse);
    },
  );
}
