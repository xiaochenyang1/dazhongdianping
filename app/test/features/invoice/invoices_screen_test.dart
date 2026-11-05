import 'dart:async';
import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/invoice/invoice_repository.dart';
import 'package:dazhongdianping_app/features/invoice/invoices_screen.dart';
import 'package:dazhongdianping_app/features/trade/order_detail_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class InvoiceApi implements JsonApi {
  List<Map<String, dynamic>> titles = [
    {'id': 8, 'name': 'First title', 'titleType': 1},
    {
      'id': 9,
      'name': 'Default company',
      'titleType': 2,
      'taxNo': 'VAT-9',
      'isDefault': true,
    },
  ];
  List<Map<String, dynamic>> history = [];
  final queries = <String, Map<String, Object?>?>{};
  final eligible = <int>{42, 43};
  bool failLoad = false;
  bool failRequest = false;
  bool failTitle = false;
  bool failRefreshAfterRequest = false;
  Completer<void>? requestGate;
  Completer<void>? titleGate;
  Map<String, dynamic>? requestBody;
  Map<String, dynamic>? titleBody;
  int requests = 0;
  int saves = 0;

  Map<String, dynamic> order(int id) => {
    'id': id,
    'orderNo': 'ORDER-$id',
    'dealTitle': 'Dinner $id',
    'shopName': 'Paris restaurant',
    'amount': 50,
    'currency': 'EUR',
  };
  Map<String, dynamic> page(
    List<Map<String, dynamic>> items,
    int current,
    bool more,
  ) => {'list': items, 'page': current, 'hasMore': more};
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    queries[path] = query;
    if (failLoad) throw const ApiException('offline');
    final current = query?['page'] as int? ?? 1;
    if (path.endsWith('/titles')) return {'value': titles};
    if (path.endsWith('/invoices/orders')) {
      final focused = query?['orderId'] as int?;
      final id = focused ?? (current == 1 ? 42 : 43);
      return page(
        eligible.contains(id) ? [order(id)] : [],
        current,
        focused == null && current == 1,
      );
    }
    if (path == '/api/c/v1/orders/42') {
      return {
        ...order(42),
        'quantity': 1,
        'unitPrice': 50,
        'payStatus': 1,
        'status': 1,
        'coupons': [],
      };
    }
    return page(
      current == 1 ? history : [invoice(101, 43, 3)],
      current,
      current == 1 && history.isNotEmpty,
    );
  }

  Map<String, dynamic> invoice(int id, int orderId, int status) => {
    'id': id,
    'orderId': orderId,
    'status': status,
    'amount': 50,
    'taxAmount': 10,
    'currency': 'EUR',
    if (status == 2) 'invoiceNo': 'INV-REGISTERED',
    if (status == 3) 'rejectReason': 'Incorrect company details',
  };
  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    if (path.endsWith('/titles')) {
      saves++;
      titleBody = Map<String, dynamic>.from(body as Map);
      await titleGate?.future;
      if (failTitle) throw const ApiException('title offline');
      final created = {'id': 27, ...titleBody!};
      titles = [created, ...titles];
      return created;
    }
    requests++;
    requestBody = Map<String, dynamic>.from(body as Map);
    await requestGate?.future;
    if (failRequest) throw const ApiException('payment service offline');
    final id = requestBody!['orderId'] as int;
    if (!eligible.remove(id)) {
      throw const ApiException('该订单已申请开票', statusCode: 409);
    }
    final created = invoice(100, id, 1);
    history.insert(0, created);
    failLoad = failRefreshAfterRequest;
    return created;
  }
}

Future<void> mount(
  WidgetTester tester,
  InvoiceApi api, {
  int? orderId,
  bool fromOrder = false,
  String locale = 'en',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: fromOrder
          ? OrderDetailScreen(repository: TradeRepository(api), orderId: 42)
          : InvoicesScreen(
              repository: InvoiceRepository(api),
              orderId: orderId,
            ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'paid order opens its eligible order without asking for an internal ID',
    (tester) async {
      final api = InvoiceApi();
      await mount(tester, api, fromOrder: true);
      await tap(tester, 'order-invoice-button');
      expect(api.queries['/api/c/v1/invoices/orders']?['orderId'], 42);
      expect(find.text('orderId'), findsNothing);
      expect(find.textContaining('Dinner 42'), findsWidgets);
      await tap(tester, 'invoice-request');
      expect(api.requestBody, {'orderId': 42, 'titleId': 9});
      expect(find.text('Invoice request submitted.'), findsWidgets);
      expect(find.byKey(const Key('invoice-100')), findsOneWidget);
    },
  );

  testWidgets('selection and pagination use the chosen order and title', (
    tester,
  ) async {
    final api = InvoiceApi();
    await mount(tester, api);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('invoice-request')))
          .onPressed,
      isNull,
    );
    await tap(tester, 'invoice-orders-more');
    await tap(tester, 'invoice-order-0');
    await tester.tap(find.textContaining('Dinner 43').last);
    await tester.pumpAndSettle();
    await tap(tester, 'invoice-title-9');
    await tester.tap(find.text('First title').last);
    await tester.pumpAndSettle();
    await tap(tester, 'invoice-request');
    expect(api.requestBody, {'orderId': 43, 'titleId': 8});
  });

  testWidgets(
    'failed load can retry and invalid focused order cannot be submitted',
    (tester) async {
      final api = InvoiceApi()..failLoad = true;
      await mount(tester, api, orderId: 999);
      expect(find.byKey(const Key('invoice-load-error')), findsOneWidget);
      api.failLoad = false;
      await tap(tester, 'invoice-retry');
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('invoice-request')))
            .onPressed,
        isNull,
      );
      await tap(tester, 'invoice-other-orders');
      expect(
        api.queries['/api/c/v1/invoices/orders']!.containsKey('orderId'),
        isFalse,
      );
      expect(
        tester.widget<DropdownButtonFormField<int>>(
          find.byKey(const Key('invoice-order-0')),
        ),
        isNotNull,
      );
    },
  );

  testWidgets(
    'company title validates fields, preserves a failed draft and selects the created ID',
    (tester) async {
      final api = InvoiceApi()
        ..titles = []
        ..failTitle = true;
      await mount(tester, api, orderId: 42);
      await tap(tester, 'invoice-new-title');
      await tap(tester, 'invoice-title-type');
      await tester.tap(find.text('Company').last);
      await tester.pumpAndSettle();
      await tap(tester, 'invoice-save-title');
      expect(api.saves, 0);
      expect(
        find.text('A tax number is required for a company.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('invoice-name')),
        'New company',
      );
      await tester.enterText(find.byKey(const Key('invoice-tax-no')), 'FR-27');
      await tester.enterText(find.byKey(const Key('invoice-email')), 'invalid');
      await tap(tester, 'invoice-save-title');
      expect(api.saves, 0);
      await tester.enterText(
        find.byKey(const Key('invoice-email')),
        'finance@example.com',
      );
      await tap(tester, 'invoice-save-title');
      expect(find.text('New company'), findsOneWidget);
      expect(api.saves, 1);
      expect(find.textContaining('title offline'), findsWidgets);
      api.failTitle = false;
      await tap(tester, 'invoice-save-title');
      expect(api.titleBody, {
        'titleType': 2,
        'name': 'New company',
        'taxNo': 'FR-27',
        'email': 'finance@example.com',
        'isDefault': true,
      });
      await tap(tester, 'invoice-request');
      expect(api.requestBody!['titleId'], 27);
    },
  );

  testWidgets('rapid requests submit once and retain selection after failure', (
    tester,
  ) async {
    final gate = Completer<void>();
    final api = InvoiceApi()
      ..requestGate = gate
      ..failRequest = true;
    await mount(tester, api, orderId: 42);
    final send = tester
        .widget<FilledButton>(find.byKey(const Key('invoice-request')))
        .onPressed!;
    send();
    send();
    await tester.pump();
    expect(api.requests, 1);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('invoice-order-42')), findsOneWidget);
    expect(find.byKey(const Key('invoice-action-error')), findsOneWidget);
    api.failRequest = false;
    await tap(tester, 'invoice-request');
    expect(api.requests, 2);
    expect(find.text('Invoice request submitted.'), findsWidgets);
  });

  testWidgets(
    'successful submission remains successful if the subsequent refresh fails',
    (tester) async {
      final api = InvoiceApi()..failRefreshAfterRequest = true;
      await mount(tester, api, orderId: 42);
      await tap(tester, 'invoice-request');
      expect(find.text('Invoice request submitted.'), findsWidgets);
      expect(find.byKey(const Key('invoice-load-error')), findsOneWidget);
      expect(find.byKey(const Key('invoice-action-error')), findsNothing);
      expect(find.byKey(const Key('invoice-100')), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('invoice-request')))
            .onPressed,
        isNull,
      );
      api.failLoad = false;
      await tap(tester, 'invoice-retry');
      expect(api.requests, 1);
    },
  );

  testWidgets(
    'conflict refreshes eligibility and explains the existing request',
    (tester) async {
      final api = InvoiceApi();
      await mount(tester, api, orderId: 42);
      api.eligible.clear();
      api.history = [api.invoice(100, 42, 1)];
      await tap(tester, 'invoice-request');
      expect(
        find.textContaining('This order already has an invoice request'),
        findsWidgets,
      );
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('invoice-request')))
            .onPressed,
        isNull,
      );
      expect(find.byKey(const Key('invoice-100')), findsOneWidget);
    },
  );

  testWidgets(
    'history paginates and shows registered number and rejection reason',
    (tester) async {
      final api = InvoiceApi()..history = [InvoiceApi().invoice(100, 42, 2)];
      await mount(tester, api);
      expect(find.text('Invoice registered'), findsOneWidget);
      expect(find.text('Invoice number: INV-REGISTERED'), findsOneWidget);
      await tap(tester, 'invoice-history-more');
      expect(find.text('Incorrect company details'), findsOneWidget);
      expect(find.byKey(const Key('invoice-100')), findsOneWidget);
    },
  );

  testWidgets(
    'late save after leaving the screen does not update disposed state',
    (tester) async {
      final gate = Completer<void>();
      final api = InvoiceApi()..requestGate = gate;
      await mount(tester, api, orderId: 42);
      tester
          .widget<FilledButton>(find.byKey(const Key('invoice-request')))
          .onPressed!();
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      gate.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
