import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/consult/consult_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class ConsultFakeApi implements JsonApi {
  ConsultFakeApi({this.getResponse = const {}, this.postResponse = const {}});

  Map<String, dynamic> getResponse;
  Map<String, dynamic> postResponse;
  String? getPath;
  Map<String, Object?>? getQuery;
  String? postPath;
  Object? postBody;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    getPath = path;
    getQuery = query;
    return getResponse;
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postPath = path;
    postBody = body;
    return postResponse;
  }
}

void main() {
  test('startSession posts shopId and parses the session', () async {
    final api = ConsultFakeApi(
      postResponse: {
        'id': 5,
        'shopId': 10001,
        'shopName': '沪上渝里',
        'lastMessage': '',
        'unread': 0,
      },
    );
    final repository = ConsultRepository(api);

    final session = await repository.startSession(10001);

    expect(api.postPath, '/api/c/v1/consult/sessions');
    expect((api.postBody as Map<String, dynamic>)['shopId'], 10001);
    expect(session.id, 5);
    expect(session.shopName, '沪上渝里');
  });

  test('loadThread parses session and messages', () async {
    final api = ConsultFakeApi(
      getResponse: {
        'session': {
          'id': 5,
          'shopId': 10001,
          'shopName': '沪上渝里',
          'lastMessage': '你好',
          'unread': 0,
        },
        'messages': [
          {'id': 1, 'senderType': 1, 'senderId': 9001, 'content': '在吗'},
          {'id': 2, 'senderType': 2, 'senderId': 11001, 'content': '在的'},
        ],
      },
    );
    final repository = ConsultRepository(api);

    final thread = await repository.loadThread(5);

    expect(api.getPath, '/api/c/v1/consult/sessions/5/messages');
    expect(thread.session.shopName, '沪上渝里');
    expect(thread.messages, hasLength(2));
    expect(thread.messages.last.senderType, 2);
  });

  test(
    'uses history and incremental cursors and parses paging metadata',
    () async {
      final api = ConsultFakeApi(
        getResponse: {
          'session': {'id': 5},
          'messages': [
            {'id': 41, 'content': 'earlier'},
          ],
          'hasMore': true,
          'nextBeforeId': 41,
          'nextAfterId': 41,
        },
      );
      final repository = ConsultRepository(api);
      final page = await repository.loadThread(5, beforeId: 60, pageSize: 20);
      expect(api.getQuery, {'beforeId': 60, 'pageSize': 20});
      expect(page.hasMore, isTrue);
      expect(page.nextBeforeId, 41);
      expect(page.nextAfterId, 41);
      api.getResponse = {
        'session': {'id': 5},
        'messages': [],
        'hasMore': false,
        'nextBeforeId': null,
        'nextAfterId': 60,
      };
      final idle = await repository.loadThread(5, afterId: 60);
      expect(api.getQuery, {'afterId': 60});
      expect(idle.nextAfterId, 60);
      expect(idle.nextBeforeId, isNull);
    },
  );

  test('sendMessage posts content and parses the reply', () async {
    final api = ConsultFakeApi(
      postResponse: {
        'id': 3,
        'senderType': 1,
        'senderId': 9001,
        'content': '谢谢',
      },
    );
    final repository = ConsultRepository(api);

    final message = await repository.sendMessage(5, '谢谢');

    expect(api.postPath, '/api/c/v1/consult/sessions/5/messages');
    expect((api.postBody as Map<String, dynamic>)['content'], '谢谢');
    expect(message.id, 3);
  });

  test(
    'loadSessions reads bounded pages and forwards the cursor and filter',
    () async {
      final api = ConsultFakeApi(
        getResponse: {
          'list': [
            {
              'id': 5,
              'shopId': 10001,
              'shopName': '沪上渝里',
              'lastMessage': '你好',
              'unread': 2,
            },
          ],
        },
      );
      final repository = ConsultRepository(api);

      final page = await repository.loadSessions(
        cursor: const ConsultSessionCursor(
          id: 9,
          updatedAt: '2026-11-06T10:00:00',
        ),
        unreadOnly: true,
        pageSize: 5,
      );

      expect(api.getPath, '/api/c/v1/consult/sessions');
      expect(page.sessions.single.unread, 2);
      expect(api.getQuery, {
        'beforeId': 9,
        'beforeUpdatedAt': '2026-11-06T10:00:00',
        'unreadOnly': true,
        'pageSize': 5,
      });
    },
  );
}
