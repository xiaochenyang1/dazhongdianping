import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/trade/order_detail_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class OrderDetailApi implements JsonApi {
  OrderDetailApi({
    this.failFirstCoupon = false,
    this.failFirstOrder = false,
    this.paid = false,
  });

  final bool failFirstCoupon;
  final bool failFirstOrder;
  final bool paid;
  int couponRequests = 0;
  Completer<void>? couponGate;
  String? path;
  Object? body;
  bool failNextRefund = false;
  int refundRequests = 0;
  Completer<void>? paymentGate;
  int paymentRequests = 0;
  int orderRequests = 0;
  Completer<void>? orderGate;
  Object? couponError;
  Object? paymentError;
  Object? refundError;
  Object? orderError;

  Map<String, dynamic> order({int status = 1, bool refunded = false}) => {
    'id': 10,
    'orderNo': 'OD-10',
    'dealTitle': '双人晚餐套餐',
    'shopName': '柏林茶馆',
    'quantity': 1,
    'unitPrice': 29.9,
    'amount': 29.9,
    'currency': 'EUR',
    'payStatus': paid ? 1 : 0,
    'payStatusText': paid ? '已支付' : '待支付',
    'status': status,
    'coupons': const [],
    if (refunded)
      'refund': {
        'id': 91,
        'status': 0,
        'statusText': '待审核',
        'reason': (body as Map<String, Object?>)['reason'],
      },
  };

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    this.path = path;
    if (path.startsWith('/api/c/v1/coupons/')) {
      couponRequests++;
      if (couponError != null) {
        final error = couponError!;
        couponError = null;
        throw error;
      }
      if (failFirstCoupon && couponRequests == 1) {
        throw StateError('network unavailable');
      }
      await couponGate?.future;
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
    orderRequests += 1;
    await orderGate?.future;
    if (orderError != null) {
      final error = orderError!;
      orderError = null;
      throw error;
    }
    if (failFirstOrder && orderRequests == 1) {
      throw StateError('order unavailable');
    }
    return order();
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    this.path = path;
    this.body = body;
    if (path.endsWith('/pay')) {
      paymentRequests += 1;
      await paymentGate?.future;
      if (paymentError != null) {
        final error = paymentError!;
        paymentError = null;
        throw error;
      }
      return {
        'channel': 'stripe',
        'orderNo': 'OD-10',
        'amount': 29.9,
        'currency': 'EUR',
      };
    }
    if (path.endsWith('/refund')) {
      refundRequests += 1;
      if (refundError != null) {
        final error = refundError!;
        refundError = null;
        throw error;
      }
      if (failNextRefund) {
        failNextRefund = false;
        throw StateError('refund unavailable');
      }
      return order(refunded: true);
    }
    return order(status: 2);
  }
}

Widget localizedApp({
  required Widget home,
  Locale locale = const Locale('zh', 'CN'),
}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: home,
  );
}

void main() {
  testWidgets('order detail localizes trade status labels in English', (
    tester,
  ) async {
    final api = OrderDetailApi(paid: true);
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: OrderDetailScreen(repository: TradeRepository(api), orderId: 10),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Paid'), findsAtLeastNWidgets(1));

    await tester.tap(find.byKey(const Key('order-refund-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('order-refund-reason')),
      'Need to change the plan',
    );
    await tester.tap(
      find.text(AppLocalizations.forTag('en').submitApplication),
    );
    await tester.pumpAndSettle();

    expect(find.text('Refund: Pending review'), findsOneWidget);
    expect(find.textContaining('待审核'), findsNothing);
  });

  testWidgets('coupon detail retries an initial load failure', (tester) async {
    final api = OrderDetailApi(failFirstCoupon: true);
    await tester.pumpWidget(
      localizedApp(
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

  testWidgets('coupon detail localizes load errors in English', (tester) async {
    final api = OrderDetailApi()..couponError = const ApiException('券码不存在');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: CouponDetailScreen(
          repository: TradeRepository(api),
          code: 'CP-DEMO-2026',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not load coupon details: This coupon could not be found.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('券码不存在'), findsNothing);
  });

  testWidgets('coupon detail guards duplicate retries', (tester) async {
    final gate = Completer<void>();
    final api = OrderDetailApi(failFirstCoupon: true)..couponGate = gate;
    await tester.pumpWidget(
      localizedApp(
        home: CouponDetailScreen(
          repository: TradeRepository(api),
          code: 'CP-DEMO-2026',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('coupon-detail-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(api.couponRequests, 2);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.couponRequests, 2);
    expect(find.text('CP-DEMO-2026'), findsOneWidget);
  });

  testWidgets('order detail shows honest payment state and cancels order', (
    tester,
  ) async {
    final api = OrderDetailApi();
    await tester.pumpWidget(
      localizedApp(
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

  testWidgets('order detail localizes payment errors in English', (
    tester,
  ) async {
    final api = OrderDetailApi()..paymentError = const ApiException('支付渠道尚未配置');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: OrderDetailScreen(
          repository: TradeRepository(api),
          orderId: 10,
          thirdPartyConfig: const ThirdPartyConfig(
            stripePublishableKey: 'pk_test_widget',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('order-pay-button')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not start payment: Payment services are not configured yet.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('支付渠道尚未配置'), findsNothing);
  });

  testWidgets('order detail guards duplicate load retries', (tester) async {
    final gate = Completer<void>();
    final api = OrderDetailApi(failFirstOrder: true);
    await tester.pumpWidget(
      localizedApp(
        home: OrderDetailScreen(repository: TradeRepository(api), orderId: 10),
      ),
    );
    await tester.pumpAndSettle();
    api.orderGate = gate;

    final retry = find.byKey(const Key('order-detail-retry'));
    await tester.tap(retry);
    await tester.tap(retry);
    await tester.pump();
    expect(api.orderRequests, 2);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.orderRequests, 2);
    expect(find.text('双人晚餐套餐'), findsOneWidget);
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
      localizedApp(
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

  testWidgets('coupon detail localizes status labels in English', (
    tester,
  ) async {
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
      localizedApp(
        locale: const Locale('en'),
        home: CouponDetailScreen(
          repository: TradeRepository(api),
          code: coupon.code,
          initialCoupon: coupon,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coupon details'), findsOneWidget);
    expect(find.textContaining('Available'), findsOneWidget);
    expect(find.textContaining('待使用'), findsNothing);
  });

  testWidgets('coupon detail guards duplicate clipboard writes', (
    tester,
  ) async {
    final gate = Completer<void>();
    var clipboardWrites = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardWrites += 1;
          await gate.future;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final api = OrderDetailApi();
    await tester.pumpWidget(
      localizedApp(
        home: CouponDetailScreen(
          repository: TradeRepository(api),
          code: 'CP-DEMO-2026',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final copy = find.byKey(const Key('copy-coupon-code'));
    await tester.tap(copy);
    await tester.tap(copy);
    await tester.pump();
    expect(clipboardWrites, 1);
    expect(find.text('复制中...'), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(clipboardWrites, 1);
    expect(find.text('券码已复制'), findsOneWidget);
  });

  testWidgets('order detail preserves a failed refund reason for retry', (
    tester,
  ) async {
    final api = OrderDetailApi(paid: true)..failNextRefund = true;
    await tester.pumpWidget(
      localizedApp(
        home: OrderDetailScreen(repository: TradeRepository(api), orderId: 10),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('order-refund-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('order-refund-reason')),
      '需要保留的退款原因',
    );
    await tester.tap(find.text('提交申请'));
    await tester.pumpAndSettle();
    expect(find.textContaining('操作失败'), findsOneWidget);

    ScaffoldMessenger.of(
      tester.element(find.byType(OrderDetailScreen)),
    ).clearSnackBars();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('order-refund-button')));
    await tester.pumpAndSettle();
    expect(find.text('需要保留的退款原因'), findsOneWidget);
    await tester.tap(find.text('提交申请'));
    await tester.pumpAndSettle();

    expect(api.refundRequests, 2);
    expect(api.body, {'reason': '需要保留的退款原因'});
    expect(find.text('退款：待审核'), findsOneWidget);
  });

  testWidgets('order detail localizes refund errors in English', (
    tester,
  ) async {
    final api = OrderDetailApi(paid: true)
      ..refundError = const ApiException('订单已有退款申请');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: OrderDetailScreen(repository: TradeRepository(api), orderId: 10),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('order-refund-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('order-refund-reason')),
      'Duplicate refund request',
    );
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not complete the action: A refund request already exists for this order.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('订单已有退款申请'), findsNothing);
  });

  testWidgets('order detail blocks duplicate payment requests', (tester) async {
    final gate = Completer<void>();
    final api = OrderDetailApi()..paymentGate = gate;
    await tester.pumpWidget(
      localizedApp(
        home: OrderDetailScreen(
          repository: TradeRepository(api),
          orderId: 10,
          thirdPartyConfig: const ThirdPartyConfig(
            stripePublishableKey: 'pk_test_widget',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('order-pay-button')));
    await tester.tap(find.byKey(const Key('order-pay-button')));
    expect(api.paymentRequests, 1);

    gate.complete();
    await tester.pumpAndSettle();
    expect(api.paymentRequests, 1);
    expect(find.textContaining('已创建 stripe 支付请求'), findsOneWidget);
  });

  testWidgets('order detail guards duplicate cancel dialogs', (tester) async {
    final api = OrderDetailApi();
    await tester.pumpWidget(
      localizedApp(
        home: OrderDetailScreen(repository: TradeRepository(api), orderId: 10),
      ),
    );
    await tester.pumpAndSettle();

    final cancel = find.byKey(const Key('order-cancel-button'));
    final cancelAction = tester.widget<OutlinedButton>(cancel).onPressed!;
    cancelAction();
    cancelAction();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('取消订单'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('先不取消'));
    await tester.pumpAndSettle();
    expect(api.path, '/api/c/v1/orders/10');
  });

  testWidgets('order detail guards duplicate refund dialogs', (tester) async {
    final api = OrderDetailApi(paid: true);
    await tester.pumpWidget(
      localizedApp(
        home: OrderDetailScreen(repository: TradeRepository(api), orderId: 10),
      ),
    );
    await tester.pumpAndSettle();

    final refund = find.byKey(const Key('order-refund-button'));
    final refundAction = tester.widget<OutlinedButton>(refund).onPressed!;
    refundAction();
    refundAction();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('申请退款'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(api.refundRequests, 0);
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
      localizedApp(
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

  testWidgets('coupon fallback localizes English refresh errors', (
    tester,
  ) async {
    final api = OrderDetailApi(failFirstCoupon: true);
    const coupon = Coupon(
      id: 21,
      orderId: 10,
      code: 'CP-DEMO-2026',
      status: 1,
      statusText: '待使用',
      dealTitle: 'Dinner for two',
      shopName: 'Berlin Tea House',
      expireAt: '2026-12-31',
    );
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: CouponDetailScreen(
          repository: TradeRepository(api),
          code: coupon.code,
          initialCoupon: coupon,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coupon details'), findsOneWidget);
    expect(
      find.textContaining('Could not refresh details: network unavailable'),
      findsOneWidget,
    );
    expect(find.text('Reload full details'), findsOneWidget);
  });
}
