import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/points/points_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class PointsRepositoryApi implements JsonApi {
  final requests = <String>[];
  final queries = <Map<String, Object?>?>[];

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    requests.add(path);
    queries.add(query);
    if (path == '/api/c/v1/points/products') {
      return {
        'list': [
          {
            'id': 11,
            'region': 'EU',
            'name': 'Coffee voucher',
            'coverImage': 'https://example.com/coffee.png',
            'description': 'A small coffee voucher',
            'pointsPrice': 120,
            'stock': 4,
            'exchangeLimitPerUser': 2,
            'exchangeCount': 6,
            'fulfillType': 2,
            'fulfillTypeText': 'Manual fulfilment',
            'status': 1,
            'sort': 3,
            'soldOut': false,
            'createdAt': '2026-08-04 09:00:00',
            'updatedAt': '2026-08-04 09:00:00',
          },
        ],
        'total': 1,
        'page': 2,
        'pageSize': 1,
        'hasMore': false,
      };
    }
    if (path == '/api/c/v1/points/products/11') {
      return {
        'id': 11,
        'region': 'EU',
        'name': 'Coffee voucher',
        'pointsPrice': 120,
        'stock': 4,
        'exchangeLimitPerUser': 2,
        'exchangeCount': 6,
        'fulfillType': 2,
        'status': 1,
        'sort': 3,
        'soldOut': false,
      };
    }
    if (path == '/api/c/v1/points/exchanges') {
      return {
        'list': [
          {
            'id': 21,
            'productId': 11,
            'productName': 'Coffee voucher',
            'pointsCost': 120,
            'quantity': 1,
            'status': 1,
            'statusText': 'Fulfilled',
            'redeemCode': 'PTCOFFEE1',
            'remark': 'Ready',
            'fulfilledAt': '2026-08-04 10:00:00',
            'createdAt': '2026-08-04 09:00:00',
          },
        ],
        'total': 1,
        'page': 1,
        'pageSize': 12,
        'hasMore': false,
      };
    }
    return const {};
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    requests.add(path);
    if (path == '/api/c/v1/points/products/11/exchange') {
      return {
        'id': 22,
        'productId': 11,
        'productName': 'Coffee voucher',
        'pointsCost': 120,
        'quantity': 1,
        'status': 1,
        'statusText': 'Fulfilled',
        'redeemCode': 'PTCOFFEE2',
        'remark': '',
        'fulfilledAt': '2026-08-04 10:00:00',
        'createdAt': '2026-08-04 10:00:00',
      };
    }
    return const {};
  }
}

void main() {
  test(
    'points repository uses exact endpoints and parses paginated payloads',
    () async {
      final api = PointsRepositoryApi();
      final repository = PointsMallRepository(api);

      final products = await repository.loadProducts(page: 2, pageSize: 1);
      expect(api.requests.single, '/api/c/v1/points/products');
      expect(api.queries.single, {'page': 2, 'pageSize': 1});
      expect(products.items.single.id, 11);
      expect(products.items.single.fulfillType, 2);
      expect(products.items.single.unlimitedPerUser, isFalse);
      expect(products.total, 1);
      expect(products.page, 2);
      expect(products.hasMore, isFalse);

      final detail = await repository.loadProduct(11);
      expect(api.requests.last, '/api/c/v1/points/products/11');
      expect(detail.name, 'Coffee voucher');

      final exchanged = await repository.exchange(11);
      expect(api.requests.last, '/api/c/v1/points/products/11/exchange');
      expect(exchanged.redeemCode, 'PTCOFFEE2');
      expect(exchanged.fulfilled, isTrue);

      final history = await repository.loadExchanges(page: 1);
      expect(api.requests.last, '/api/c/v1/points/exchanges');
      expect(history.items.single.cancelled, isFalse);
      expect(history.items.single.redeemCode, 'PTCOFFEE1');
    },
  );
}
