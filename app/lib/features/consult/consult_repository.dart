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
  const ConsultThread({
    required this.session,
    required this.messages,
    this.hasMore = false,
    this.nextBeforeId,
    this.nextAfterId = 0,
  });
  final ConsultSession session;
  final List<ConsultMessage> messages;
  final bool hasMore;
  final int? nextBeforeId;
  final int nextAfterId;
}

class ConsultSessionCursor {
  const ConsultSessionCursor({required this.id, required this.updatedAt});
  final int id;
  final String updatedAt;
}

class ConsultSessionPage {
  const ConsultSessionPage({
    required this.sessions,
    this.hasMore = false,
    this.nextCursor,
  });
  final List<ConsultSession> sessions;
  final bool hasMore;
  final ConsultSessionCursor? nextCursor;
}

/// C端在线咨询仓库。
class ConsultRepository {
  ConsultRepository(this.api);

  final JsonApi api;

  Future<ConsultSession> startSession(int shopId) async {
    final result = await api.postJson(
      '/api/c/v1/consult/sessions',
      body: {'shopId': shopId},
    );
    return ConsultSession.fromJson(result);
  }

  Future<ConsultSessionPage> loadSessions({
    ConsultSessionCursor? cursor,
    bool unreadOnly = false,
    int? pageSize,
  }) async {
    final result = await api.getJson(
      '/api/c/v1/consult/sessions',
      query: {
        if (cursor != null) 'beforeId': cursor.id,
        if (cursor != null) 'beforeUpdatedAt': cursor.updatedAt,
        'unreadOnly': unreadOnly,
        if (pageSize != null) 'pageSize': pageSize,
      },
    );
    final raw = result['list'];
    final nextId = (result['nextBeforeId'] as num?)?.toInt();
    final nextTime = result['nextBeforeUpdatedAt'] as String?;
    return ConsultSessionPage(
      sessions: raw is List
          ? raw
                .whereType<Map<String, dynamic>>()
                .map(ConsultSession.fromJson)
                .toList()
          : const [],
      hasMore: result['hasMore'] as bool? ?? false,
      nextCursor: nextId != null && nextTime != null
          ? ConsultSessionCursor(id: nextId, updatedAt: nextTime)
          : null,
    );
  }

  Future<ConsultThread> loadThread(
    int sessionId, {
    int? beforeId,
    int? afterId,
    int? pageSize,
  }) async {
    final result = await api.getJson(
      '/api/c/v1/consult/sessions/$sessionId/messages',
      query: {
        if (beforeId != null) 'beforeId': beforeId,
        if (afterId != null) 'afterId': afterId,
        if (pageSize != null) 'pageSize': pageSize,
      },
    );
    final session = ConsultSession.fromJson(
      (result['session'] as Map<String, dynamic>?) ?? const {},
    );
    final rawMessages = result['messages'];
    final messages = rawMessages is List
        ? rawMessages
              .whereType<Map<String, dynamic>>()
              .map(ConsultMessage.fromJson)
              .toList()
        : <ConsultMessage>[];
    return ConsultThread(
      session: session,
      messages: messages,
      hasMore: result['hasMore'] as bool? ?? false,
      nextBeforeId:
          (result['nextBeforeId'] as num?)?.toInt() ??
          (messages.isEmpty ? null : messages.first.id),
      nextAfterId:
          (result['nextAfterId'] as num?)?.toInt() ??
          (messages.isEmpty ? afterId ?? 0 : messages.last.id),
    );
  }

  Future<ConsultMessage> sendMessage(int sessionId, String content) async {
    final result = await api.postJson(
      '/api/c/v1/consult/sessions/$sessionId/messages',
      body: {'content': content},
    );
    return ConsultMessage.fromJson(result);
  }
}
