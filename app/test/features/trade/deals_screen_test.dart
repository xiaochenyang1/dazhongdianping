import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/trade/deals_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class DealsScreenApi implements JsonApi {
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async => {
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

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async => {
    'id': 10,
    'orderNo': 'O10',
    'amount': 29.9,
    'currency': 'EUR',
    'payStatus': 0,
  };
}

void main() {
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
}
