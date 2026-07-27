import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/trade/coupons_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CouponsApi implements JsonApi {
  CouponsApi({this.paginated = false, this.failFirst = false});

  final bool paginated;
  final bool failFirst;
  int couponListRequests = 0;
  Map<String, Object?>? lastQuery;
  final List<String> paths = <String>[];
  final List<int> requestedPages = <int>[];
  Completer<void>? retryGate;
  Completer<void>? detailGate;
  int couponDetailRequests = 0;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    paths.add(path);
    lastQuery = query;
    if (path == '/api/c/v1/coupons') {
      couponListRequests++;
      if (failFirst && couponListRequests == 1) {
        throw StateError('network unavailable');
      }
      if (couponListRequests > 1) await retryGate?.future;
      final page = query?['page'] as int? ?? 1;
      requestedPages.add(page);
      return {
        'list': [
          {
            'id': paginated ? 20 + page : 21,
            'orderId': 10,
            'code': paginated ? 'CP-PAGE-$page' : 'CP-DEMO',
            'status': 1,
            'statusText': '待使用',
            'dealTitle': page == 1 ? '双人晚餐套餐' : '更早的券',
            'shopName': '柏林茶馆',
            'expireAt': '2026-12-31',
          },
        ],
        'total': paginated ? 2 : 1,
      };
    }
    if (path == '/api/c/v1/coupons/CP-DEMO') {
      couponDetailRequests++;
      await detailGate?.future;
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
  testWidgets('coupons screen retries an initial load failure', (tester) async {
    final api = CouponsApi(failFirst: true);
    await tester.pumpWidget(
      MaterialApp(home: CouponsScreen(repository: TradeRepository(api))),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('券码加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('coupons-retry')));
    await tester.pumpAndSettle();

    expect(api.couponListRequests, 2);
    expect(find.byKey(const Key('coupon-card-CP-DEMO')), findsOneWidget);
  });

  testWidgets('coupons screen guards duplicate retries', (tester) async {
    final gate = Completer<void>();
    final api = CouponsApi(failFirst: true)..retryGate = gate;
    await tester.pumpWidget(
      MaterialApp(home: CouponsScreen(repository: TradeRepository(api))),
    );
    await tester.pumpAndSettle();

    final retry = find.byKey(const Key('coupons-retry'));
    await tester.tap(retry);
    await tester.tap(retry, warnIfMissed: false);
    await tester.pump();
    expect(api.couponListRequests, 2);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('coupon-card-CP-DEMO')), findsOneWidget);
  });

  testWidgets('coupons screen loads later filtered pages', (tester) async {
    final api = CouponsApi(paginated: true);
    await tester.pumpWidget(
      MaterialApp(
        home: CouponsScreen(repository: TradeRepository(api), initialStatus: 1),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('coupon-card-CP-PAGE-1')), findsOneWidget);
    expect(find.byKey(const Key('coupons-load-more')), findsOneWidget);
    await tester.tap(find.byKey(const Key('coupons-load-more')));
    await tester.pumpAndSettle();

    expect(api.requestedPages, [1, 2]);
    expect(api.lastQuery?['status'], 1);
    expect(find.byKey(const Key('coupon-card-CP-PAGE-2')), findsOneWidget);
    expect(find.byKey(const Key('coupons-load-more')), findsNothing);
  });

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

  testWidgets('coupons screen guards duplicate detail navigation', (
    tester,
  ) async {
    final gate = Completer<void>();
    final api = CouponsApi()..detailGate = gate;
    await tester.pumpWidget(
      MaterialApp(home: CouponsScreen(repository: TradeRepository(api))),
    );
    await tester.pumpAndSettle();

    final card = find.byKey(const Key('coupon-card-CP-DEMO'));
    await tester.tap(card);
    await tester.tap(card, warnIfMissed: false);
    await tester.pump();

    expect(api.couponDetailRequests, 1);

    gate.complete();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(api.couponDetailRequests, 1);
    expect(api.couponListRequests, 1);
  });
}
