import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/trade/order_detail_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class OrderDetailApi implements JsonApi {
  OrderDetailApi({this.failFirstCoupon = false});

  final bool failFirstCoupon;
  int couponRequests = 0;
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
    if (path.startsWith('/api/c/v1/coupons/')) {
      couponRequests++;
      if (failFirstCoupon && couponRequests == 1) {
        throw StateError('network unavailable');
      }
      return {
        'id': 21,
        'orderId': 10,
        'code': 'CP-DEMO-2026',
        'status': 1,
        'statusText': '待使用',
        'dealTitle': '双人晚餐套餐',
        'shopName': '柏林茶馆',
        'expireAt': '2026-12-31',
        'rules': '周末通用',
        'validStart': '2026-01-01',
        'validEnd': '2026-12-31',
        'verifyAt': '',
        'usable': true,
        'qrPayload': 'CP-DEMO-2026',
        'qrImageUrl': '',
        'verifyHint': '到店后出示二维码或券码，由商户核销。',
      };
    }
    return order();
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    this.path = path;
    return order(status: 2);
  }
}

void main() {
  testWidgets('coupon detail retries an initial load failure', (tester) async {
    final api = OrderDetailApi(failFirstCoupon: true);
    await tester.pumpWidget(
      MaterialApp(
        home: CouponDetailScreen(
          repository: TradeRepository(api),
          code: 'CP-DEMO-2026',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('券码详情加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('coupon-detail-retry')));
    await tester.pumpAndSettle();

    expect(api.couponRequests, 2);
    expect(find.text('CP-DEMO-2026'), findsOneWidget);
    expect(find.textContaining('由商户核销'), findsOneWidget);
  });

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
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (_) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final api = OrderDetailApi();
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
      MaterialApp(
        home: CouponDetailScreen(
          repository: TradeRepository(api),
          code: coupon.code,
          initialCoupon: coupon,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CP-DEMO-2026'), findsOneWidget);
    expect(find.textContaining('待使用'), findsOneWidget);
    expect(find.textContaining('由商户核销'), findsOneWidget);

    await tester.tap(find.byKey(const Key('copy-coupon-code')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('券码已复制'), findsOneWidget);
  });

  testWidgets('coupon fallback can retry loading the complete detail', (
    tester,
  ) async {
    final api = OrderDetailApi(failFirstCoupon: true);
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
      MaterialApp(
        home: CouponDetailScreen(
          repository: TradeRepository(api),
          code: coupon.code,
          initialCoupon: coupon,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(coupon.code), findsOneWidget);
    expect(find.textContaining('详情刷新失败'), findsOneWidget);
    expect(find.text('使用规则'), findsNothing);

    await tester.tap(find.byKey(const Key('coupon-detail-fallback-retry')));
    await tester.pumpAndSettle();

    expect(api.couponRequests, 2);
    expect(find.text('使用规则'), findsOneWidget);
    expect(find.text('周末通用'), findsOneWidget);
    expect(find.textContaining('详情刷新失败'), findsNothing);
  });
}
