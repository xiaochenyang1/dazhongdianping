import 'package:dazhongdianping_app/core/api_client.dart';

class DealSummary {
  const DealSummary({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.title,
    required this.price,
    required this.originalPrice,
    required this.currency,
    required this.stock,
    required this.soldCount,
  });
  final int id;
  final int shopId;
  final String shopName;
  final String title;
  final num price;
  final num originalPrice;
  final String currency;
  final int stock;
  final int soldCount;

  factory DealSummary.fromJson(Map<String, dynamic> json) => DealSummary(
    id: json['id'] as int,
    shopId: json['shopId'] as int? ?? 0,
    shopName: json['shopName'] as String? ?? '',
    title: json['title'] as String? ?? '',
    price: json['price'] as num? ?? 0,
    originalPrice: json['originalPrice'] as num? ?? 0,
    currency: json['currency'] as String? ?? 'EUR',
    stock: json['stock'] as int? ?? 0,
    soldCount: json['soldCount'] as int? ?? 0,
  );
}

class TradeOrder {
  const TradeOrder({
    required this.id,
    required this.orderNo,
    required this.dealTitle,
    required this.shopName,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    required this.currency,
    required this.payStatus,
    required this.payStatusText,
    required this.status,
    required this.coupons,
    this.refund,
  });
  final int id;
  final String orderNo;
  final String dealTitle;
  final String shopName;
  final int quantity;
  final num unitPrice;
  final num amount;
  final String currency;
  final int payStatus;
  final String payStatusText;
  final int status;
  final List<Coupon> coupons;
  final RefundInfo? refund;

  factory TradeOrder.fromJson(Map<String, dynamic> json) => TradeOrder(
    id: json['id'] as int,
    orderNo: json['orderNo'] as String? ?? '',
    dealTitle: json['dealTitle'] as String? ?? '',
    shopName: json['shopName'] as String? ?? '',
    quantity: json['quantity'] as int? ?? 0,
    unitPrice: json['unitPrice'] as num? ?? 0,
    amount: json['amount'] as num? ?? 0,
    currency: json['currency'] as String? ?? 'EUR',
    payStatus: json['payStatus'] as int? ?? 0,
    payStatusText: json['payStatusText'] as String? ?? '',
    status: json['status'] as int? ?? 1,
    coupons: (json['coupons'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(Coupon.fromJson)
        .toList(),
    refund: json['refund'] is Map<String, dynamic>
        ? RefundInfo.fromJson(json['refund'] as Map<String, dynamic>)
        : null,
  );
}

class TradeOrderPage {
  const TradeOrderPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<TradeOrder> items;
  final int total;
  final int page;
  final int pageSize;

  bool get hasMore => items.length < total;
}

class Coupon {
  const Coupon({
    required this.id,
    required this.orderId,
    required this.code,
    required this.status,
    required this.statusText,
    required this.dealTitle,
    required this.shopName,
    required this.expireAt,
    this.dealId = 0,
    this.shopId = 0,
    this.coverImage = '',
  });
  final int id;
  final int orderId;
  final String code;
  final int status;
  final String statusText;
  final String dealTitle;
  final String shopName;
  final String expireAt;
  final int dealId;
  final int shopId;
  final String coverImage;

  factory Coupon.fromJson(Map<String, dynamic> json) => Coupon(
    id: json['id'] as int,
    orderId: json['orderId'] as int? ?? 0,
    code: json['code'] as String? ?? '',
    status: json['status'] as int? ?? 1,
    statusText: json['statusText'] as String? ?? '',
    dealTitle: json['dealTitle'] as String? ?? '',
    shopName: json['shopName'] as String? ?? '',
    expireAt: json['expireAt'] as String? ?? '',
    dealId: json['dealId'] as int? ?? 0,
    shopId: json['shopId'] as int? ?? 0,
    coverImage: json['coverImage'] as String? ?? '',
  );
}

class CouponDetail extends Coupon {
  const CouponDetail({
    required super.id,
    required super.orderId,
    required super.code,
    required super.status,
    required super.statusText,
    required super.dealTitle,
    required super.shopName,
    required super.expireAt,
    super.dealId,
    super.shopId,
    super.coverImage,
    required this.rules,
    required this.validStart,
    required this.validEnd,
    required this.verifyAt,
    required this.usable,
    required this.qrPayload,
    required this.qrImageUrl,
    required this.verifyHint,
  });

  final String rules;
  final String validStart;
  final String validEnd;
  final String verifyAt;
  final bool usable;
  final String qrPayload;
  final String qrImageUrl;
  final String verifyHint;

  factory CouponDetail.fromJson(Map<String, dynamic> json) => CouponDetail(
    id: json['id'] as int,
    orderId: json['orderId'] as int? ?? 0,
    code: json['code'] as String? ?? '',
    status: json['status'] as int? ?? 1,
    statusText: json['statusText'] as String? ?? '',
    dealTitle: json['dealTitle'] as String? ?? '',
    shopName: json['shopName'] as String? ?? '',
    expireAt: json['expireAt'] as String? ?? '',
    dealId: json['dealId'] as int? ?? 0,
    shopId: json['shopId'] as int? ?? 0,
    coverImage: json['coverImage'] as String? ?? '',
    rules: json['rules'] as String? ?? '',
    validStart: json['validStart'] as String? ?? '',
    validEnd: json['validEnd'] as String? ?? '',
    verifyAt: json['verifyAt'] as String? ?? '',
    usable: json['usable'] as bool? ?? false,
    qrPayload: json['qrPayload'] as String? ?? json['code'] as String? ?? '',
    qrImageUrl: json['qrImageUrl'] as String? ?? '',
    verifyHint: json['verifyHint'] as String? ?? '',
  );
}

class RefundInfo {
  const RefundInfo({
    required this.reason,
    required this.statusText,
    required this.auditReason,
  });
  final String reason;
  final String statusText;
  final String auditReason;

  factory RefundInfo.fromJson(Map<String, dynamic> json) => RefundInfo(
    reason: json['reason'] as String? ?? '',
    statusText: json['statusText'] as String? ?? '',
    auditReason: json['auditReason'] as String? ?? '',
  );
}

class PaymentIntent {
  const PaymentIntent({
    required this.channel,
    required this.orderNo,
    required this.amount,
    required this.currency,
  });
  final String channel;
  final String orderNo;
  final num amount;
  final String currency;

  factory PaymentIntent.fromJson(Map<String, dynamic> json) => PaymentIntent(
    channel: json['channel'] as String? ?? '',
    orderNo: json['orderNo'] as String? ?? '',
    amount: json['amount'] as num? ?? 0,
    currency: json['currency'] as String? ?? 'EUR',
  );
}

class TradeRepository {
  TradeRepository(this.api);
  final JsonApi api;

  Future<List<DealSummary>> loadShopDeals(int shopId) async {
    final result = await api.getJson('/api/c/v1/shops/$shopId/deals');
    final list = result['value'] as List<dynamic>? ?? const [];
    return list.cast<Map<String, dynamic>>().map(DealSummary.fromJson).toList();
  }

  Future<TradeOrder> createOrder({
    required int dealId,
    required int quantity,
  }) async {
    return TradeOrder.fromJson(
      await api.postJson(
        '/api/c/v1/orders',
        body: {'dealId': dealId, 'quantity': quantity},
      ),
    );
  }

  Future<PaymentIntent> createPayment(int orderId) async {
    return PaymentIntent.fromJson(
      await api.postJson('/api/c/v1/orders/$orderId/pay'),
    );
  }

  Future<TradeOrder> loadOrder(int orderId) async {
    return TradeOrder.fromJson(await api.getJson('/api/c/v1/orders/$orderId'));
  }

  Future<TradeOrder> cancelOrder(int orderId) async {
    return TradeOrder.fromJson(
      await api.postJson('/api/c/v1/orders/$orderId/cancel'),
    );
  }

  Future<TradeOrder> refundOrder(int orderId, {required String reason}) async {
    return TradeOrder.fromJson(
      await api.postJson(
        '/api/c/v1/orders/$orderId/refund',
        body: {'reason': reason},
      ),
    );
  }

  Future<List<Coupon>> loadCoupons({
    int? status,
    int page = 1,
    int pageSize = 30,
  }) async {
    final result = await api.getJson(
      '/api/c/v1/coupons',
      query: {
        'page': page,
        'pageSize': pageSize,
        if (status != null) 'status': status,
      },
    );
    return (result['list'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(Coupon.fromJson)
        .toList();
  }

  Future<List<TradeOrder>> loadOrders({
    int? payStatus,
    int page = 1,
    int pageSize = 30,
  }) async => (await loadOrderPage(
    payStatus: payStatus,
    page: page,
    pageSize: pageSize,
  )).items;

  Future<TradeOrderPage> loadOrderPage({
    int? payStatus,
    int page = 1,
    int pageSize = 30,
  }) async {
    final result = await api.getJson(
      '/api/c/v1/orders',
      query: {
        'page': page,
        'pageSize': pageSize,
        if (payStatus != null) 'payStatus': payStatus,
      },
    );
    final items = (result['list'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(TradeOrder.fromJson)
        .toList();
    return TradeOrderPage(
      items: items,
      total: (result['total'] as num?)?.toInt() ?? items.length,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<CouponDetail> loadCouponDetail(String code) async {
    final result = await api.getJson(
      '/api/c/v1/coupons/${Uri.encodeComponent(code)}',
    );
    return CouponDetail.fromJson(result);
  }
}
