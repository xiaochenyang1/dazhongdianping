import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/trade/deals_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class DealsScreenApi implements JsonApi {
  DealsScreenApi({this.failFirst = false, this.failPayment = false});

  final bool failFirst;
  final bool failPayment;
  int dealRequests = 0;
  int createOrderRequests = 0;
  int orderDetailRequests = 0;
  int paymentRequests = 0;
  Completer<void>? retryGate;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (path == '/api/c/v1/orders/10') {
      orderDetailRequests++;
      return {
        'id': 10,
        'orderNo': 'O10',
        'dealTitle': 'Dinner Set',
        'shopName': 'EU Shop',
        'quantity': 1,
        'unitPrice': 29.9,
        'amount': 29.9,
        'currency': 'EUR',
        'payStatus': 0,
        'payStatusText': '待支付',
        'status': 1,
        'coupons': const [],
      };
    }
    if (path != '/api/c/v1/shops/2/deals') {
      throw StateError('unexpected GET $path');
    }
    dealRequests++;
    if (failFirst && dealRequests == 1) {
      throw StateError('network unavailable');
    }
    if (dealRequests > 1) await retryGate?.future;
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
    if (path == '/api/c/v1/orders/10/pay') {
      paymentRequests++;
      if (failPayment) throw StateError('payment gateway unavailable');
      return {
        'channel': 'stripe',
        'orderNo': 'O10',
        'amount': 29.9,
        'currency': 'EUR',
      };
    }
    if (path != '/api/c/v1/orders') {
      throw StateError('unexpected POST $path');
    }
    createOrderRequests++;
    return {
      'id': 10,
      'orderNo': 'O10',
      'dealTitle': 'Dinner Set',
      'shopName': 'EU Shop',
      'quantity': 1,
      'unitPrice': 29.9,
      'amount': 29.9,
      'currency': 'EUR',
      'payStatus': 0,
      'payStatusText': '待支付',
      'status': 1,
      'coupons': const [],
    };
  }
}

void main() {
  testWidgets('deals screen retries an initial load failure', (tester) async {
    final api = DealsScreenApi(failFirst: true);
    await tester.pumpWidget(
      MaterialApp(
        home: DealsScreen(
          repository: TradeRepository(api),
          shopId: 2,
          thirdPartyConfig: const ThirdPartyConfig(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('团购加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('deals-retry')));
    await tester.pumpAndSettle();

    expect(api.dealRequests, 2);
    expect(find.text('Dinner Set'), findsOneWidget);
  });

  testWidgets('deals screen guards duplicate retries', (tester) async {
    final gate = Completer<void>();
    final api = DealsScreenApi(failFirst: true)..retryGate = gate;
    await tester.pumpWidget(
      MaterialApp(
        home: DealsScreen(
          repository: TradeRepository(api),
          shopId: 2,
          thirdPartyConfig: const ThirdPartyConfig(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('deals-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(api.dealRequests, 2);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Dinner Set'), findsOneWidget);
  });

  testWidgets(
    'deal purchase blocks real payment when provider is unconfigured',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DealsScreen(
            repository: TradeRepository(DealsScreenApi()),
            shopId: 2,
            thirdPartyConfig: const ThirdPartyConfig(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dinner Set'), findsOneWidget);
      await tester.tap(find.text('购买'));
      await tester.pumpAndSettle();
      expect(find.textContaining('真实支付未配置'), findsOneWidget);
    },
  );

  testWidgets('payment failure retries from the created order detail', (
    tester,
  ) async {
    final api = DealsScreenApi(failPayment: true);
    await tester.pumpWidget(
      MaterialApp(
        home: DealsScreen(
          repository: TradeRepository(api),
          shopId: 2,
          thirdPartyConfig: const ThirdPartyConfig(
            stripePublishableKey: 'pk_test_configured',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('deal-action-5')));
    await tester.pumpAndSettle();

    expect(api.createOrderRequests, 1);
    expect(api.paymentRequests, 0);
    expect(api.orderDetailRequests, 0);
    expect(find.text('订单详情'), findsOneWidget);
    expect(find.text('EU Shop · 订单 O10'), findsOneWidget);

    await tester.tap(find.byKey(const Key('order-pay-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('支付发起失败'), findsOneWidget);
    expect(find.textContaining('下单失败'), findsNothing);
    expect(api.createOrderRequests, 1);
    expect(api.paymentRequests, 1);

    await tester.tap(find.byKey(const Key('order-pay-button')));
    await tester.pumpAndSettle();

    expect(api.createOrderRequests, 1);
    expect(api.paymentRequests, 2);
  });
}
