import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/trade/order_detail_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class OrderDetailApi implements JsonApi {
  String? path;

  Map<String, dynamic> order({int status = 1}) => {
    'id': 10,
    'orderNo': 'OD-10',
    'dealTitle': '双人晚餐套餐',
    'shopName': '柏林茶馆',
    'quantity': 1,
    'unitPrice': 29.9,
    'amount': 29.9,
    'currency': 'EUR',
    'payStatus': 0,
    'payStatusText': '待支付',
    'status': status,
    'coupons': const [],
  };

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    this.path = path;
    return order();
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    this.path = path;
    return order(status: 2);
  }
}

void main() {
  testWidgets('order detail shows honest payment state and cancels order', (
    tester,
  ) async {
    final api = OrderDetailApi();
    await tester.pumpWidget(
      MaterialApp(
        home: OrderDetailScreen(
          repository: TradeRepository(api),
          orderId: 10,
          thirdPartyConfig: const ThirdPartyConfig(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('双人晚餐套餐'), findsOneWidget);
    expect(find.textContaining('真实支付未配置'), findsOneWidget);
    expect(find.text('取消订单'), findsOneWidget);

    await tester.tap(find.text('取消订单'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认取消'));
    await tester.pumpAndSettle();

    expect(api.path, '/api/c/v1/orders/10/cancel');
    expect(find.text('订单已取消'), findsOneWidget);
  });

  testWidgets('coupon detail shows code, status and merchant boundary', (
    tester,
  ) async {
    const coupon = Coupon(
      id: 21,
      orderId: 10,
      code: 'CP-DEMO-2026',
      status: 1,
      statusText: '待使用',
      dealTitle: '双人晚餐套餐',
      shopName: '柏林茶馆',
      expireAt: '2026-12-31',
    );
    await tester.pumpWidget(
      const MaterialApp(home: CouponDetailScreen(coupon: coupon)),
    );

    expect(find.text('CP-DEMO-2026'), findsOneWidget);
    expect(find.text('待使用'), findsOneWidget);
    expect(find.textContaining('由商户核销'), findsOneWidget);
  });
}
