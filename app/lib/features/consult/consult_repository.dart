import 'package:dazhongdianping_app/core/api_client.dart';

/// 咨询会话。
class ConsultSession {
  const ConsultSession({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.lastMessage,
    required this.unread,
    this.lastMessageAt,
  });

  final int id;
  final int shopId;
  final String shopName;
  final String lastMessage;
  final int unread;
  final String? lastMessageAt;

  factory ConsultSession.fromJson(Map<String, dynamic> json) => ConsultSession(
        id: (json['id'] as num?)?.toInt() ?? 0,
        shopId: (json['shopId'] as num?)?.toInt() ?? 0,
        shopName: json['shopName'] as String? ?? '',
        lastMessage: json['lastMessage'] as String? ?? '',
        unread: (json['unread'] as num?)?.toInt() ?? 0,
        lastMessageAt: json['lastMessageAt'] as String?,
      );
}

/// 咨询消息。senderType：1=用户 2=商家。
class ConsultMessage {
  const ConsultMessage({
    required this.id,
    required this.senderType,
    required this.content,
    this.createdAt,
  });

  final int id;
  final int senderType;
  final String content;
  final String? createdAt;

  factory ConsultMessage.fromJson(Map<String, dynamic> json) => ConsultMessage(
        id: (json['id'] as num?)?.toInt() ?? 0,
        senderType: (json['senderType'] as num?)?.toInt() ?? 1,
        content: json['content'] as String? ?? '',
        createdAt: json['createdAt'] as String?,
      );
}

/// 会话消息线程。
class ConsultThread {
  const ConsultThread({required this.session, required this.messages});
  final ConsultSession session;
  final List<ConsultMessage> messages;
}

/// C端在线咨询仓库。
class ConsultRepository {
  ConsultRepository(this.api);

  final JsonApi api;

  Future<ConsultSession> startSession(int shopId) async {
    final result = await api.postJson('/api/c/v1/consult/sessions', body: {'shopId': shopId});
    return ConsultSession.fromJson(result);
  }

  Future<List<ConsultSession>> loadSessions() async {
    final result = await api.getJson('/api/c/v1/consult/sessions');
    final raw = result['value'] ?? result['list'];
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map(ConsultSession.fromJson).toList();
  }

  Future<ConsultThread> loadThread(int sessionId) async {
    final result = await api.getJson('/api/c/v1/consult/sessions/$sessionId/messages');
    final session = ConsultSession.fromJson(
        (result['session'] as Map<String, dynamic>?) ?? const {});
    final rawMessages = result['messages'];
    final messages = rawMessages is List
        ? rawMessages.whereType<Map<String, dynamic>>().map(ConsultMessage.fromJson).toList()
        : <ConsultMessage>[];
    return ConsultThread(session: session, messages: messages);
  }

  Future<ConsultMessage> sendMessage(int sessionId, String content) async {
    final result = await api.postJson(
      '/api/c/v1/consult/sessions/$sessionId/messages',
      body: {'content': content},
    );
    return ConsultMessage.fromJson(result);
  }
}
