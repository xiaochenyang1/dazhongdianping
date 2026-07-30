import 'package:dazhongdianping_app/core/api_client.dart';

({String? code, String? label}) _badgeFromJson(Object? raw) {
  if (raw is! Map<String, dynamic>) {
    return (code: null, label: null);
  }
  final code = raw['code'];
  final label = raw['label'];
  return (
    code: code is String && code.trim().isNotEmpty ? code.trim() : null,
    label: label is String && label.trim().isNotEmpty ? label.trim() : null,
  );
}

class ShopSummary {
  const ShopSummary({
    required this.id,
    required this.name,
    required this.category,
    required this.score,
    required this.currency,
    required this.pricePerCapita,
    this.merchantCertificationCode,
    this.merchantCertificationLabel,
  });
  final int id;
  final String name;
  final String category;
  final double score;
  final String currency;
  final num pricePerCapita;
  final String? merchantCertificationCode;
  final String? merchantCertificationLabel;

  factory ShopSummary.fromJson(Map<String, dynamic> json) {
    final certification = _badgeFromJson(json['merchantCertification']);
    return ShopSummary(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      category: json['categoryName'] as String? ?? '',
      score: (json['score'] as num? ?? 0).toDouble(),
      currency: json['currency'] as String? ?? 'EUR',
      pricePerCapita: json['pricePerCapita'] as num? ?? 0,
      merchantCertificationCode: certification.code,
      merchantCertificationLabel: certification.label,
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

class SearchSuggestion {
  const SearchSuggestion({required this.term, required this.type, this.refId});
  final String term;
  final String type;
  final int? refId;

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    final ref = json['refId'];
    return SearchSuggestion(
      term: json['term'] as String? ?? '',
      type: json['type'] as String? ?? '',
      refId: ref is num ? ref.toInt() : null,
    );
  }
}

class ShopReviewPreview {
  const ShopReviewPreview({
    required this.id,
    required this.userName,
    required this.score,
    required this.content,
    required this.likedCount,
    required this.commentCount,
    required this.createdAt,
    this.authorCertificationCode,
    this.authorCertificationLabel,
    this.merchantReply,
  });

  final int id;
  final String userName;
  final double score;
  final String content;
  final int likedCount;
  final int commentCount;
  final String createdAt;
  final String? authorCertificationCode;
  final String? authorCertificationLabel;
  final String? merchantReply;

  factory ShopReviewPreview.fromJson(Map<String, dynamic> json) {
    final author = _badgeFromJson(json['authorCertification']);
    final reply = json['merchantReply'];
    String? merchantReply;
    if (reply is Map<String, dynamic>) {
      final content = reply['content'] as String? ?? '';
      if (content.trim().isNotEmpty) {
        merchantReply = content.trim();
      }
    }
    return ShopReviewPreview(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userName: json['userName'] as String? ?? '',
      score: (json['score'] as num? ?? 0).toDouble(),
      content: json['content'] as String? ?? '',
      likedCount: (json['likedCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
      authorCertificationCode: author.code,
      authorCertificationLabel: author.label,
      merchantReply: merchantReply,
    );
  }
}

class ShopReviewPage {
  const ShopReviewPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
  });

  final List<ShopReviewPreview> items;
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;

  factory ShopReviewPage.fromJson(Map<String, dynamic> json) {
    final list = json['list'] as List<dynamic>? ?? const [];
    final items = list
        .whereType<Map<String, dynamic>>()
        .map(ShopReviewPreview.fromJson)
        .where((item) => item.id > 0)
        .toList();
    final page = (json['page'] as num?)?.toInt() ?? 1;
    final pageSize = (json['pageSize'] as num?)?.toInt() ?? items.length;
    final total = (json['total'] as num?)?.toInt() ?? items.length;
    final hasMore = json['hasMore'] as bool? ?? (page * pageSize < total);
    return ShopReviewPage(
      items: items,
      page: page,
      pageSize: pageSize,
      total: total,
      hasMore: hasMore,
    );
  }
}

class ShopSearchPage {
  const ShopSearchPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });
  final List<ShopSummary> items;
  final int total;
  final int page;
  final int pageSize;

  bool get hasMore => items.length < total;
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

class SearchHistoryPage {
  const SearchHistoryPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<SearchHistoryItem> items;
  final int total, page, pageSize;

  bool get hasMore => items.length < total;
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
    this.merchantCertificationCode,
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
  final String? merchantCertificationCode;
  final String? merchantCertificationLabel;

  factory ShopBrowseHistoryItem.fromJson(Map<String, dynamic> json) {
    final certification = _badgeFromJson(json['merchantCertification']);
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
      merchantCertificationCode: certification.code,
      merchantCertificationLabel: certification.label,
    );
  }
}

class ShopBrowseHistoryPage {
  const ShopBrowseHistoryPage({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  final List<ShopBrowseHistoryItem> items;
  final int total;
  final int page;
  final int pageSize;

  bool get hasMore => items.length < total;
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
    this.merchantCertificationCode,
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
  final String? merchantCertificationCode;
  final String? merchantCertificationLabel;

  factory ShopDetail.fromJson(Map<String, dynamic> json) {
    final certification = _badgeFromJson(json['merchantCertification']);
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
      merchantCertificationCode: certification.code,
      merchantCertificationLabel: certification.label,
    );
  }
}

abstract class BrowseRepository {
  Future<List<ShopSummary>> loadFeaturedShops();
  Future<List<ShopSummary>> searchShops(String keyword) =>
      throw UnimplementedError();
  Future<ShopSearchPage> searchShopPage(
    String keyword, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final items = await searchShops(keyword);
    return ShopSearchPage(
      items: items,
      total: items.length,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<ShopDetail> loadShopDetail(int shopId) => throw UnimplementedError();
  Future<List<SearchHotWord>> loadHotWords({int limit = 8}) =>
      throw UnimplementedError();
  Future<List<SearchHistoryItem>> loadSearchHistory({
    int page = 1,
    int pageSize = 8,
  }) => throw UnimplementedError();
  Future<SearchHistoryPage> loadSearchHistoryPage({
    int page = 1,
    int pageSize = 8,
  }) async {
    final items = await loadSearchHistory(page: page, pageSize: pageSize);
    return SearchHistoryPage(
      items: items,
      total: items.length,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<void> clearSearchHistory() => throw UnimplementedError();
  Future<void> removeSearchHistoryItem(int historyId) =>
      throw UnimplementedError();
  Future<List<ShopBrowseHistoryItem>> loadBrowseHistory({
    int page = 1,
    int pageSize = 20,
  }) => throw UnimplementedError();
  Future<ShopBrowseHistoryPage> loadBrowseHistoryPage({
    int page = 1,
    int pageSize = 20,
  }) async {
    final items = await loadBrowseHistory(page: page, pageSize: pageSize);
    return ShopBrowseHistoryPage(
      items: items,
      total: items.length,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<void> clearBrowseHistory() => throw UnimplementedError();
  Future<void> removeBrowseHistoryItem(int shopId) =>
      throw UnimplementedError();
  Future<bool> isShopFavorited(int shopId) => throw UnimplementedError();
  Future<void> favoriteShop(int shopId) => throw UnimplementedError();
  Future<void> unfavoriteShop(int shopId) => throw UnimplementedError();
  Future<List<SearchSuggestion>> loadSearchSuggestions(
    String keyword, {
    int limit = 8,
  }) => throw UnimplementedError();
  Future<List<ShopSummary>> loadSimilarShops(int shopId, {int limit = 6}) =>
      throw UnimplementedError();
  Future<List<ShopReviewPreview>> loadShopReviews(
    int shopId, {
    int page = 1,
    int pageSize = 5,
    String sort = 'latest',
    double? minScore,
    bool? hasImages,
  }) => throw UnimplementedError();
  Future<ShopReviewPage> loadShopReviewPage(
    int shopId, {
    int page = 1,
    int pageSize = 20,
    String sort = 'latest',
    double? minScore,
    bool? hasImages,
  }) => throw UnimplementedError();
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
  Future<List<ShopSummary>> searchShops(String keyword) async =>
      (await searchShopPage(keyword)).items;

  @override
  Future<ShopSearchPage> searchShopPage(
    String keyword, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await client.getJson(
      '/api/c/v1/search/shops',
      query: {'keyword': keyword, 'page': page, 'pageSize': pageSize},
    );
    final list = result['list'] as List<dynamic>? ?? const [];
    final items = list
        .cast<Map<String, dynamic>>()
        .map(ShopSummary.fromJson)
        .toList();
    return ShopSearchPage(
      items: items,
      total: (result['total'] as num?)?.toInt() ?? items.length,
      page: (result['page'] as num?)?.toInt() ?? page,
      pageSize: (result['pageSize'] as num?)?.toInt() ?? pageSize,
    );
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
  }) async =>
      (await loadSearchHistoryPage(page: page, pageSize: pageSize)).items;

  @override
  Future<SearchHistoryPage> loadSearchHistoryPage({
    int page = 1,
    int pageSize = 8,
  }) async {
    try {
      final result = await client.getJson(
        '/api/c/v1/search/history',
        query: {'page': page, 'pageSize': pageSize},
      );
      final list = result['list'] as List<dynamic>? ?? const [];
      final items = list
          .whereType<Map<String, dynamic>>()
          .map(SearchHistoryItem.fromJson)
          .where((item) => item.keyword.isNotEmpty)
          .toList();
      return SearchHistoryPage(
        items: items,
        total: (result['total'] as num?)?.toInt() ?? items.length,
        page: (result['page'] as num?)?.toInt() ?? page,
        pageSize: (result['pageSize'] as num?)?.toInt() ?? pageSize,
      );
    } on ApiException catch (error) {
      // Guest sessions cannot read history; treat as empty instead of failing the panel.
      if (error.statusCode == 401) {
        return SearchHistoryPage(
          items: const [],
          total: 0,
          page: page,
          pageSize: pageSize,
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> clearSearchHistory() async {
    final deleteApi = client is JsonDeleteApi
        ? client as JsonDeleteApi
        : throw UnsupportedError(
            'JsonDeleteApi is required for clearSearchHistory',
          );
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
  }) async =>
      (await loadBrowseHistoryPage(page: page, pageSize: pageSize)).items;

  @override
  Future<ShopBrowseHistoryPage> loadBrowseHistoryPage({
    int page = 1,
    int pageSize = 20,
  }) async {
    final result = await client.getJson(
      '/api/c/v1/user/browse-history',
      query: {'page': page, 'pageSize': pageSize},
    );
    final list = result['list'] as List<dynamic>? ?? const [];
    final items = list
        .whereType<Map<String, dynamic>>()
        .map(ShopBrowseHistoryItem.fromJson)
        .where((item) => item.shopId > 0)
        .toList();
    return ShopBrowseHistoryPage(
      items: items,
      total: (result['total'] as num?)?.toInt() ?? items.length,
      page: (result['page'] as num?)?.toInt() ?? page,
      pageSize: (result['pageSize'] as num?)?.toInt() ?? pageSize,
    );
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

  @override
  Future<bool> isShopFavorited(int shopId) async {
    try {
      final result = await client.getJson(
        '/api/c/v1/favorites',
        query: {'targetType': 1, 'page': 1, 'pageSize': 50},
      );
      final list = result['list'] as List<dynamic>? ?? const [];
      return list.whereType<Map<String, dynamic>>().any((item) {
        final targetId = item['targetId'];
        return targetId is num && targetId.toInt() == shopId;
      });
    } on ApiException catch (error) {
      // Guest sessions cannot read favorites.
      if (error.statusCode == 401) {
        return false;
      }
      rethrow;
    }
  }

  @override
  Future<void> favoriteShop(int shopId) async {
    await client.postJson(
      '/api/c/v1/favorites',
      body: {'targetType': 1, 'targetId': shopId},
    );
  }

  @override
  Future<void> unfavoriteShop(int shopId) async {
    final deleteApi = client is JsonDeleteApi
        ? client as JsonDeleteApi
        : throw UnsupportedError(
            'JsonDeleteApi is required for unfavoriteShop',
          );
    await deleteApi.deleteJson(
      '/api/c/v1/favorites?targetType=1&targetId=$shopId',
    );
  }

  @override
  Future<List<SearchSuggestion>> loadSearchSuggestions(
    String keyword, {
    int limit = 8,
  }) async {
    final normalized = keyword.trim();
    if (normalized.isEmpty) return const [];
    final result = await client.getJson(
      '/api/c/v1/search/suggest',
      query: {'kw': normalized, 'limit': limit},
    );
    // ApiClient wraps bare list payloads as {'value': [...]}.
    final raw = result['value'] ?? result['list'];
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(SearchSuggestion.fromJson)
          .where((item) => item.term.isNotEmpty)
          .toList();
    }
    return const [];
  }

  @override
  Future<List<ShopSummary>> loadSimilarShops(
    int shopId, {
    int limit = 6,
  }) async {
    final result = await client.getJson(
      '/api/c/v1/shops/$shopId/similar',
      query: {'limit': limit},
    );
    final raw = result['value'] ?? result['list'];
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map((json) {
      // similar shops reuse list-item fields; fall back when categoryName is absent
      final mapped = <String, dynamic>{
        ...json,
        'categoryName':
            json['categoryName'] ??
            [
              if ((json['cityName'] as String?)?.isNotEmpty == true)
                json['cityName'],
              if ((json['areaName'] as String?)?.isNotEmpty == true)
                json['areaName'],
            ].join(' · '),
      };
      return ShopSummary.fromJson(mapped);
    }).toList();
  }

  @override
  Future<List<ShopReviewPreview>> loadShopReviews(
    int shopId, {
    int page = 1,
    int pageSize = 5,
    String sort = 'latest',
    double? minScore,
    bool? hasImages,
  }) async {
    final pageResult = await loadShopReviewPage(
      shopId,
      page: page,
      pageSize: pageSize,
      sort: sort,
      minScore: minScore,
      hasImages: hasImages,
    );
    return pageResult.items;
  }

  @override
  Future<ShopReviewPage> loadShopReviewPage(
    int shopId, {
    int page = 1,
    int pageSize = 20,
    String sort = 'latest',
    double? minScore,
    bool? hasImages,
  }) async {
    final result = await client.getJson(
      '/api/c/v1/shops/$shopId/reviews',
      query: {
        'page': page,
        'pageSize': pageSize,
        'sort': sort,
        if (minScore != null) 'minScore': minScore,
        if (hasImages != null) 'hasImages': hasImages,
      },
    );
    return ShopReviewPage.fromJson(result);
  }
}
