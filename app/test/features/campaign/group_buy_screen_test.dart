import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/campaign/campaign_repository.dart';
import 'package:dazhongdianping_app/features/campaign/group_buy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class GroupBuyApi implements JsonApi {
  String? postedPath;
  int loads = 0;

  Map<String, dynamic> get order => {
    'id': 87,
    'orderNo': 'OD87',
    'dealTitle': 'Dinner group',
    'shopName': 'Paris restaurant',
    'quantity': 1,
    'unitPrice': 19.9,
    'amount': 19.9,
    'currency': 'EUR',
    'payStatus': 0,
    'payStatusText': '待支付',
    'status': 1,
    'orderSource': 'groupbuy',
    'campaignTitle': 'Dinner group',
    'groupBuyTeamId': 90,
    'groupBuyStatus': 1,
    'groupBuyMemberCount': 1,
    'groupBuyPaidCount': 0,
    'groupBuySize': 3,
    'coupons': const [],
  };

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    loads++;
    return {
      'value': [
        {
          'id': 12,
          'title': 'Dinner group',
          'dealId': 41,
          'groupPrice': 19.9,
          'currency': 'EUR',
          'groupSize': 3,
        },
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postedPath = path;
    return {
      'id': 90,
      'status': 1,
      'memberCount': path.endsWith('/join') ? 2 : 1,
      'paidCount': 0,
      'groupSize': 3,
      'orderId': 87,
      'order': order,
    };
  }
}

Widget wrap(GroupBuyApi api) => MaterialApp(
  locale: const Locale('en'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: GroupBuyScreen(repository: CampaignRepository(api)),
);

void main() {
  testWidgets('opening a group creates an order and opens its detail', (
    tester,
  ) async {
    final api = GroupBuyApi();
    await tester.pumpWidget(wrap(api));
    await tester.pumpAndSettle();

    expect(find.textContaining('refunded automatically'), findsOneWidget);
    expect(find.textContaining('€19.90'), findsOneWidget);
    await tester.tap(find.byKey(const Key('groupbuy-open-12')));
    await tester.pumpAndSettle();

    expect(api.postedPath, '/api/c/v1/marketing/groupbuy/12/teams');
    expect(find.byKey(const Key('groupbuy-status')), findsOneWidget);
    expect(find.textContaining('Payment progress 0/3'), findsOneWidget);
  });

  testWidgets('joining a group opens the member order', (tester) async {
    final api = GroupBuyApi();
    await tester.pumpWidget(wrap(api));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('groupbuy-team-id')), '90');
    await tester.tap(find.byKey(const Key('groupbuy-join')));
    await tester.pumpAndSettle();

    expect(api.postedPath, '/api/c/v1/marketing/groupbuy/teams/90/join');
    expect(find.byKey(const Key('groupbuy-status')), findsOneWidget);
  });
}
