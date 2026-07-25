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
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) =>
      throw UnimplementedError();

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
}
