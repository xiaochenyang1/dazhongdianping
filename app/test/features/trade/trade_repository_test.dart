import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class TradeFakeApi implements JsonApi {
  String? path;
  Object? body;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    this.path = path;
    return {
      'value': [
        {
          'id': 5,
          'shopId': 2,
          'shopName': 'EU Shop',
          'title': 'Dinner Set',
          'price': 29.9,
          'originalPrice': 39.9,
          'currency': 'EUR',
          'stock': 10,
          'soldCount': 4,
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    this.path = path;
    this.body = body;
    return {
      'id': 10,
      'orderNo': 'O10',
      'amount': 29.9,
      'currency': 'EUR',
      'payStatus': 0,
    };
  }
}

class TradeManagementFakeApi implements JsonApi {
  String? path;
  Object? body;

  Map<String, dynamic> get order => {
    'id': 10,
    'orderNo': 'O10',
    'dealId': 5,
    'dealTitle': 'Dinner Set',
    'shopId': 2,
    'shopName': 'EU Shop',
    'coverImage': '',
    'quantity': 1,
    'unitPrice': 29.9,
    'amount': 29.9,
    'currency': 'EUR',
    'payStatus': 1,
    'payStatusText': '已支付',
    'status': 1,
    'coupons': [coupon],
  };

  Map<String, dynamic> get coupon => {
    'id': 21,
    'orderId': 10,
    'code': 'CP-DEMO',
    'status': 1,
    'statusText': '待使用',
    'dealId': 5,
    'dealTitle': 'Dinner Set',
    'shopId': 2,
    'shopName': 'EU Shop',
    'coverImage': '',
    'expireAt': '2026-12-31',
  };

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    this.path = path;
    if (path == '/api/c/v1/coupons') {
      return {
        'list': [coupon],
        'total': 1,
      };
    }
    return order;
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    this.path = path;
    this.body = body;
    return order;
  }
}

void main() {
  test('trade repository lists deals and creates order', () async {
    final api = TradeFakeApi();
    final repository = TradeRepository(api);
    final deals = await repository.loadShopDeals(2);
    expect(api.path, '/api/c/v1/shops/2/deals');
    expect(deals.single.title, 'Dinner Set');

    final order = await repository.createOrder(dealId: 5, quantity: 1);
    expect(api.path, '/api/c/v1/orders');
    expect((api.body as Map)['dealId'], 5);
    expect(order.orderNo, 'O10');
  });

  test('trade repository loads order details and coupons', () async {
    final api = TradeManagementFakeApi();
    final repository = TradeRepository(api);

    final order = await repository.loadOrder(10);
    expect(api.path, '/api/c/v1/orders/10');
    expect(order.dealTitle, 'Dinner Set');
    expect(order.payStatusText, '已支付');
    expect(order.coupons.single.code, 'CP-DEMO');

    final coupons = await repository.loadCoupons();
    expect(api.path, '/api/c/v1/coupons');
    expect(coupons.single.expireAt, '2026-12-31');
  });

  test('trade repository cancels and refunds an order', () async {
    final api = TradeManagementFakeApi();
    final repository = TradeRepository(api);

    await repository.cancelOrder(10);
    expect(api.path, '/api/c/v1/orders/10/cancel');

    await repository.refundOrder(10, reason: '行程有变');
    expect(api.path, '/api/c/v1/orders/10/refund');
    expect(api.body, {'reason': '行程有变'});
  });
}
