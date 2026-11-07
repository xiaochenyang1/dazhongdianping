import 'dart:async';
import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/campaign/campaign_repository.dart';
import 'package:dazhongdianping_app/features/campaign/seckill_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class FlashSaleApi implements JsonApi {
  int purchases = 0;
  int loads = 0;
  bool failLoad = false;
  bool failPurchase = false;
  int stock = 1;
  int? orderId;
  Completer<Map<String, dynamic>>? pending;
  final order = <String, dynamic>{
    'id': 87,
    'orderNo': 'OD87',
    'dealTitle': 'Dinner for two',
    'shopName': 'Paris restaurant',
    'quantity': 1,
    'unitPrice': 9.9,
    'amount': 9.9,
    'currency': 'EUR',
    'payStatus': 0,
    'status': 1,
    'orderSource': 'seckill',
    'campaignTitle': 'Lunch flash sale',
    'expireAt': '2026-11-06T18:15:00',
    'canPay': true,
  };
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (path == '/api/c/v1/orders/87') return order;
    loads++;
    if (failLoad) throw Exception('offline');
    return {
      'value': [
        {
          'id': 12,
          'title': 'Lunch flash sale',
          'dealId': 41,
          'seckillPrice': 9.9,
          'currency': 'EUR',
          'stock': 1,
          'sold': 1 - stock,
          'availableStock': stock,
          'orderId': orderId,
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    expect(path, '/api/c/v1/marketing/seckill/12/orders');
    expect(body, isNull);
    purchases++;
    if (failPurchase) throw const ApiException('秒杀已售罄');
    if (pending != null) return pending!.future;
    orderId = 87;
    return {'claimId': 8, 'orderId': 87, 'order': order};
  }
}

Widget wrap(FlashSaleApi api) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: SeckillScreen(repository: CampaignRepository(api)),
);

void main() {
  testWidgets(
    'creates an order at the sale price and opens the existing payment screen',
    (tester) async {
      final api = FlashSaleApi();
      await tester.pumpWidget(wrap(api));
      await tester.pumpAndSettle();
      expect(find.textContaining('15 minutes'), findsOneWidget);
      expect(find.textContaining('€'), findsOneWidget);
      await tester.tap(find.byKey(const Key('seckill-buy-12')));
      await tester.pumpAndSettle();
      expect(api.purchases, 1);
      expect(find.byKey(const Key('order-pay-button')), findsOneWidget);
      expect(find.byKey(const Key('order-source')), findsOneWidget);
      expect(find.textContaining('Flash-sale order'), findsOneWidget);
      expect(find.byKey(const Key('order-deadline')), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(api.loads, 2);
      expect(find.text('View order'), findsOneWidget);
    },
  );

  testWidgets(
    'does not submit duplicate purchases while a request is pending',
    (tester) async {
      final api = FlashSaleApi()..pending = Completer<Map<String, dynamic>>();
      await tester.pumpWidget(wrap(api));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('seckill-buy-12')));
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('seckill-buy-12')))
            .onPressed,
        isNull,
      );
      expect(api.purchases, 1);
      api.pending!.complete({'orderId': 87, 'order': api.order});
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('order-pay-button')), findsOneWidget);
    },
  );

  testWidgets('retries a failed list and keeps purchase errors visible', (
    tester,
  ) async {
    final api = FlashSaleApi()..failLoad = true;
    await tester.pumpWidget(wrap(api));
    await tester.pumpAndSettle();
    expect(find.text('No flash sales right now.'), findsNothing);
    api.failLoad = false;
    await tester.tap(find.byKey(const Key('seckill-retry')));
    await tester.pumpAndSettle();
    api.failPurchase = true;
    await tester.tap(find.byKey(const Key('seckill-buy-12')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('seckill-error')), findsOneWidget);
    expect(find.text('Sold out'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('seckill-buy-12')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'sold-out events still link to an existing order without buying again',
    (tester) async {
      final api = FlashSaleApi()
        ..stock = 0
        ..orderId = 87;
      await tester.pumpWidget(wrap(api));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View order'));
      await tester.pumpAndSettle();
      expect(api.purchases, 0);
      expect(find.byKey(const Key('order-source')), findsOneWidget);
    },
  );

  testWidgets('does not expose a payment action after the server deadline', (
    tester,
  ) async {
    final api = FlashSaleApi()..orderId = 87;
    api.order['canPay'] = false;
    await tester.pumpWidget(wrap(api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View order'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('order-pay-button')))
          .onPressed,
      isNull,
    );
    expect(find.textContaining('deadline has passed'), findsOneWidget);
  });
}
