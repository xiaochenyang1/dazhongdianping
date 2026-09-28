import 'package:dazhongdianping_app/core/api_client.dart';

class CreatorTask {
  const CreatorTask({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardPoints,
    required this.claimStatus,
  });

  final int id;
  final String title;
  final String description;
  final int rewardPoints;
  final int claimStatus;

  factory CreatorTask.fromJson(Map<String, dynamic> json) => CreatorTask(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 0,
        claimStatus: (json['claimStatus'] as num?)?.toInt() ?? 0,
      );
}

class CreatorRepository {
  CreatorRepository(this.api);

  final JsonApi api;

  Future<List<CreatorTask>> load() async {
    final result = await api.getJson('/api/c/v1/creator/tasks');
    final raw = result['list'];
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map(CreatorTask.fromJson).toList();
  }

  Future<void> claim(int id) => api.postJson('/api/c/v1/creator/tasks/$id/claim');

  Future<void> complete(int id) => api.postJson('/api/c/v1/creator/tasks/$id/complete');
}

class InvoiceTitle {
  const InvoiceTitle({required this.id, required this.name, required this.titleType});

  final int id;
  final String name;
  final int titleType;

  factory InvoiceTitle.fromJson(Map<String, dynamic> json) => InvoiceTitle(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        titleType: (json['titleType'] as num?)?.toInt() ?? 1,
      );
}

class InvoiceRequestItem {
  const InvoiceRequestItem({
    required this.id,
    required this.orderId,
    required this.statusText,
    required this.amount,
    required this.taxAmount,
  });

  final int id;
  final int orderId;
  final String statusText;
  final num amount;
  final num taxAmount;

  factory InvoiceRequestItem.fromJson(Map<String, dynamic> json) => InvoiceRequestItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        orderId: (json['orderId'] as num?)?.toInt() ?? 0,
        statusText: json['statusText'] as String? ?? '',
        amount: json['amount'] as num? ?? 0,
        taxAmount: json['taxAmount'] as num? ?? 0,
      );
}

class InvoiceRepository {
  InvoiceRepository(this.api);

  final JsonApi api;

  Future<List<InvoiceTitle>> titles() async {
    final result = await api.getJson('/api/c/v1/invoices/titles');
    final raw = result['list'] ?? result['value'];
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().map(InvoiceTitle.fromJson).toList();
    }
    return const [];
  }

  Future<List<InvoiceRequestItem>> invoices() async {
    final result = await api.getJson('/api/c/v1/invoices');
    final raw = result['list'];
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map(InvoiceRequestItem.fromJson).toList();
  }

  Future<void> saveTitle({required int titleType, required String name, String taxNo = ''}) {
    return api.postJson('/api/c/v1/invoices/titles', body: {
      'titleType': titleType,
      'name': name,
      'taxNo': taxNo,
      'isDefault': false,
    });
  }

  Future<void> requestInvoice({required int orderId, required int titleId}) {
    return api.postJson('/api/c/v1/invoices', body: {'orderId': orderId, 'titleId': titleId});
  }
}
