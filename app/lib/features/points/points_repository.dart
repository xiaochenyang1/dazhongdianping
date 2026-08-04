import 'package:dazhongdianping_app/core/api_client.dart';

/// 积分商城商品。stock / exchangeLimitPerUser 直接来自后端，避免客户端二次推断可兑状态。
class PointsProduct {
  const PointsProduct({
    required this.id,
    required this.region,
    required this.name,
    required this.coverImage,
    required this.description,
    required this.pointsPrice,
    required this.stock,
    required this.exchangeLimitPerUser,
    required this.exchangeCount,
    required this.fulfillType,
    required this.fulfillTypeText,
    required this.status,
    required this.sort,
    required this.soldOut,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String region;
  final String name;
  final String coverImage;
  final String description;
  final int pointsPrice;
  final int stock;
  final int exchangeLimitPerUser;
  final int exchangeCount;
  final int fulfillType;
  final String fulfillTypeText;
  final int status;
  final int sort;
  final bool soldOut;
  final String createdAt;
  final String updatedAt;

  bool get unlimitedPerUser => exchangeLimitPerUser <= 0;

  factory PointsProduct.fromJson(Map<String, dynamic> json) => PointsProduct(
    id: (json['id'] as num?)?.toInt() ?? 0,
    region: json['region'] as String? ?? '',
    name: json['name'] as String? ?? '',
    coverImage: json['coverImage'] as String? ?? '',
    description: json['description'] as String? ?? '',
    pointsPrice: (json['pointsPrice'] as num?)?.toInt() ?? 0,
    stock: (json['stock'] as num?)?.toInt() ?? 0,
    exchangeLimitPerUser: (json['exchangeLimitPerUser'] as num?)?.toInt() ?? 0,
    exchangeCount: (json['exchangeCount'] as num?)?.toInt() ?? 0,
    fulfillType: (json['fulfillType'] as num?)?.toInt() ?? 1,
    fulfillTypeText: json['fulfillTypeText'] as String? ?? '',
    status: (json['status'] as num?)?.toInt() ?? 0,
    sort: (json['sort'] as num?)?.toInt() ?? 0,
    soldOut: json['soldOut'] as bool? ?? false,
    createdAt: json['createdAt'] as String? ?? '',
    updatedAt: json['updatedAt'] as String? ?? '',
  );
}

class PointsProductPage {
  const PointsProductPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  final List<PointsProduct> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;
}

/// 兑换单。status: 0 待发放 / 1 已发放 / 2 已取消；取消后后端不再回传兑换码。
class PointsExchange {
  const PointsExchange({
    required this.id,
    required this.productId,
    required this.productName,
    required this.pointsCost,
    required this.quantity,
    required this.status,
    required this.statusText,
    required this.redeemCode,
    required this.remark,
    required this.fulfilledAt,
    required this.createdAt,
  });

  final int id;
  final int productId;
  final String productName;
  final int pointsCost;
  final int quantity;
  final int status;
  final String statusText;
  final String redeemCode;
  final String remark;
  final String fulfilledAt;
  final String createdAt;

  bool get pending => status == 0;
  bool get fulfilled => status == 1;
  bool get cancelled => status == 2;

  factory PointsExchange.fromJson(Map<String, dynamic> json) => PointsExchange(
    id: (json['id'] as num?)?.toInt() ?? 0,
    productId: (json['productId'] as num?)?.toInt() ?? 0,
    productName: json['productName'] as String? ?? '',
    pointsCost: (json['pointsCost'] as num?)?.toInt() ?? 0,
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    status: (json['status'] as num?)?.toInt() ?? 0,
    statusText: json['statusText'] as String? ?? '',
    redeemCode: json['redeemCode'] as String? ?? '',
    remark: json['remark'] as String? ?? '',
    fulfilledAt: json['fulfilledAt'] as String? ?? '',
    createdAt: json['createdAt'] as String? ?? '',
  );
}

class PointsExchangePage {
  const PointsExchangePage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  final List<PointsExchange> items;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;
}

class PointsMallRepository {
  PointsMallRepository(this.api);

  final JsonApi api;

  Future<PointsProductPage> loadProducts({
    int page = 1,
    int pageSize = 12,
  }) async {
    final result = await api.getJson(
      '/api/c/v1/points/products',
      query: {'page': page, 'pageSize': pageSize},
    );
    final items = (result['list'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PointsProduct.fromJson)
        .toList();
    return PointsProductPage(
      items: items,
      total: (result['total'] as num?)?.toInt() ?? items.length,
      page: (result['page'] as num?)?.toInt() ?? page,
      pageSize: (result['pageSize'] as num?)?.toInt() ?? pageSize,
      hasMore: result['hasMore'] as bool? ?? false,
    );
  }

  Future<PointsProduct> loadProduct(int productId) async =>
      PointsProduct.fromJson(
        await api.getJson('/api/c/v1/points/products/$productId'),
      );

  Future<PointsExchange> exchange(int productId) async =>
      PointsExchange.fromJson(
        await api.postJson('/api/c/v1/points/products/$productId/exchange'),
      );

  Future<PointsExchangePage> loadExchanges({
    int page = 1,
    int pageSize = 12,
  }) async {
    final result = await api.getJson(
      '/api/c/v1/points/exchanges',
      query: {'page': page, 'pageSize': pageSize},
    );
    final items = (result['list'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(PointsExchange.fromJson)
        .toList();
    return PointsExchangePage(
      items: items,
      total: (result['total'] as num?)?.toInt() ?? items.length,
      page: (result['page'] as num?)?.toInt() ?? page,
      pageSize: (result['pageSize'] as num?)?.toInt() ?? pageSize,
      hasMore: result['hasMore'] as bool? ?? false,
    );
  }
}
