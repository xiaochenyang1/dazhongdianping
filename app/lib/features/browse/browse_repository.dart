import 'package:dazhongdianping_app/core/api_client.dart';

class ShopSummary {
  const ShopSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.score,
    required this.currency,
    required this.pricePerCapita,
    this.merchantCertificationLabel,
  });
  final int id;
  final String name;
  final String category;
  final double score;
  final String currency;
  final num pricePerCapita;
  final String? merchantCertificationLabel;

  factory ShopSummary.fromJson(Map<String, dynamic> json) {
    final certification = json['merchantCertification'];
    String? label;
    if (certification is Map<String, dynamic>) {
      final value = certification['label'];
      if (value is String && value.trim().isNotEmpty) {
        label = value.trim();
      }
    }
    return ShopSummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      category: json['categoryName'] as String? ?? '',
      score: (json['score'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
      pricePerCapita: json['pricePerCapita'] as num? ?? 0,
      merchantCertificationLabel: label,
    );
  }
}

class SearchHotWord {
  const SearchHotWord({required this.term, required this.score});
  final String term;
  final int score;

  factory SearchHotWord.fromJson(Map<String, dynamic> json) {
    return SearchHotWord(
      term: json['term'] as String? ?? '',
      score: (json['score'] as num? ?? 0).toInt(),
    );
  }
}

class SearchHistoryItem {
  const SearchHistoryItem({
    required this.id,
    required this.keyword,
    required this.region,
    required this.updatedAt,
  });
  final int id;
  final String keyword;
  final String region;
  final String updatedAt;

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      keyword: json['keyword'] as String? ?? '',
      region: json['region'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}

class ShopBrowseHistoryItem {
  const ShopBrowseHistoryItem({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.score,
    required this.currency,
    required this.pricePerCapita,
    required this.address,
    required this.cityName,
    required this.areaName,
    required this.viewCount,
    required this.lastViewedAt,
    this.merchantCertificationLabel,
  });

  final int id;
  final int shopId;
  final String shopName;
  final double score;
  final String currency;
  final num pricePerCapita;
  final String address;
  final String cityName;
  final String areaName;
  final int viewCount;
  final String lastViewedAt;
  final String? merchantCertificationLabel;

  factory ShopBrowseHistoryItem.fromJson(Map<String, dynamic> json) {
    final certification = json['merchantCertification'];
    String? label;
    if (certification is Map<String, dynamic>) {
      final value = certification['label'];
      if (value is String && value.trim().isNotEmpty) {
        label = value.trim();
      }
    }
    return ShopBrowseHistoryItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      shopId: (json['shopId'] as num?)?.toInt() ?? 0,
      shopName: json['shopName'] as String? ?? '',
      score: (json['score'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
      pricePerCapita: json['pricePerCapita'] as num? ?? 0,
      address: json['address'] as String? ?? '',
      cityName: json['cityName'] as String? ?? '',
      areaName: json['areaName'] as String? ?? '',
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 1,
      lastViewedAt: json['lastViewedAt'] as String? ?? '',
      merchantCertificationLabel: label,
    );
  }
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
    this.merchantCertificationLabel,
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
  final String? merchantCertificationLabel;

  factory ShopDetail.fromJson(Map<String, dynamic> json) {
    final certification = json['merchantCertification'];
    String? label;
    if (certification is Map<String, dynamic>) {
      final value = certification['label'];
      if (value is String && value.trim().isNotEmpty) {
        label = value.trim();
      }
    }
    return ShopDetail(
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
      merchantCertificationLabel: label,
    );
  }
}

abstract class BrowseRepository {
  Future<List<ShopSummary>> loadFeaturedShops();
  Future<List<ShopSummary>> searchShops(String keyword) =>
      throw UnimplementedError();
  Future<ShopDetail> loadShopDetail(int shopId) => throw UnimplementedError();
  Future<List<SearchHotWord>> loadHotWords({int limit = 8}) =>
      throw UnimplementedError();
  Future<List<SearchHistoryItem>> loadSearchHistory({
    int page = 1,
    int pageSize = 8,
  }) => throw UnimplementedError();
  Future<void> clearSearchHistory() => throw UnimplementedError();
  Future<void> removeSearchHistoryItem(int historyId) =>
      throw UnimplementedError();
  Future<List<ShopBrowseHistoryItem>> loadBrowseHistory({
    int page = 1,
    int pageSize = 20,
  }) => throw UnimplementedError();
  Future<void> clearBrowseHistory() => throw UnimplementedError();
  Future<void> removeBrowseHistoryItem(int shopId) =>
      throw UnimplementedError();
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

  @override
  Future<List<SearchHotWord>> loadHotWords({int limit = 8}) async {
    final result = await client.getJson(
      '/api/c/v1/search/hot',
      query: {'limit': limit},
    );
    // ApiClient wraps bare list payloads as {'value': [...]}.
    final raw = result['value'] ?? result['list'];
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(SearchHotWord.fromJson)
          .where((item) => item.term.isNotEmpty)
          .toList();
    }
    return const [];
  }

  @override
  Future<List<SearchHistoryItem>> loadSearchHistory({
    int page = 1,
    int pageSize = 8,
  }) async {
    try {
      final result = await client.getJson(
        '/api/c/v1/search/history',
        query: {'page': page, 'pageSize': pageSize},
      );
      final list = result['list'] as List<dynamic>? ?? const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(SearchHistoryItem.fromJson)
          .where((item) => item.keyword.isNotEmpty)
          .toList();
    } on ApiException catch (error) {
      // Guest sessions cannot read history; treat as empty instead of failing the panel.
      if (error.statusCode == 401) {
        return const [];
      }
      rethrow;
    }
  }

  @override
  Future<void> clearSearchHistory() async {
    final deleteApi = client is JsonDeleteApi
        ? client as JsonDeleteApi
        : throw UnsupportedError('JsonDeleteApi is required for clearSearchHistory');
    await deleteApi.deleteJson('/api/c/v1/search/history');
  }

  @override
  Future<void> removeSearchHistoryItem(int historyId) async {
    final deleteApi = client is JsonDeleteApi
        ? client as JsonDeleteApi
        : throw UnsupportedError(
            'JsonDeleteApi is required for removeSearchHistoryItem',
          );
    await deleteApi.deleteJson('/api/c/v1/search/history/$historyId');
  }

  @override
  Future<List<ShopBrowseHistoryItem>> loadBrowseHistory({
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await client.getJson(
      '/api/c/v1/user/browse-history',
      query: {'page': page, 'pageSize': pageSize},
    );
    final list = result['list'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ShopBrowseHistoryItem.fromJson)
        .where((item) => item.shopId > 0)
        .toList();
  }

  @override
  Future<void> clearBrowseHistory() async {
    final deleteApi = client is JsonDeleteApi
        ? client as JsonDeleteApi
        : throw UnsupportedError(
            'JsonDeleteApi is required for clearBrowseHistory',
          );
    await deleteApi.deleteJson('/api/c/v1/user/browse-history');
  }

  @override
  Future<void> removeBrowseHistoryItem(int shopId) async {
    final deleteApi = client is JsonDeleteApi
        ? client as JsonDeleteApi
        : throw UnsupportedError(
            'JsonDeleteApi is required for removeBrowseHistoryItem',
          );
    await deleteApi.deleteJson('/api/c/v1/user/browse-history/$shopId');
  }
}
