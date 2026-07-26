import 'dart:async';

import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class SearchFakeRepository extends BrowseRepository {
  SearchFakeRepository({
    this.hotWords = const [],
    this.history = const [],
    this.suggestions = const [],
    this.paginated = false,
    this.paginatedHistory = false,
    this.failFirstPanel = false,
    this.failFirstSearch = false,
  });

  final List<SearchHotWord> hotWords;
  List<SearchHistoryItem> history;
  final List<SearchSuggestion> suggestions;
  final bool paginated;
  final bool paginatedHistory;
  final bool failFirstPanel;
  final bool failFirstSearch;
  int panelRequests = 0;
  int searchRequests = 0;
  final List<int> requestedPages = <int>[];
  final List<int> requestedHistoryPages = <int>[];
  final List<String> searchedKeywords = <String>[];
  final List<String> suggestionKeywords = <String>[];
  int clearCalls = 0;
  final List<int> removedHistoryIds = <int>[];
  Completer<void>? clearHistoryGate;
  final Map<int, Completer<void>> removeHistoryGates = {};
  final Map<int, Completer<void>> historyPageGates = {};

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
  Future<ShopSearchPage> searchShopPage(
    String keyword, {
    int page = 1,
    int pageSize = 20,
  }) async {
    searchRequests++;
    if (failFirstSearch && searchRequests == 1) {
      throw StateError('search network unavailable');
    }
    searchedKeywords.add(keyword);
    requestedPages.add(page);
    final shop = ShopSummary(
      id: page == 1 ? 7 : 8,
      name: page == 1 ? 'Berlin Tea' : 'Paris Tea',
      category: 'Tea',
      score: 4.5,
      currency: 'EUR',
      pricePerCapita: 12,
    );
    return ShopSearchPage(
      items: [shop],
      total: paginated ? 2 : 1,
      page: page,
      pageSize: paginated ? 1 : pageSize,
    );
  }

  @override
  Future<List<SearchHotWord>> loadHotWords({int limit = 8}) async {
    panelRequests++;
    if (failFirstPanel && panelRequests == 1) {
      throw StateError('panel network unavailable');
    }
    return hotWords;
  }

  @override
  Future<List<SearchHistoryItem>> loadSearchHistory({
    int page = 1,
    int pageSize = 8,
  }) async => history;

  @override
  Future<SearchHistoryPage> loadSearchHistoryPage({
    int page = 1,
    int pageSize = 8,
  }) async {
    requestedHistoryPages.add(page);
    await historyPageGates[page]?.future;
    final items = paginatedHistory
        ? [
            SearchHistoryItem(
              id: page,
              keyword: page == 1 ? 'noodles' : 'cafe',
              region: 'EU',
              updatedAt: '2026-07-25 10:00:00',
            ),
          ]
        : history;
    return SearchHistoryPage(
      items: items,
      total: paginatedHistory ? 2 : items.length,
      page: page,
      pageSize: paginatedHistory ? 1 : pageSize,
    );
  }

  @override
  Future<void> clearSearchHistory() async {
    clearCalls += 1;
    await clearHistoryGate?.future;
    history = const [];
  }

  @override
  Future<void> removeSearchHistoryItem(int historyId) async {
    removedHistoryIds.add(historyId);
    await removeHistoryGates[historyId]?.future;
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
  testWidgets('search discovery retries an initial panel failure', (
    tester,
  ) async {
    final repository = SearchFakeRepository(
      failFirstPanel: true,
      hotWords: const [SearchHotWord(term: 'Brunch', score: 12)],
    );
    await tester.pumpWidget(
      MaterialApp(home: SearchScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('搜索发现加载失败'), findsOneWidget);

    await tester.tap(find.byKey(const Key('search-panel-retry')));
    await tester.pumpAndSettle();
    expect(repository.panelRequests, 2);
    expect(find.text('Brunch · 12'), findsOneWidget);
  });

  testWidgets('search results retry the current keyword', (tester) async {
    final repository = SearchFakeRepository(failFirstSearch: true);
    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(repository: repository, initialKeyword: 'tea'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Search failed'), findsOneWidget);

    await tester.tap(find.byKey(const Key('search-results-retry')));
    await tester.pumpAndSettle();
    expect(repository.searchRequests, 2);
    expect(find.text('Berlin Tea'), findsOneWidget);
  });

  testWidgets('search screen loads later result pages', (tester) async {
    final repository = SearchFakeRepository(paginated: true);
    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(repository: repository, initialKeyword: 'tea'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search-results-load-more')), findsOneWidget);
    await tester.tap(find.byKey(const Key('search-results-load-more')));
    await tester.pumpAndSettle();

    expect(repository.requestedPages, [1, 2]);
    expect(find.text('Paris Tea'), findsOneWidget);
    expect(find.byKey(const Key('search-results-load-more')), findsNothing);
  });

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

  testWidgets('loads and merges later search history pages', (tester) async {
    final repository = SearchFakeRepository(
      hotWords: const [SearchHotWord(term: 'Brunch', score: 12)],
      paginatedHistory: true,
    );
    await tester.pumpWidget(
      MaterialApp(home: SearchScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('noodles'), findsOneWidget);
    await tester.tap(find.byKey(const Key('search-history-load-more')));
    await tester.pumpAndSettle();

    expect(repository.requestedHistoryPages, [1, 2]);
    expect(find.text('noodles'), findsOneWidget);
    expect(find.text('cafe'), findsOneWidget);
    expect(find.byKey(const Key('search-history-load-more')), findsNothing);
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

  testWidgets('guards duplicate search history removal', (tester) async {
    final repository = SearchFakeRepository(
      history: const [
        SearchHistoryItem(
          id: 11,
          keyword: 'noodles',
          region: 'EU',
          updatedAt: '2026-07-25 10:00:00',
        ),
      ],
    )..removeHistoryGates[11] = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(home: SearchScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    final history = find.byKey(const ValueKey('history-11'));
    final chip = tester.widget<InputChip>(history);
    chip.onDeleted!();
    chip.onDeleted!();

    expect(repository.removedHistoryIds, [11]);
    repository.removeHistoryGates[11]!.complete();
    await tester.pumpAndSettle();
    expect(find.text('noodles'), findsNothing);
  });

  testWidgets('clear invalidates an in-flight search history page', (
    tester,
  ) async {
    final repository = SearchFakeRepository(
      hotWords: const [SearchHotWord(term: 'Brunch', score: 12)],
      paginatedHistory: true,
    );
    await tester.pumpWidget(
      MaterialApp(home: SearchScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    repository.historyPageGates[2] = Completer<void>();

    await tester.tap(find.byKey(const Key('search-history-load-more')));
    await tester.tap(find.byKey(const Key('search-history-clear')));
    await tester.pumpAndSettle();

    expect(repository.clearCalls, 1);
    expect(find.text('noodles'), findsNothing);
    repository.historyPageGates[2]!.complete();
    await tester.pumpAndSettle();

    expect(find.text('cafe'), findsNothing);
    expect(find.text('noodles'), findsNothing);
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
