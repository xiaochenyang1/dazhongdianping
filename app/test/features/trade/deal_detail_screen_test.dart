import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/trade/deal_detail_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class DealDetailApi implements JsonApi {
  Object? dealError;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (dealError != null) {
      final error = dealError!;
      dealError = null;
      throw error;
    }
    return {
      'id': 5,
      'shopId': 2,
      'shopName': 'Berlin Tea House',
      'title': 'Dinner Set',
      'price': 29.9,
      'originalPrice': 39.9,
      'currency': 'EUR',
      'stock': 10,
      'soldCount': 4,
      'rules': 'Booking required',
      'validStart': '2026-07-01',
      'validEnd': '2026-12-31',
      'items': const [],
    };
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
  testWidgets('deal detail localizes load errors in English', (tester) async {
    final api = DealDetailApi()..dealError = const ApiException('团购不存在');
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: DealDetailScreen(repository: TradeRepository(api), dealId: 5),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Could not load deal details: This deal could not be found.'),
      findsOneWidget,
    );
    expect(find.textContaining('团购不存在'), findsNothing);
  });
}
