import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/recommendation/recommendation_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class RecommendationFakeApi implements JsonApi {
  String? getPath;
  Map<String, Object?>? getQuery;
  String? postPath;
  Object? postBody;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    getPath = path;
    getQuery = query;
    return {
      'value': [
        {
          'id': 20001,
          'name': 'Recommended bistro',
          'categoryName': 'Cafe',
          'score': 4.8,
          'currency': 'EUR',
          'pricePerCapita': 42,
          'address': '1 Rue de Test',
          'latitude': 48.85,
          'longitude': 2.35,
          'distanceMeters': 120.0,
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postPath = path;
    postBody = body;
    return const {};
  }
}

void main() {
  test('loadFeed passes location and city and parses shops', () async {
    final api = RecommendationFakeApi();
    final repository = RecommendationRepository(api);

    final shops = await repository.loadFeed(
      latitude: 48.85,
      longitude: 2.35,
      cityId: 101,
      limit: 6,
    );

    expect(api.getPath, '/api/c/v1/recommendations/feed');
    expect(api.getQuery?['latitude'], 48.85);
    expect(api.getQuery?['longitude'], 2.35);
    expect(api.getQuery?['cityId'], 101);
    expect(api.getQuery?['limit'], 6);
    expect(shops.single.id, 20001);
    expect(shops.single.name, 'Recommended bistro');
    expect(shops.single.distanceMeters, 120.0);
  });

  test('trackBehavior posts the event payload', () async {
    final api = RecommendationFakeApi();
    final repository = RecommendationRepository(api);

    await repository.trackBehavior(
      eventType: BehaviorEventType.order,
      shopId: 20001,
    );

    expect(api.postPath, '/api/c/v1/recommendations/behaviors');
    final body = api.postBody as Map<String, dynamic>;
    expect(body['eventType'], 3);
    expect(body['shopId'], 20001);
    expect(body.containsKey('categoryId'), false);
  });
}
