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
    if (path == '/api/c/v1/deals/5') {
      return {
        'id': 5,
        'shopId': 2,
        'shopName': 'EU Shop',
        'title': 'Dinner Set',
        'coverImage': 'https://example.com/deal.jpg',
        'price': 29.9,
        'originalPrice': 39.9,
        'currency': 'EUR',
        'stock': 10,
        'soldCount': 4,
        'rules': 'Booking required',
        'validStart': '2026-07-01',
        'validEnd': '2026-12-31',
        'items': [
          {
            'id': 51,
            'dealId': 5,
            'name': 'Dinner for two',
            'quantity': 1,
            'price': 29.9,
            'sort': 1,
          },
        ],
      };
    }
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
  Map<String, Object?>? query;

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
    this.query = query;
    if (path == '/api/c/v1/orders') {
      return {
        'list': [order],
        'total': 1,
      };
    }
    if (path == '/api/c/v1/coupons') {
      return {
        'list': [coupon],
        'total': 1,
      };
    }
    if (path == '/api/c/v1/coupons/CP-DEMO') {
      return {
        ...coupon,
        'rules': '周末通用',
        'validStart': '2026-01-01',
        'validEnd': '2026-12-31',
        'verifyAt': '',
        'usable': true,
        'qrPayload': 'CP-DEMO',
        'qrImageUrl': 'https://example.com/qr.png',
        'verifyHint': '到店后出示二维码或券码，由商户核销。',
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

    final detail = await repository.loadDeal(5);
    expect(api.path, '/api/c/v1/deals/5');
    expect(detail.rules, 'Booking required');
    expect(detail.items.single.name, 'Dinner for two');
    expect(detail.coverImage, 'https://example.com/deal.jpg');

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

    final coupons = await repository.loadCoupons(status: 1);
    expect(api.path, '/api/c/v1/coupons');
    expect(api.query?['status'], 1);
    expect(coupons.single.expireAt, '2026-12-31');

    final couponPage = await repository.loadCouponPage(
      status: 1,
      page: 2,
      pageSize: 12,
    );
    expect(api.query, {'page': 2, 'pageSize': 12, 'status': 1});
    expect(couponPage.page, 2);
    expect(couponPage.pageSize, 12);
    expect(couponPage.total, 1);
    expect(couponPage.hasMore, isFalse);

    final orders = await repository.loadOrders(payStatus: 1);
    expect(api.path, '/api/c/v1/orders');
    expect(api.query?['payStatus'], 1);
    expect(orders.single.orderNo, 'O10');

    final orderPage = await repository.loadOrderPage(
      payStatus: 1,
      page: 2,
      pageSize: 12,
    );
    expect(api.query, {'page': 2, 'pageSize': 12, 'payStatus': 1});
    expect(orderPage.page, 2);
    expect(orderPage.pageSize, 12);
    expect(orderPage.total, 1);
    expect(orderPage.hasMore, isFalse);

    final detail = await repository.loadCouponDetail('CP-DEMO');
    expect(api.path, '/api/c/v1/coupons/CP-DEMO');
    expect(detail.usable, isTrue);
    expect(detail.qrImageUrl, 'https://example.com/qr.png');
    expect(detail.rules, '周末通用');
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
