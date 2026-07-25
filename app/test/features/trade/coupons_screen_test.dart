import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/trade/coupons_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CouponsApi implements JsonApi {
  Map<String, Object?>? lastQuery;
  final List<String> paths = <String>[];

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    paths.add(path);
    lastQuery = query;
    if (path == '/api/c/v1/coupons') {
      return {
        'list': [
          {
            'id': 21,
            'orderId': 10,
            'code': 'CP-DEMO',
            'status': 1,
            'statusText': '待使用',
            'dealTitle': '双人晚餐套餐',
            'shopName': '柏林茶馆',
            'expireAt': '2026-12-31',
          },
        ],
        'total': 1,
      };
    }
    if (path == '/api/c/v1/coupons/CP-DEMO') {
      return {
        'id': 21,
        'orderId': 10,
        'code': 'CP-DEMO',
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
        'qrPayload': 'CP-DEMO',
        'qrImageUrl': '',
        'verifyHint': '到店后出示二维码或券码，由商户核销。',
      };
    }
    return const {};
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async =>
      const {};
}

void main() {
  testWidgets('coupons screen filters by status and opens detail', (
    tester,
  ) async {
    final api = CouponsApi();
    await tester.pumpWidget(
      MaterialApp(
        home: CouponsScreen(
          repository: TradeRepository(api),
          initialStatus: 1,
          highlightCode: 'CP-DEMO',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('coupon-highlight-banner')), findsOneWidget);
    expect(api.lastQuery?['status'], 1);
    expect(find.byKey(const Key('coupon-card-CP-DEMO')), findsOneWidget);

    await tester.tap(find.byKey(const Key('coupon-tab-3')));
    await tester.pumpAndSettle();
    expect(api.lastQuery?['status'], 3);

    await tester.tap(find.byKey(const Key('coupon-card-CP-DEMO')));
    await tester.pumpAndSettle();
    expect(find.text('券详情'), findsOneWidget);
    expect(find.byKey(const Key('coupon-detail-code')), findsOneWidget);
    expect(api.paths, contains('/api/c/v1/coupons/CP-DEMO'));
  });
}
