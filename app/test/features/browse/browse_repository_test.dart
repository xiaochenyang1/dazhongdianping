import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeJsonApi implements JsonApi {
  String? path;
  Map<String, Object?>? query;

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
}
