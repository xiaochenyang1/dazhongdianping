import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class SearchFakeRepository extends BrowseRepository {
  SearchFakeRepository({
    this.hotWords = const [],
    this.history = const [],
    this.suggestions = const [],
  });

  final List<SearchHotWord> hotWords;
  List<SearchHistoryItem> history;
  final List<SearchSuggestion> suggestions;
  final List<String> searchedKeywords = <String>[];
  final List<String> suggestionKeywords = <String>[];
  int clearCalls = 0;
  final List<int> removedHistoryIds = <int>[];

  @override
  Future<List<ShopSummary>> loadFeaturedShops() async => const [];

  @override
  Future<List<ShopSummary>> searchShops(String keyword) async {
    searchedKeywords.add(keyword);
    return const [
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

  @override
  Future<List<SearchHotWord>> loadHotWords({int limit = 8}) async => hotWords;

  @override
  Future<List<SearchHistoryItem>> loadSearchHistory({
    int page = 1,
    int pageSize = 8,
  }) async => history;

  @override
  Future<void> clearSearchHistory() async {
    clearCalls += 1;
    history = const [];
  }

  @override
  Future<void> removeSearchHistoryItem(int historyId) async {
    removedHistoryIds.add(historyId);
    history = history.where((item) => item.id != historyId).toList();
  }

  @override
  Future<List<SearchSuggestion>> loadSearchSuggestions(
    String keyword, {
    int limit = 8,
  }) async {
    suggestionKeywords.add(keyword);
    return suggestions;
  }
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

  testWidgets('shows hot words and search history before first query', (
    tester,
  ) async {
    final repository = SearchFakeRepository(
      hotWords: const [
        SearchHotWord(term: 'Brunch', score: 12),
        SearchHotWord(term: 'Hotpot', score: 9),
      ],
      history: const [
        SearchHistoryItem(
          id: 1,
          keyword: 'noodles',
          region: 'EU',
          updatedAt: '2026-07-25 10:00:00',
        ),
        SearchHistoryItem(
          id: 2,
          keyword: 'cafe',
          region: 'EU',
          updatedAt: '2026-07-25 10:01:00',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: SearchScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('最近搜过'), findsOneWidget);
    expect(find.text('当前热词'), findsOneWidget);
    expect(find.text('noodles'), findsOneWidget);
    expect(find.text('Brunch · 12'), findsOneWidget);

    await tester.tap(find.text('Brunch · 12'));
    await tester.pumpAndSettle();

    expect(repository.searchedKeywords, contains('Brunch'));
    expect(find.text('Berlin Tea'), findsOneWidget);
  });

  testWidgets('can remove one history item and clear all history', (
    tester,
  ) async {
    final repository = SearchFakeRepository(
      history: const [
        SearchHistoryItem(
          id: 11,
          keyword: 'noodles',
          region: 'EU',
          updatedAt: '2026-07-25 10:00:00',
        ),
        SearchHistoryItem(
          id: 12,
          keyword: 'cafe',
          region: 'EU',
          updatedAt: '2026-07-25 10:01:00',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: SearchScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('noodles'), findsOneWidget);
    expect(find.text('cafe'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    expect(repository.removedHistoryIds, contains(11));
    expect(find.text('noodles'), findsNothing);
    expect(find.text('cafe'), findsOneWidget);

    await tester.tap(find.text('清空'));
    await tester.pumpAndSettle();

    expect(repository.clearCalls, 1);
    expect(find.text('cafe'), findsNothing);
    expect(find.text('最近搜过'), findsNothing);
  });

  testWidgets('shows live search suggestions while typing', (tester) async {
    final repository = SearchFakeRepository(
      suggestions: const [
        SearchSuggestion(term: '火锅', type: 'category', refId: 102),
        SearchSuggestion(term: '渝里火锅', type: 'shop', refId: 10001),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: SearchScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '火');
    await tester.pumpAndSettle();

    expect(repository.suggestionKeywords, contains('火'));
    expect(find.text('搜索联想'), findsOneWidget);
    expect(find.text('火锅 · category'), findsOneWidget);

    await tester.tap(find.text('火锅 · category'));
    await tester.pumpAndSettle();

    expect(repository.searchedKeywords, contains('火锅'));
    expect(find.text('Berlin Tea'), findsOneWidget);
  });
}
