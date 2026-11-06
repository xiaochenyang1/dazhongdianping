import 'dart:typed_data';
import 'package:dazhongdianping_app/core/api_client.dart';

class InvoiceTitle {
  const InvoiceTitle({
    required this.id,
    required this.name,
    required this.titleType,
    this.taxNo = '',
    this.email = '',
    this.isDefault = false,
  });
  final int id;
  final String name;
  final int titleType;
  final String taxNo;
  final String email;
  final bool isDefault;
  factory InvoiceTitle.fromJson(Map<String, dynamic> json) => InvoiceTitle(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? '',
    titleType: (json['titleType'] as num?)?.toInt() ?? 1,
    taxNo: json['taxNo'] as String? ?? '',
    email: json['email'] as String? ?? '',
    isDefault: json['isDefault'] == true,
  );
}

class InvoiceOrder {
  const InvoiceOrder({
    required this.id,
    required this.orderNo,
    required this.dealTitle,
    required this.shopName,
    required this.amount,
    required this.currency,
  });
  final int id;
  final String orderNo;
  final String dealTitle;
  final String shopName;
  final num amount;
  final String currency;
  factory InvoiceOrder.fromJson(Map<String, dynamic> json) => InvoiceOrder(
    id: (json['id'] as num).toInt(),
    orderNo: json['orderNo'] as String? ?? '',
    dealTitle: json['dealTitle'] as String? ?? '',
    shopName: json['shopName'] as String? ?? '',
    amount: json['amount'] as num? ?? 0,
    currency: json['currency'] as String? ?? '',
  );
}

class InvoiceRequestItem {
  const InvoiceRequestItem({
    required this.id,
    required this.orderId,
    required this.status,
    required this.amount,
    required this.taxAmount,
    required this.currency,
    this.invoiceNo = '',
    this.rejectReason = '',
    this.documentAvailable = false,
    this.documentSha256 = '',
    this.receivedAt = '',
  });
  final int id;
  final int orderId;
  final int status;
  final num amount;
  final num taxAmount;
  final String currency;
  final String invoiceNo;
  final String rejectReason;
  final bool documentAvailable;
  final String documentSha256;
  final String receivedAt;
  factory InvoiceRequestItem.fromJson(Map<String, dynamic> json) =>
      InvoiceRequestItem(
        id: (json['id'] as num).toInt(),
        orderId: (json['orderId'] as num).toInt(),
        status: (json['status'] as num?)?.toInt() ?? 0,
        amount: json['amount'] as num? ?? 0,
        taxAmount: json['taxAmount'] as num? ?? 0,
        currency: json['currency'] as String? ?? '',
        invoiceNo: json['invoiceNo'] as String? ?? '',
        rejectReason: json['rejectReason'] as String? ?? '',
        documentAvailable: json['documentAvailable'] == true,
        documentSha256: json['documentSha256'] as String? ?? '',
        receivedAt: json['receivedAt'] as String? ?? '',
      );
}

class InvoicePage<T> {
  const InvoicePage({
    required this.items,
    required this.page,
    required this.hasMore,
  });
  final List<T> items;
  final int page;
  final bool hasMore;
  factory InvoicePage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) decode,
  ) => InvoicePage(
    items: (json['list'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(decode)
        .toList(),
    page: (json['page'] as num?)?.toInt() ?? 1,
    hasMore: json['hasMore'] == true,
  );
}

class InvoiceRepository {
  InvoiceRepository(this.api);
  final JsonApi api;

  Future<Uint8List> download(int id) =>
      (api as BinaryApi).getBytes('/api/c/v1/invoices/$id/document');

  Future<InvoiceRequestItem> confirmReceipt(int id, String sha256) async =>
      InvoiceRequestItem.fromJson(
        await api.postJson(
          '/api/c/v1/invoices/$id/receipt',
          body: {'sha256': sha256},
        ),
      );

  Future<List<InvoiceTitle>> titles() async {
    final result = await api.getJson('/api/c/v1/invoices/titles');
    return ((result['list'] ?? result['value']) as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(InvoiceTitle.fromJson)
        .toList();
  }

  Future<InvoicePage<InvoiceOrder>> orders({
    int page = 1,
    int? orderId,
  }) async => InvoicePage.fromJson(
    await api.getJson(
      '/api/c/v1/invoices/orders',
      query: {
        'page': page,
        'pageSize': 12,
        if (orderId != null) 'orderId': orderId,
      },
    ),
    InvoiceOrder.fromJson,
  );

  Future<InvoicePage<InvoiceRequestItem>> invoices({int page = 1}) async =>
      InvoicePage.fromJson(
        await api.getJson(
          '/api/c/v1/invoices',
          query: {'page': page, 'pageSize': 12},
        ),
        InvoiceRequestItem.fromJson,
      );

  Future<InvoiceTitle> saveTitle({
    required int titleType,
    required String name,
    String taxNo = '',
    String email = '',
    bool isDefault = false,
  }) async => InvoiceTitle.fromJson(
    await api.postJson(
      '/api/c/v1/invoices/titles',
      body: {
        'titleType': titleType,
        'name': name,
        'taxNo': taxNo,
        'email': email,
        'isDefault': isDefault,
      },
    ),
  );

  Future<InvoiceRequestItem> requestInvoice({
    required int orderId,
    required int titleId,
  }) async => InvoiceRequestItem.fromJson(
    await api.postJson(
      '/api/c/v1/invoices',
      body: {'orderId': orderId, 'titleId': titleId},
    ),
  );
}
