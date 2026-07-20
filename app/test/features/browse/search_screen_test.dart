import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class SearchFakeRepository extends BrowseRepository {
  @override
  Future<List<ShopSummary>> loadFeaturedShops() async => const [];

  @override
  Future<List<ShopSummary>> searchShops(String keyword) async => const [
    ShopSummary(
      id: 7,
      name: 'Berlin Tea',
      category: 'Tea',
      score: 4.5,
      currency: 'EUR',
      pricePerCapita: 12,
    ),
  ];
}

void main() {
  testWidgets('search screen submits keyword and renders result', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(
          repository: SearchFakeRepository(),
          initialKeyword: 'tea',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Berlin Tea'), findsOneWidget);
    expect(find.text('Search results'), findsOneWidget);
  });
}
