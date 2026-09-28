import 'package:dazhongdianping_app/core/api_client.dart';

/// 领券中心的一张可领券模板 + 当前用户领取状态。
class CouponCenterItem {
  const CouponCenterItem({
    required this.id,
    required this.name,
    required this.type,
    required this.typeText,
    required this.thresholdAmount,
    required this.discountAmount,
    required this.currency,
    required this.shopId,
    required this.perUserLimit,
    required this.validDays,
    required this.claimed,
    required this.soldOut,
    required this.claimable,
  });

  final int id;
  final String name;
  final int type;
  final String typeText;
  final double thresholdAmount;
  final double discountAmount;
  final String currency;
  final int shopId;
  final int perUserLimit;
  final int validDays;
  final bool claimed;
  final bool soldOut;
  final bool claimable;

  static double _toDouble(Object? v) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? 0}') ?? 0;

  factory CouponCenterItem.fromJson(Map<String, dynamic> json) => CouponCenterItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        type: (json['type'] as num?)?.toInt() ?? 1,
        typeText: json['typeText'] as String? ?? '',
        thresholdAmount: _toDouble(json['thresholdAmount']),
        discountAmount: _toDouble(json['discountAmount']),
        currency: json['currency'] as String? ?? '',
        shopId: (json['shopId'] as num?)?.toInt() ?? 0,
        perUserLimit: (json['perUserLimit'] as num?)?.toInt() ?? 1,
        validDays: (json['validDays'] as num?)?.toInt() ?? 0,
        claimed: json['claimed'] as bool? ?? false,
        soldOut: json['soldOut'] as bool? ?? false,
        claimable: json['claimable'] as bool? ?? false,
      );
}

/// 用户已领取的营销券。status：1=未使用 2=已使用 3=已过期。
class MarketingCoupon {
  const MarketingCoupon({
    required this.id,
    required this.templateId,
    required this.templateName,
    required this.type,
    required this.typeText,
    required this.thresholdAmount,
    required this.discountAmount,
    required this.currency,
    required this.shopId,
    required this.status,
    required this.statusText,
    this.expireAt,
    this.usedAt,
  });

  final int id;
  final int templateId;
  final String templateName;
  final int type;
  final String typeText;
  final double thresholdAmount;
  final double discountAmount;
  final String currency;
  final int shopId;
  final int status;
  final String statusText;
  final String? expireAt;
  final String? usedAt;

  factory MarketingCoupon.fromJson(Map<String, dynamic> json) => MarketingCoupon(
        id: (json['id'] as num?)?.toInt() ?? 0,
        templateId: (json['templateId'] as num?)?.toInt() ?? 0,
        templateName: json['templateName'] as String? ?? '',
        type: (json['type'] as num?)?.toInt() ?? 1,
        typeText: json['typeText'] as String? ?? '',
        thresholdAmount: CouponCenterItem._toDouble(json['thresholdAmount']),
        discountAmount: CouponCenterItem._toDouble(json['discountAmount']),
        currency: json['currency'] as String? ?? '',
        shopId: (json['shopId'] as num?)?.toInt() ?? 0,
        status: (json['status'] as num?)?.toInt() ?? 1,
        statusText: json['statusText'] as String? ?? '',
        expireAt: json['expireAt'] as String?,
        usedAt: json['usedAt'] as String?,
      );
}

/// C端营销券仓库：领券中心、领券、我的营销券、下单可用券。
class MarketingRepository {
  MarketingRepository(this.api);

  final JsonApi api;

  /// 领券中心：当前区域可领取的券模板（匿名可看，登录后带领取状态）。
  Future<List<CouponCenterItem>> loadCenter() async {
    final result = await api.getJson('/api/c/v1/marketing/coupons/center');
    final raw = result['value'] ?? result['list'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(CouponCenterItem.fromJson)
        .toList();
  }

  /// 领取一张券（需登录）。
  Future<MarketingCoupon> claim(int templateId) async {
    final result =
        await api.postJson('/api/c/v1/marketing/coupons/$templateId/claim');
    return MarketingCoupon.fromJson(result);
  }

  /// 我的营销券钱包。status 可选：1/2/3。
  Future<List<MarketingCoupon>> loadMyCoupons({int? status}) async {
    final query = <String, Object?>{'page': 1, 'pageSize': 50};
    if (status != null) query['status'] = status;
    final result =
        await api.getJson('/api/c/v1/marketing/coupons/mine', query: query);
    final raw = result['list'] ?? result['value'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(MarketingCoupon.fromJson)
        .toList();
  }

  /// 下单前查询某团购下可用的营销券。
  Future<List<MarketingCoupon>> loadUsableCoupons(int dealId,
      {int quantity = 1}) async {
    final result = await api.getJson(
      '/api/c/v1/deals/$dealId/usable-coupons',
      query: {'quantity': quantity},
    );
    final raw = result['value'] ?? result['list'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(MarketingCoupon.fromJson)
        .toList();
  }
}
