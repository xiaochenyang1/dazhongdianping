import 'package:dazhongdianping_app/core/api_client.dart';

class RankSummary {
  const RankSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.typeText,
    required this.cityName,
    required this.categoryName,
    required this.period,
    required this.itemCount,
    required this.topShopName,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final int? type;
  final String typeText;
  final String cityName;
  final String categoryName;
  final String period;
  final int itemCount;
  final String topShopName;
  final String updatedAt;

  factory RankSummary.fromJson(Map<String, dynamic> json) => RankSummary(
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    type: (json['type'] as num?)?.toInt(),
    typeText: json['typeText'] as String? ?? '',
    cityName: json['cityName'] as String? ?? '',
    categoryName: json['categoryName'] as String? ?? '',
    period: json['period'] as String? ?? '',
    itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
    topShopName: json['topShopName'] as String? ?? '',
    updatedAt: json['updatedAt'] as String? ?? '',
  );
}

class RankShop {
  const RankShop({
    required this.id,
    required this.name,
    required this.score,
    required this.currency,
    required this.pricePerCapita,
    required this.cityName,
    required this.areaName,
    this.merchantCertificationLabel,
  });

  final int id;
  final String name;
  final double score;
  final String currency;
  final num pricePerCapita;
  final String cityName;
  final String areaName;
  final String? merchantCertificationLabel;

  factory RankShop.fromJson(Map<String, dynamic> json) {
    final certification = json['merchantCertification'];
    String? label;
    if (certification is Map<String, dynamic>) {
      final value = certification['label'];
      if (value is String && value.trim().isNotEmpty) label = value.trim();
    }
    return RankShop(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      score: (json['score'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
      pricePerCapita: json['pricePerCapita'] as num? ?? 0,
      cityName: json['cityName'] as String? ?? '',
      areaName: json['areaName'] as String? ?? '',
      merchantCertificationLabel: label,
    );
  }
}

class RankItem {
  const RankItem({
    required this.position,
    required this.rankScore,
    required this.reason,
    required this.shop,
  });

  final int position;
  final double rankScore;
  final String reason;
  final RankShop shop;

  factory RankItem.fromJson(Map<String, dynamic> json) {
    final shopJson = json['shop'];
    return RankItem(
      position: (json['position'] as num?)?.toInt() ?? 0,
      rankScore: (json['rankScore'] as num? ?? 0).toDouble(),
      reason: json['reason'] as String? ?? '',
      shop: shopJson is Map<String, dynamic>
          ? RankShop.fromJson(shopJson)
          : const RankShop(
              id: 0,
              name: '',
              score: 0,
              currency: 'EUR',
              pricePerCapita: 0,
              cityName: '',
              areaName: '',
            ),
    );
  }
}

class RankDetail {
  const RankDetail({
    required this.id,
    required this.name,
    required this.type,
    required this.typeText,
    required this.cityName,
    required this.categoryName,
    required this.period,
    required this.updatedAt,
    required this.items,
  });

  final int id;
  final String name;
  final int? type;
  final String typeText;
  final String cityName;
  final String categoryName;
  final String period;
  final String updatedAt;
  final List<RankItem> items;

  factory RankDetail.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RankItem.fromJson)
        .toList();
    return RankDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      type: (json['type'] as num?)?.toInt(),
      typeText: json['typeText'] as String? ?? '',
      cityName: json['cityName'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      period: json['period'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      items: items,
    );
  }
}

class RankRepository {
  RankRepository(this.api);
  final JsonApi api;

  Future<List<RankSummary>> loadRanks({int? type}) async {
    final result = await api.getJson(
      '/api/c/v1/ranks',
      query: {if (type != null) 'type': type},
    );
    final raw = result['value'] ?? result['list'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(RankSummary.fromJson)
        .where((item) => item.id > 0)
        .toList();
  }

  Future<RankDetail> loadRankDetail(int rankId) async {
    final result = await api.getJson('/api/c/v1/ranks/$rankId');
    return RankDetail.fromJson(result);
  }
}
