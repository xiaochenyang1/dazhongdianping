import 'package:dazhongdianping_app/core/api_client.dart';

class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.peerUserId,
    required this.peerNickname,
    required this.peerAvatar,
    required this.lastMessagePreview,
    required this.lastMessageAt,
    required this.unreadCount,
  });
  final int id, peerUserId, unreadCount;
  final String peerNickname, peerAvatar, lastMessagePreview, lastMessageAt;
  factory ConversationSummary.fromJson(Map<String, dynamic> json) =>
      ConversationSummary(
        id: json['id'] as int,
        peerUserId: json['peerUserId'] as int,
        peerNickname: json['peerNickname'] as String? ?? '',
        peerAvatar: json['peerAvatar'] as String? ?? '',
        lastMessagePreview: json['lastMessagePreview'] as String? ?? '',
        lastMessageAt: json['lastMessageAt'] as String? ?? '',
        unreadCount: json['unreadCount'] as int? ?? 0,
      );
}

class DirectMessage {
  const DirectMessage({
    required this.id,
    required this.conversationId,
    required this.fromUserId,
    required this.toUserId,
    required this.content,
    required this.read,
    required this.createdAt,
  });
  final int id, conversationId, fromUserId, toUserId;
  final String content, createdAt;
  final bool read;
  factory DirectMessage.fromJson(Map<String, dynamic> json) => DirectMessage(
    id: json['id'] as int,
    conversationId: json['conversationId'] as int,
    fromUserId: json['fromUserId'] as int,
    toUserId: json['toUserId'] as int,
    content: json['content'] as String? ?? '',
    read: json['read'] as bool? ?? false,
    createdAt: json['createdAt'] as String? ?? '',
  );
}

class BlockStatus {
  const BlockStatus(this.userId, this.blocked);
  final int userId;
  final bool blocked;
}

class MessageRepository {
  MessageRepository(this.api);
  final JsonApi api;
  Future<List<ConversationSummary>> loadConversations() async => _list(
    await api.getJson('/api/c/v1/messages/conversations'),
    ConversationSummary.fromJson,
  );
  Future<List<DirectMessage>> loadMessages(int conversationId) async => _list(
    await api.getJson('/api/c/v1/messages/conversations/$conversationId'),
    DirectMessage.fromJson,
  );
  Future<DirectMessage> send(int toUserId, String content) async =>
      DirectMessage.fromJson(
        await api.postJson(
          '/api/c/v1/messages/send',
          body: {'toUserId': toUserId, 'content': content},
        ),
      );
  Future<int> markRead(int conversationId) async =>
      (await api.postJson(
            '/api/c/v1/messages/conversations/$conversationId/read',
          ))['markedReadCount']
          as int? ??
      0;
  Future<void> reportConversation(int id, String reason) async {
    await api.postJson(
      '/api/c/v1/messages/report',
      body: {'targetType': 2, 'targetId': id, 'reason': reason},
    );
  }

  Future<BlockStatus> block(int userId) async {
    final data = await (api as JsonMutationApi).putJson(
      '/api/c/v1/messages/blocks/$userId',
    );
    return BlockStatus(data['userId'] as int, data['blocked'] as bool);
  }

  Future<BlockStatus> unblock(int userId) async {
    final data = await (api as JsonDeleteApi).deleteJson(
      '/api/c/v1/messages/blocks/$userId',
    );
    return BlockStatus(data['userId'] as int, data['blocked'] as bool);
  }

  List<T> _list<T>(
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) parse,
  ) => (data['list'] as List<dynamic>? ?? const [])
      .cast<Map<String, dynamic>>()
      .map(parse)
      .toList();
}
