import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/trade/orders_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class OrdersApi implements JsonApi {
  Map<String, Object?>? lastQuery;
  final List<String> paths = <String>[];

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    paths.add(path);
    lastQuery = query;
    if (path == '/api/c/v1/orders') {
      return {
        'list': [
          {
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
          },
        ],
        'total': 1,
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
