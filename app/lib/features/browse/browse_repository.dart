import 'package:dazhongdianping_app/core/api_client.dart';

class ShopSummary {
  const ShopSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.score,
    required this.currency,
    required this.pricePerCapita,
  });
  final int id;
  final String name;
  final String category;
  final double score;
  final String currency;
  final num pricePerCapita;

  factory ShopSummary.fromJson(Map<String, dynamic> json) => ShopSummary(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    category: json['categoryName'] as String? ?? '',
    score: (json['score'] as num? ?? 0).toDouble(),
    currency: json['currency'] as String? ?? 'EUR',
    pricePerCapita: json['pricePerCapita'] as num? ?? 0,
  );
}

class ShopDetail {
  const ShopDetail({
    required this.id,
    required this.name,
    required this.category,
    required this.score,
    required this.currency,
    required this.pricePerCapita,
    required this.address,
    required this.phone,
    required this.businessHours,
    required this.summary,
    required this.tags,
  });

  final int id;
  final String name;
  final String category;
  final double score;
  final String currency;
  final num pricePerCapita;
  final String address;
  final String phone;
  final String businessHours;
  final String summary;
  final List<String> tags;

  factory ShopDetail.fromJson(Map<String, dynamic> json) => ShopDetail(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    category: json['categoryName'] as String? ?? '',
    score: (json['score'] as num? ?? 0).toDouble(),
    currency: json['currency'] as String? ?? 'EUR',
    pricePerCapita: json['pricePerCapita'] as num? ?? 0,
    address: json['address'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    businessHours: json['businessHours'] as String? ?? '',
    summary: json['summary'] as String? ?? '',
    tags: (json['tags'] as List<dynamic>? ?? const [])
        .map((item) => '$item')
        .toList(),
  );
}

abstract class BrowseRepository {
  Future<List<ShopSummary>> loadFeaturedShops();
  Future<List<ShopSummary>> searchShops(String keyword) =>
      throw UnimplementedError();
  Future<ShopDetail> loadShopDetail(int shopId) => throw UnimplementedError();
}

class ApiBrowseRepository implements BrowseRepository {
  ApiBrowseRepository(this.client);
  final JsonApi client;
  @override
  Future<List<ShopSummary>> loadFeaturedShops() async {
    final result = await client.getJson(
      '/api/c/v1/shops',
      query: const {'page': 1, 'pageSize': 12},
    );
    final list = result['list'] as List<dynamic>? ?? const [];
    return list.cast<Map<String, dynamic>>().map(ShopSummary.fromJson).toList();
  }

  @override
  Future<List<ShopSummary>> searchShops(String keyword) async {
    final result = await client.getJson(
      '/api/c/v1/search/shops',
      query: {'keyword': keyword, 'page': 1, 'pageSize': 20},
    );
    final list = result['list'] as List<dynamic>? ?? const [];
    return list.cast<Map<String, dynamic>>().map(ShopSummary.fromJson).toList();
  }

  @override
  Future<ShopDetail> loadShopDetail(int shopId) async {
    final result = await client.getJson('/api/c/v1/shops/$shopId');
    return ShopDetail.fromJson(result);
  }
}
