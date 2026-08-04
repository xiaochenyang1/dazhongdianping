import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/points/points_mall_screen.dart';
import 'package:dazhongdianping_app/features/points/points_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class PointsScreenApi implements JsonApi {
  bool paginatedProducts = false;
  bool failNextProductsLoad = false;
  Object? exchangeError;
  Object? exchangesError;
  Completer<void>? exchangeGate;
  Completer<void>? exchangesGate;
  final productPages = <int>[];
  final exchangePages = <int>[];
  int exchangeRequests = 0;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (path == '/api/c/v1/points/products') {
      final page = query?['page'] as int? ?? 1;
      productPages.add(page);
      if (failNextProductsLoad) {
        failNextProductsLoad = false;
        throw const ApiException('products unavailable');
      }
      return _products(page);
    }
    if (path == '/api/c/v1/points/exchanges') {
      final page = query?['page'] as int? ?? 1;
      exchangePages.add(page);
      await exchangesGate?.future;
      if (exchangesError != null) {
        final error = exchangesError!;
        exchangesError = null;
        throw error;
      }
      return _exchanges(page);
    }
    return const {};
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    expect(path, '/api/c/v1/points/products/1/exchange');
    exchangeRequests++;
    await exchangeGate?.future;
    if (exchangeError != null) throw exchangeError!;
    return {
      'id': 31,
      'productId': 1,
      'productName': 'Coffee voucher',
      'pointsCost': 100,
      'quantity': 1,
      'status': 1,
      'statusText': 'Fulfilled',
      'redeemCode': 'PTCOFFEE31',
      'remark': '',
      'fulfilledAt': '2026-08-04 10:00:00',
      'createdAt': '2026-08-04 10:00:00',
    };
  }

  Map<String, dynamic> _products(int page) {
    final items = page == 1
        ? [
            product(id: 1, name: 'Coffee voucher'),
            product(id: 2, name: 'Sold-out voucher', stock: 0, soldOut: true),
          ]
        : [
            product(id: 1, name: 'Coffee voucher'),
            product(id: 3, name: 'Tea voucher'),
          ];
    return {
      'list': items,
      'total': paginatedProducts ? 3 : 2,
      'page': page,
      'pageSize': 12,
      'hasMore': paginatedProducts && page == 1,
    };
  }

  Map<String, dynamic> _exchanges(int page) => {
    'list': [
      {
        'id': page == 1 ? 41 : 42,
        'productId': page == 1 ? 1 : 3,
        'productName': page == 1 ? 'Coffee voucher' : 'Tea voucher',
        'pointsCost': page == 1 ? 100 : 80,
        'quantity': 1,
        'status': page == 1 ? 1 : 0,
        'statusText': page == 1 ? 'Fulfilled' : 'Pending',
        'redeemCode': page == 1 ? 'PTCOFFEE41' : '',
        'remark': '',
        'fulfilledAt': page == 1 ? '2026-08-04 10:00:00' : '',
        'createdAt': '2026-08-04 09:00:00',
      },
    ],
    'total': 2,
    'page': page,
    'pageSize': 12,
    'hasMore': page == 1,
  };

  static Map<String, dynamic> product({
    required int id,
    required String name,
    int stock = 5,
    bool soldOut = false,
  }) => {
    'id': id,
    'region': 'CN',
    'name': name,
    'coverImage': '',
    'description': 'Product description',
    'pointsPrice': 100,
    'stock': stock,
    'exchangeLimitPerUser': 1,
    'exchangeCount': 0,
    'fulfillType': 1,
    'fulfillTypeText': 'Auto',
    'status': 1,
    'sort': id,
    'soldOut': soldOut,
    'createdAt': '2026-08-04 09:00:00',
    'updatedAt': '2026-08-04 09:00:00',
  };
}

Widget localizedApp({
  required Widget home,
  Locale locale = const Locale('zh', 'CN'),
}) => MaterialApp(
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

void main() {
  testWidgets(
    'points products paginate without duplicate rows and disable sold-out products',
    (tester) async {
      final api = PointsScreenApi()..paginatedProducts = true;
      await tester.pumpWidget(
        localizedApp(
          home: PointsMallScreen(repository: PointsMallRepository(api)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Coffee voucher'), findsOneWidget);
      final soldOut = tester.widget<FilledButton>(
        find.byKey(const Key('points-exchange-2')),
      );
      expect(soldOut.onPressed, isNull);

      await tester.ensureVisible(
        find.byKey(const Key('points-products-load-more')),
      );
      await tester.tap(find.byKey(const Key('points-products-load-more')));
      await tester.pumpAndSettle();

      expect(api.productPages, [1, 2]);
      expect(find.text('Coffee voucher'), findsOneWidget);
      expect(find.text('Tea voucher'), findsOneWidget);
    },
  );

  testWidgets('points products retry an initial loading failure', (
    tester,
  ) async {
    final api = PointsScreenApi()..failNextProductsLoad = true;
    await tester.pumpWidget(
      localizedApp(
        home: PointsMallScreen(repository: PointsMallRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('积分商品加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('points-products-retry')));
    await tester.pumpAndSettle();

    expect(api.productPages, [1, 1]);
    expect(find.text('Coffee voucher'), findsOneWidget);
  });

  testWidgets('successful exchange refreshes the balance and product list', (
    tester,
  ) async {
    final api = PointsScreenApi();
    int? spentPoints;
    await tester.pumpWidget(
      localizedApp(
        home: PointsMallScreen(
          repository: PointsMallRepository(api),
          points: 500,
          onPointsSpent: (points) => spentPoints = points,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('points-exchange-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('points-exchange-confirm')));
    await tester.pumpAndSettle();

    expect(api.exchangeRequests, 1);
    expect(api.productPages, [1, 1]);
    expect(spentPoints, 100);
    expect(find.text('当前积分 400'), findsOneWidget);
    expect(find.text('兑换成功'), findsOneWidget);
  });

  testWidgets('exchange action opens only one confirmation dialog', (
    tester,
  ) async {
    final api = PointsScreenApi();
    await tester.pumpWidget(
      localizedApp(
        home: PointsMallScreen(repository: PointsMallRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    final action = tester
        .widget<FilledButton>(find.byKey(const Key('points-exchange-1')))
        .onPressed!;
    action();
    action();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('确认兑换'), findsOneWidget);
    await tester.tap(find.byKey(const Key('points-exchange-cancel')));
    await tester.pumpAndSettle();
    expect(api.exchangeRequests, 0);
  });

  testWidgets('exchange errors are localized in English', (tester) async {
    final api = PointsScreenApi()..exchangeError = const ApiException('积分不足');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: PointsMallScreen(repository: PointsMallRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('points-exchange-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('points-exchange-confirm')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Not enough points. Earn more points first.'),
      findsOneWidget,
    );
    expect(find.textContaining('积分不足'), findsNothing);
  });

  testWidgets('exchange history retries once and loads the next page', (
    tester,
  ) async {
    final retryGate = Completer<void>();
    final api = PointsScreenApi()
      ..exchangesError = const ApiException('history unavailable');
    await tester.pumpWidget(
      localizedApp(
        home: PointsMallScreen(repository: PointsMallRepository(api)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('兑换记录'));
    await tester.pumpAndSettle();
    expect(find.textContaining('兑换记录加载失败'), findsOneWidget);

    api.exchangesGate = retryGate;
    final retry = tester
        .widget<FilledButton>(find.byKey(const Key('points-exchanges-retry')))
        .onPressed!;
    retry();
    retry();
    await tester.pump();
    expect(api.exchangePages, [1, 1]);

    retryGate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Coffee voucher'), findsOneWidget);

    api.exchangesGate = null;
    await tester.ensureVisible(
      find.byKey(const Key('points-exchanges-load-more')),
    );
    await tester.tap(find.byKey(const Key('points-exchanges-load-more')));
    await tester.pumpAndSettle();
    expect(api.exchangePages, [1, 1, 2]);
    expect(find.text('Tea voucher'), findsOneWidget);
  });
}
