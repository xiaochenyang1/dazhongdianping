import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/qa/qa_repository.dart';
import 'package:dazhongdianping_app/features/qa/shop_qa_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class QaSectionFakeApi implements JsonApi {
  int askCalls = 0;

  @override
  Future<Map<String, dynamic>> getJson(String path, {Map<String, Object?>? query}) async {
    if (path.endsWith('/answers')) {
      return {'value': const []};
    }
    return {
      'list': [
        {'id': 7, 'userNickname': 'Amu', 'content': 'Do I need a reservation?', 'answerCount': 0, 'latestAnswer': ''},
      ],
      'total': 1,
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    askCalls++;
    return {'id': 8, 'userNickname': 'Amu', 'content': 'Parking?', 'answerCount': 0, 'latestAnswer': ''};
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
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('lists questions and posts a new one', (tester) async {
    final api = QaSectionFakeApi();
    await tester.pumpWidget(
      _wrap(ShopQaSection(repository: QaRepository(api), shopId: 10001)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Do I need a reservation?'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('qa-ask-input')), 'Parking?');
    await tester.tap(find.byKey(const Key('qa-ask-submit')));
    await tester.pumpAndSettle();

    expect(api.askCalls, 1);
  });
}
