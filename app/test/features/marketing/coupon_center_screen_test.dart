import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/marketing/coupon_center_screen.dart';
import 'package:dazhongdianping_app/features/marketing/marketing_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class CouponCenterFakeApi implements JsonApi {
  int claimCalls = 0;
  bool claimed = false;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    return {
      'value': [
        {
          'id': 5001,
          'name': 'Spend 100 save 20',
          'type': 1,
          'typeText': 'Spend & save',
          'thresholdAmount': 100,
          'discountAmount': 20,
          'currency': 'EUR',
          'shopId': 0,
          'perUserLimit': 1,
          'validDays': 30,
          'claimed': claimed,
          'soldOut': false,
          'claimable': !claimed,
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    claimCalls++;
    claimed = true;
    return {
      'id': 9001,
      'templateId': 5001,
      'templateName': 'Spend 100 save 20',
      'type': 1,
      'typeText': 'Spend & save',
      'thresholdAmount': 100,
      'discountAmount': 20,
      'currency': 'EUR',
      'shopId': 0,
      'status': 1,
      'statusText': 'Unused',
    };
  }
}

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );

void main() {
  testWidgets('lists claimable coupons and claims one', (tester) async {
    final api = CouponCenterFakeApi();
    await tester.pumpWidget(
      _wrap(CouponCenterScreen(repository: MarketingRepository(api))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Spend 100 save 20'), findsOneWidget);
    expect(find.byKey(const Key('coupon-center-claim-5001')), findsOneWidget);

    await tester.tap(find.byKey(const Key('coupon-center-claim-5001')));
    await tester.pumpAndSettle();

    expect(api.claimCalls, 1);
    expect(find.text('Claimed'), findsWidgets);
  });
}
