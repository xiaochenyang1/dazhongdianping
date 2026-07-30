import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/trade/orders_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class OrdersApi implements JsonApi {
  OrdersApi({this.paginated = false, this.failFirst = false});

  final bool paginated;
  final bool failFirst;
  int orderListRequests = 0;
  Map<String, Object?>? lastQuery;
  final List<String> paths = <String>[];
  final List<int> requestedPages = <int>[];
  Completer<void>? retryGate;
  Completer<void>? detailGate;
  int orderDetailRequests = 0;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    paths.add(path);
    lastQuery = query;
    if (path == '/api/c/v1/orders') {
      orderListRequests++;
      if (failFirst && orderListRequests == 1) {
        throw StateError('network unavailable');
      }
      if (orderListRequests > 1) await retryGate?.future;
      final page = query?['page'] as int? ?? 1;
      requestedPages.add(page);
      return {
        'list': [
          {
            'id': paginated ? 9 + page : 10,
            'orderNo': 'OD-${paginated ? 9 + page : 10}',
            'dealTitle': page == 1 ? '双人晚餐套餐' : '更早的订单',
            'shopName': '柏林茶馆',
            'quantity': 1,
            'unitPrice': 29.9,
            'amount': 29.9,
            'currency': 'EUR',
            'payStatus': 0,
            'payStatusText': '待支付',
            'status': 1,
            'coupons': const [],
          },
        ],
        'total': paginated ? 2 : 1,
      };
    }
    if (path == '/api/c/v1/orders/10') {
      orderDetailRequests++;
      await detailGate?.future;
      return {
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
        'status': 1,
        'coupons': const [],
      };
    }
    return const {};
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      const {};
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
  testWidgets('orders screen switches English chrome', (tester) async {
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: OrdersScreen(repository: TradeRepository(OrdersApi())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Unpaid'), findsOneWidget);
    expect(find.textContaining('柏林茶馆 · Unpaid · EUR 29.9'), findsOneWidget);
    expect(find.textContaining('待支付'), findsNothing);
  });

  testWidgets('orders screen retries an initial load failure', (tester) async {
    final api = OrdersApi(failFirst: true);
    await tester.pumpWidget(
      localizedApp(home: OrdersScreen(repository: TradeRepository(api))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('订单加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('orders-retry')));
    await tester.pumpAndSettle();

    expect(api.orderListRequests, 2);
    expect(find.byKey(const Key('order-card-10')), findsOneWidget);
  });

  testWidgets('orders screen guards duplicate retries', (tester) async {
    final gate = Completer<void>();
    final api = OrdersApi(failFirst: true)..retryGate = gate;
    await tester.pumpWidget(
      localizedApp(home: OrdersScreen(repository: TradeRepository(api))),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('orders-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(api.orderListRequests, 2);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('order-card-10')), findsOneWidget);
  });

  testWidgets('orders screen loads later filtered pages', (tester) async {
    final api = OrdersApi(paginated: true);
    await tester.pumpWidget(
      localizedApp(
        home: OrdersScreen(
          repository: TradeRepository(api),
          initialPayStatus: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('order-card-10')), findsOneWidget);
    expect(find.byKey(const Key('orders-load-more')), findsOneWidget);
    await tester.tap(find.byKey(const Key('orders-load-more')));
    await tester.pumpAndSettle();

    expect(api.requestedPages, [1, 2]);
    expect(api.lastQuery?['payStatus'], 1);
    expect(find.byKey(const Key('order-card-11')), findsOneWidget);
    expect(find.byKey(const Key('orders-load-more')), findsNothing);
  });

  testWidgets('orders screen filters by pay status and opens detail', (
    tester,
  ) async {
    final api = OrdersApi();
    await tester.pumpWidget(
      localizedApp(
        home: OrdersScreen(
          repository: TradeRepository(api),
          initialPayStatus: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.lastQuery?['payStatus'], 0);
    expect(find.byKey(const Key('order-card-10')), findsOneWidget);

    await tester.tap(find.byKey(const Key('order-tab-1')));
    await tester.pumpAndSettle();
    expect(api.lastQuery?['payStatus'], 1);

    await tester.tap(find.byKey(const Key('order-card-10')));
    await tester.pumpAndSettle();
    expect(find.text('订单详情'), findsOneWidget);
    expect(api.paths, contains('/api/c/v1/orders/10'));
  });

  testWidgets('orders screen guards duplicate detail navigation', (
    tester,
  ) async {
    final gate = Completer<void>();
    final api = OrdersApi()..detailGate = gate;
    await tester.pumpWidget(
      localizedApp(home: OrdersScreen(repository: TradeRepository(api))),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const Key('order-card-10'));
    await tester.tap(card);
    await tester.tap(card, warnIfMissed: false);
    await tester.pump();

    expect(api.orderDetailRequests, 1);

    gate.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();

    expect(api.orderDetailRequests, 1);
    expect(api.orderListRequests, 2);
  });
}
