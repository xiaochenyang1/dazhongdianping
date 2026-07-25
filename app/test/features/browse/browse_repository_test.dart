import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeJsonApi implements JsonApi, JsonDeleteApi {
  String? path;
  Map<String, Object?>? query;
  final List<String> deletedPaths = <String>[];
  bool throwUnauthorizedOnHistory = false;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    this.path = path;
    this.query = query;
    if (path.endsWith('/99')) {
      return {
        'id': 99,
        'name': 'Paris Noodles',
        'categoryName': 'Chinese',
        'score': 4.7,
        'currency': 'EUR',
        'pricePerCapita': 22,
        'address': 'Rue de Lyon',
        'phone': '+331000000',
        'businessHours': '10:00-22:00',
        'summary': 'Hand-pulled noodles',
        'tags': ['Noodles'],
      };
    }
    if (path == '/api/c/v1/search/hot') {
      return {
        'value': [
          {'term': 'Brunch', 'score': 12},
          {'term': 'Hotpot', 'score': 9},
        ],
      };
    }
    if (path == '/api/c/v1/search/suggest') {
      return {
        'value': [
          {'term': '火锅', 'type': 'category', 'refId': 102},
          {'term': '渝里火锅徐汇店', 'type': 'shop', 'refId': 10001},
        ],
      };
    }
    if (path.endsWith('/similar')) {
      return {
        'value': [
          {
            'id': 10002,
            'name': '徐汇小馆',
            'cityName': '上海',
            'areaName': '徐汇',
            'score': 4.6,
            'currency': 'CNY',
            'pricePerCapita': 88,
          },
        ],
      };
    }
    if (path == '/api/c/v1/search/history') {
      if (throwUnauthorizedOnHistory) {
        throw const ApiException('login required', statusCode: 401);
      }
      return {
        'list': [
          {
            'id': 3,
            'keyword': 'noodles',
            'region': 'EU',
            'updatedAt': '2026-07-25 10:00:00',
          },
        ],
        'total': 1,
        'page': 1,
        'pageSize': 8,
        'hasMore': false,
      };
    }
    if (path == '/api/c/v1/user/browse-history') {
      return {
        'list': [
          {
            'id': 1,
            'shopId': 10001,
            'shopName': 'London Hotpot',
            'score': 4.8,
            'currency': 'GBP',
            'pricePerCapita': 35,
            'address': 'Chinatown',
            'cityName': 'London',
            'areaName': 'Soho',
            'viewCount': 2,
            'lastViewedAt': '2026-07-25 18:00',
          },
        ],
        'total': 1,
        'page': 1,
        'pageSize': 20,
        'hasMore': false,
      };
    }
    if (path == '/api/c/v1/favorites') {
      return {
        'list': [
          {
            'id': 8,
            'targetType': 1,
            'targetId': 10001,
            'target': {'id': 10001, 'name': 'London Hotpot'},
          },
        ],
        'total': 1,
        'page': 1,
        'pageSize': 50,
        'hasMore': false,
      };
    }
    return {
      'list': [
        {
          'id': 99,
          'name': 'Paris Noodles',
          'categoryName': 'Chinese',
          'score': 4.7,
          'currency': 'EUR',
          'pricePerCapita': 22,
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    this.path = path;
    return const {};
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path) async {
    deletedPaths.add(path);
    return const {};
  }
}

void main() {
  test('search and detail use public browse endpoints', () async {
    final api = FakeJsonApi();
    final repository = ApiBrowseRepository(api);

    final results = await repository.searchShops('noodles');
    expect(api.path, '/api/c/v1/search/shops');
    expect(api.query?['keyword'], 'noodles');
    expect(results.single.name, 'Paris Noodles');

    final detail = await repository.loadShopDetail(99);
    expect(api.path, '/api/c/v1/shops/99');
    expect(detail.address, 'Rue de Lyon');
  });

  test('loads hot words and search history, and supports delete paths', () async {
    final api = FakeJsonApi();
    final repository = ApiBrowseRepository(api);

    final hotWords = await repository.loadHotWords(limit: 6);
    expect(api.path, '/api/c/v1/search/hot');
    expect(api.query?['limit'], 6);
    expect(hotWords.map((item) => item.term), ['Brunch', 'Hotpot']);

    final history = await repository.loadSearchHistory(page: 1, pageSize: 8);
    expect(api.path, '/api/c/v1/search/history');
    expect(history.single.keyword, 'noodles');

    await repository.removeSearchHistoryItem(3);
    await repository.clearSearchHistory();
    expect(api.deletedPaths, [
      '/api/c/v1/search/history/3',
      '/api/c/v1/search/history',
    ]);
  });

  test('treats unauthorized search history as empty for guests', () async {
    final api = FakeJsonApi()..throwUnauthorizedOnHistory = true;
    final repository = ApiBrowseRepository(api);

    final history = await repository.loadSearchHistory();
    expect(history, isEmpty);
  });

  test('loads browse history and supports delete paths', () async {
    final api = FakeJsonApi();
    final repository = ApiBrowseRepository(api);

    final history = await repository.loadBrowseHistory(page: 1, pageSize: 20);
    expect(api.path, '/api/c/v1/user/browse-history');
    expect(history.single.shopName, 'London Hotpot');
    expect(history.single.viewCount, 2);

    await repository.removeBrowseHistoryItem(10001);
    await repository.clearBrowseHistory();
    expect(api.deletedPaths, [
      '/api/c/v1/user/browse-history/10001',
      '/api/c/v1/user/browse-history',
    ]);
  });

  test('checks and mutates shop favorite state', () async {
    final api = FakeJsonApi();
    final repository = ApiBrowseRepository(api);

    expect(await repository.isShopFavorited(10001), isTrue);
    expect(await repository.isShopFavorited(20002), isFalse);

    await repository.favoriteShop(20002);
    expect(api.path, '/api/c/v1/favorites');

    await repository.unfavoriteShop(20002);
    expect(
      api.deletedPaths,
      contains('/api/c/v1/favorites?targetType=1&targetId=20002'),
    );
  });

  test('loads search suggestions and similar shops', () async {
    final api = FakeJsonApi();
    final repository = ApiBrowseRepository(api);

    final suggestions = await repository.loadSearchSuggestions('火', limit: 6);
    expect(api.path, '/api/c/v1/search/suggest');
    expect(api.query?['kw'], '火');
    expect(suggestions.map((item) => item.term), ['火锅', '渝里火锅徐汇店']);
    expect(suggestions.first.type, 'category');

    final similar = await repository.loadSimilarShops(10001, limit: 4);
    expect(api.path, '/api/c/v1/shops/10001/similar');
    expect(api.query?['limit'], 4);
    expect(similar.single.name, '徐汇小馆');
    expect(similar.single.category, '上海 · 徐汇');
  });
}
