import 'package:dazhongdianping_app/core/api_client.dart';

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.content,
    required this.status,
    required this.statusText,
    required this.shopId,
    this.messages = const [],
    this.createdAt = '',
  });

  final int id;
  final String subject;
  final String content;
  final int status;
  final String statusText;
  final int shopId;
  final List<TicketMessage> messages;
  final String createdAt;

  bool get canReply => status == 1 || status == 2;

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
    id: (json['id'] as num?)?.toInt() ?? 0,
    subject: json['subject'] as String? ?? '',
    content: json['content'] as String? ?? '',
    status: (json['status'] as num?)?.toInt() ?? 1,
    statusText: json['statusText'] as String? ?? '',
    shopId: (json['shopId'] as num?)?.toInt() ?? 0,
    createdAt: json['createdAt'] as String? ?? '',
    messages: (json['messages'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(TicketMessage.fromJson)
        .toList(),
  );
}

class TicketMessage {
  const TicketMessage({
    required this.id,
    required this.content,
    required this.senderType,
    this.createdAt = '',
  });

  final int id;
  final String content;
  final int senderType;
  final String createdAt;

  factory TicketMessage.fromJson(Map<String, dynamic> json) => TicketMessage(
    id: (json['id'] as num?)?.toInt() ?? 0,
    content: json['content'] as String? ?? '',
    senderType: (json['senderType'] as num?)?.toInt() ?? 1,
    createdAt: json['createdAt'] as String? ?? '',
  );
}

class TicketPage {
  const TicketPage({
    required this.items,
    required this.page,
    required this.hasMore,
  });
  final List<SupportTicket> items;
  final int page;
  final bool hasMore;
}

class TicketRepository {
  TicketRepository(this.api);

  final JsonApi api;

  Future<List<SupportTicket>> loadMine() async {
    return (await loadPage()).items;
  }

  Future<TicketPage> loadPage({int page = 1, int pageSize = 12}) async {
    final result = await api.getJson(
      '/api/c/v1/tickets',
      query: {'page': page, 'pageSize': pageSize},
    );
    final raw = result['list'];
    final items = raw is List
        ? raw
              .whereType<Map<String, dynamic>>()
              .map(SupportTicket.fromJson)
              .toList()
        : <SupportTicket>[];
    final currentPage = (result['page'] as num?)?.toInt() ?? page;
    final total = (result['total'] as num?)?.toInt() ?? items.length;
    return TicketPage(
      items: items,
      page: currentPage,
      hasMore:
          result['hasMore'] as bool? ??
          ((currentPage - 1) * pageSize + items.length < total),
    );
  }

  Future<SupportTicket> detail(int id) async {
    return SupportTicket.fromJson(await api.getJson('/api/c/v1/tickets/$id'));
  }

  Future<SupportTicket> create({
    required String subject,
    required String content,
    int shopId = 0,
  }) async {
    return SupportTicket.fromJson(
      await api.postJson(
        '/api/c/v1/tickets',
        body: {'subject': subject, 'content': content, 'shopId': shopId},
      ),
    );
  }

  Future<SupportTicket> reply(int id, String content) async {
    return SupportTicket.fromJson(
      await api.postJson(
        '/api/c/v1/tickets/$id/messages',
        body: {'content': content},
      ),
    );
  }
}
