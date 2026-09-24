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
  });

  final int id;
  final String subject;
  final String content;
  final int status;
  final String statusText;
  final int shopId;
  final List<TicketMessage> messages;

  factory SupportTicket.fromJson(Map<String, dynamic> json) => SupportTicket(
        id: (json['id'] as num?)?.toInt() ?? 0,
        subject: json['subject'] as String? ?? '',
        content: json['content'] as String? ?? '',
        status: (json['status'] as num?)?.toInt() ?? 1,
        statusText: json['statusText'] as String? ?? '',
        shopId: (json['shopId'] as num?)?.toInt() ?? 0,
        messages: (json['messages'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(TicketMessage.fromJson)
            .toList(),
      );
}

class TicketMessage {
  const TicketMessage({required this.id, required this.content, required this.senderType});

  final int id;
  final String content;
  final int senderType;

  factory TicketMessage.fromJson(Map<String, dynamic> json) => TicketMessage(
        id: (json['id'] as num?)?.toInt() ?? 0,
        content: json['content'] as String? ?? '',
        senderType: (json['senderType'] as num?)?.toInt() ?? 1,
      );
}

class TicketRepository {
  TicketRepository(this.api);

  final JsonApi api;

  Future<List<SupportTicket>> loadMine() async {
    final result = await api.getJson('/api/c/v1/tickets');
    final raw = result['list'];
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map(SupportTicket.fromJson).toList();
  }

  Future<SupportTicket> detail(int id) async {
    return SupportTicket.fromJson(await api.getJson('/api/c/v1/tickets/$id'));
  }

  Future<SupportTicket> create({required String subject, required String content, int shopId = 0}) async {
    return SupportTicket.fromJson(await api.postJson('/api/c/v1/tickets', body: {
      'subject': subject,
      'content': content,
      'shopId': shopId,
    }));
  }

  Future<SupportTicket> reply(int id, String content) async {
    return SupportTicket.fromJson(await api.postJson('/api/c/v1/tickets/$id/messages', body: {'content': content}));
  }
}
