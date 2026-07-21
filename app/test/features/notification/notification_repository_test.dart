import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/notification/notification_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class NotificationFakeApi implements JsonApi {
  String? path;
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    this.path = path;
    return {
      'list': [
        {
          'id': 1,
          'type': 'review.reply',
          'actorUserId': 9,
          'actorName': 'Maison Sichuan',
          'title': '商家回复',
          'content': '谢谢支持',
          'linkUrl': '/reviews/1',
          'aggregateCount': 3,
          'read': false,
          'createdAt': '2026-07-15 10:00:00',
        },
      ],
      'total': 1,
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    this.path = path;
    return {
      'id': 1,
      'type': 'review.reply',
      'actorUserId': 9,
      'actorName': 'Maison Sichuan',
      'title': '商家回复',
      'content': '谢谢支持',
      'linkUrl': '/reviews/1',
      'aggregateCount': 3,
      'read': true,
      'createdAt': '2026-07-15 10:00:00',
    };
  }
}

void main() {
  test('notification repository lists and acknowledges messages', () async {
    final api = NotificationFakeApi();
    final repository = NotificationRepository(api);
    final messages = await repository.load();
    expect(messages.single.read, isFalse);
    expect(messages.single.actorUserId, 9);
    expect(messages.single.actorName, 'Maison Sichuan');
    expect(messages.single.aggregateCount, 3);
    final read = await repository.ack(1);
    expect(api.path, '/api/c/v1/notifications/1/ack');
    expect(read.read, isTrue);
    expect(read.aggregateCount, 3);
  });
}
