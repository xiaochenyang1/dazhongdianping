import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/trade/orders_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class OrdersApi implements JsonApi {
  OrdersApi({this.paginated = false});

  final bool paginated;
  Map<String, Object?>? lastQuery;
  final List<String> paths = <String>[];
  final List<int> requestedPages = <int>[];

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    paths.add(path);
    lastQuery = query;
    if (path == '/api/c/v1/orders') {
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

void main() {
  testWidgets('orders screen loads later filtered pages', (tester) async {
    final api = OrdersApi(paginated: true);
    await tester.pumpWidget(
      MaterialApp(
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
      MaterialApp(
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
}
