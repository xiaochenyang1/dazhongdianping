import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/shop_detail_screen.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.repository,
    this.initialKeyword = '',
    this.tradeRepository,
    this.reservationRepository,
    this.reviewRepository,
    this.canInteractReviews = false,
    this.thirdPartyConfig = const ThirdPartyConfig(),
  });
  final BrowseRepository repository;
  final String initialKeyword;
  final TradeRepository? tradeRepository;
  final ReservationRepository? reservationRepository;
  final ReviewRepository? reviewRepository;
  final bool canInteractReviews;
  final ThirdPartyConfig thirdPartyConfig;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;
  Future<ShopSearchPage>? _results;
  String _searchedKeyword = '';
  bool _loadingMore = false;
  bool _retryingSearch = false;
  List<SearchHotWord> _hotWords = const [];
  List<SearchHistoryItem> _history = const [];
  SearchHistoryPage? _historyPage;
  List<SearchSuggestion> _suggestions = const [];
  bool _panelLoading = false;
  bool _retryingPanel = false;
  bool _clearingHistory = false;
  bool _loadingMoreHistory = false;
  final Set<int> _removingHistoryIds = <int>{};
  int _historyRevision = 0;
  bool _suggestLoading = false;
  int _suggestRequestId = 0;
  String? _panelError;
  int _panelRequestId = 0;
  int _searchRequestId = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialKeyword);
    _controller.addListener(_onKeywordChanged);
    if (widget.initialKeyword.trim().isNotEmpty) {
      _search(widget.initialKeyword);
    } else {
      _loadPanel();
    }
  }

  void _onKeywordChanged() {
    final keyword = _controller.text.trim();
    if (keyword.isEmpty) {
      if (_suggestions.isNotEmpty || _suggestLoading) {
        setState(() {
          _suggestions = const [];
          _suggestLoading = false;
        });
      }
      return;
    }
    // Keep showing live suggestions while typing; results only appear after submit.
    _loadSuggestions(keyword);
  }

  Future<void> _loadSuggestions(String keyword) async {
    final requestId = ++_suggestRequestId;
    setState(() => _suggestLoading = true);
    try {
      final suggestions = await widget.repository.loadSearchSuggestions(
        keyword,
        limit: 8,
      );
      if (!mounted || requestId != _suggestRequestId) return;
      setState(() {
        _suggestions = suggestions;
        _suggestLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _suggestRequestId) return;
      setState(() {
        _suggestions = const [];
        _suggestLoading = false;
      });
    }
  }

  Future<void> _loadPanel() async {
    final requestId = ++_panelRequestId;
    final historyRevision = ++_historyRevision;
    setState(() {
      _panelLoading = true;
      _panelError = null;
      _loadingMoreHistory = false;
    });
    try {
      final hotFuture = widget.repository.loadHotWords(limit: 8);
      final historyFuture = widget.repository.loadSearchHistoryPage(
        page: 1,
        pageSize: 8,
      );
      final hot = await hotFuture;
      final historyPage = await historyFuture;
      if (!mounted ||
          requestId != _panelRequestId ||
          historyRevision != _historyRevision) {
        return;
      }
      setState(() {
        _hotWords = hot;
        _historyPage = historyPage;
        _history = historyPage.items;
        _panelLoading = false;
        _panelError = null;
      });
    } catch (error) {
      if (!mounted ||
          requestId != _panelRequestId ||
          historyRevision != _historyRevision) {
        return;
      }
      setState(() {
        _panelLoading = false;
        _panelError = '$error';
      });
    }
  }

  Future<void> _retryPanel() async {
    if (_retryingPanel) return;
    setState(() => _retryingPanel = true);
    try {
      await _loadPanel();
    } finally {
      if (mounted) setState(() => _retryingPanel = false);
    }
  }

  Future<void> _search(String value) async {
    final keyword = value.trim();
    if (keyword.isEmpty) return;
    final requestId = ++_searchRequestId;
    final future = widget.repository.searchShopPage(keyword);
    setState(() {
      _searchedKeyword = keyword;
      _results = future;
      _suggestions = const [];
      _loadingMore = false;
    });
    // Refresh history after a successful search so the new keyword appears.
    try {
      await future;
      if (!mounted || requestId != _searchRequestId) return;
      final historyRevision = ++_historyRevision;
      setState(() => _loadingMoreHistory = false);
      final historyPage = await widget.repository.loadSearchHistoryPage(
        page: 1,
        pageSize: 8,
      );
      if (!mounted ||
          requestId != _searchRequestId ||
          historyRevision != _historyRevision) {
        return;
      }
      setState(() {
        _historyPage = historyPage;
        _history = historyPage.items;
      });
    } catch (_) {
      // Search failure is already rendered by FutureBuilder; history refresh is best-effort.
    }
  }

  Future<void> _retrySearch() async {
    if (_retryingSearch) return;
    setState(() => _retryingSearch = true);
    try {
      await _search(_searchedKeyword);
    } finally {
      if (mounted) setState(() => _retryingSearch = false);
    }
  }

  void _showDiscovery() {
    _searchRequestId++;
    setState(() {
      _results = null;
      _searchedKeyword = '';
      _controller.clear();
      _suggestions = const [];
      _loadingMore = false;
    });
    _loadPanel();
  }

  Future<void> _loadMore(ShopSearchPage current) async {
    if (_loadingMore || !current.hasMore || _searchedKeyword.isEmpty) return;
    final requestId = _searchRequestId;
    setState(() => _loadingMore = true);
    try {
      final next = await widget.repository.searchShopPage(
        _searchedKeyword,
        page: current.page + 1,
        pageSize: current.pageSize,
      );
      if (!mounted || requestId != _searchRequestId) return;
      final knownIds = current.items.map((shop) => shop.id).toSet();
      setState(() {
        _results = Future.value(
          ShopSearchPage(
            items: [
              ...current.items,
              ...next.items.where((shop) => knownIds.add(shop.id)),
            ],
            total: next.total,
            page: next.page,
            pageSize: current.pageSize,
          ),
        );
      });
    } catch (error) {
      if (mounted && requestId == _searchRequestId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).loadMoreShopsFailed(error),
            ),
          ),
        );
      }
    } finally {
      if (mounted && requestId == _searchRequestId) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _clearHistory() async {
    if (_clearingHistory || _removingHistoryIds.isNotEmpty) return;
    _historyRevision++;
    setState(() {
      _clearingHistory = true;
      _loadingMoreHistory = false;
    });
    try {
      await widget.repository.clearSearchHistory();
      if (!mounted) return;
      setState(() {
        _history = const [];
        _historyPage = null;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).clearHistoryFailed(error)),
        ),
      );
    } finally {
      if (mounted) setState(() => _clearingHistory = false);
    }
  }

  Future<void> _removeHistoryItem(SearchHistoryItem item) async {
    if (_clearingHistory || _removingHistoryIds.contains(item.id)) return;
    _historyRevision++;
    setState(() {
      _removingHistoryIds.add(item.id);
      _loadingMoreHistory = false;
    });
    try {
      await widget.repository.removeSearchHistoryItem(item.id);
      if (!mounted) return;
      setState(() {
        _history = _history.where((row) => row.id != item.id).toList();
        final page = _historyPage;
        if (page != null) {
          _historyPage = SearchHistoryPage(
            items: _history,
            total: page.total > 0 ? page.total - 1 : 0,
            page: page.page,
            pageSize: page.pageSize,
          );
        }
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).removeHistoryFailed(error),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _removingHistoryIds.remove(item.id));
      }
    }
  }

  Future<void> _loadMoreHistory() async {
    final current = _historyPage;
    if (current == null ||
        _loadingMoreHistory ||
        _clearingHistory ||
        _removingHistoryIds.isNotEmpty ||
        !current.hasMore) {
      return;
    }
    final revision = _historyRevision;
    setState(() => _loadingMoreHistory = true);
    try {
      final next = await widget.repository.loadSearchHistoryPage(
        page: current.page + 1,
        pageSize: current.pageSize,
      );
      final knownIds = _history.map((item) => item.id).toSet();
      final merged = [
        ..._history,
        ...next.items.where((item) => knownIds.add(item.id)),
      ];
      if (mounted && revision == _historyRevision) {
        setState(() {
          _history = merged;
          _historyPage = SearchHistoryPage(
            items: merged,
            total: next.total,
            page: next.page,
            pageSize: next.pageSize,
          );
        });
      }
    } catch (error) {
      if (mounted && revision == _historyRevision) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).loadMoreHistoryFailed(error),
            ),
          ),
        );
      }
    } finally {
      if (mounted && revision == _historyRevision) {
        setState(() => _loadingMoreHistory = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onKeywordChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.searchTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: widget.initialKeyword.isEmpty,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: strings.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  key: Key(
                    _results == null
                        ? 'search-submit'
                        : 'search-show-discovery',
                  ),
                  onPressed: _results == null
                      ? () => _search(_controller.text)
                      : _showDiscovery,
                  icon: Icon(
                    _results == null ? Icons.arrow_forward : Icons.close,
                  ),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            if (_suggestions.isNotEmpty || _suggestLoading) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _suggestLoading
                      ? strings.searchSuggestionsLoading
                      : strings.searchSuggestions,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              if (_suggestions.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestions
                        .map(
                          (item) => ActionChip(
                            key: ValueKey('suggest-${item.type}-${item.term}'),
                            label: Text(
                              item.type.isEmpty
                                  ? item.term
                                  : '${item.term} · ${item.type}',
                            ),
                            onPressed: () {
                              if (item.type == 'shop' && item.refId != null) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ShopDetailScreen(
                                      repository: widget.repository,
                                      shopId: item.refId!,
                                      tradeRepository: widget.tradeRepository,
                                      reservationRepository:
                                          widget.reservationRepository,
                                      reviewRepository: widget.reviewRepository,
                                      canInteractReviews:
                                          widget.canInteractReviews,
                                      thirdPartyConfig: widget.thirdPartyConfig,
                                    ),
                                  ),
                                );
                                return;
                              }
                              _controller.text = item.term;
                              _search(item.term);
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: _results == null
                  ? _buildDiscoveryPanel()
                  : FutureBuilder<ShopSearchPage>(
                      future: _results,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(strings.searchFailed(snapshot.error!)),
                                const SizedBox(height: 12),
                                FilledButton.tonalIcon(
                                  key: const Key('search-results-retry'),
                                  onPressed: _retryingSearch
                                      ? null
                                      : _retrySearch,
                                  icon: const Icon(Icons.refresh),
                                  label: Text(
                                    _retryingSearch
                                        ? strings.processing
                                        : strings.retry,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        final page = snapshot.data!;
                        final items = page.items;
                        if (items.isEmpty) {
                          return Center(child: Text(strings.noMatchingPlaces));
                        }
                        return ListView.separated(
                          itemCount: items.length + (page.hasMore ? 1 : 0),
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            if (index == items.length) {
                              return Center(
                                child: OutlinedButton.icon(
                                  key: const Key('search-results-load-more'),
                                  onPressed: _loadingMore
                                      ? null
                                      : () => _loadMore(page),
                                  icon: _loadingMore
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.expand_more),
                                  label: Text(
                                    _loadingMore
                                        ? strings.loading
                                        : strings.loadMore,
                                  ),
                                ),
                              );
                            }
                            final shop = items[index];
                            return ListTile(
                              title: Text(shop.name),
                              subtitle: Text(
                                strings
                                        .certificationBadgeLabel(
                                          code: shop.merchantCertificationCode,
                                          fallback:
                                              shop.merchantCertificationLabel,
                                        )
                                        .isEmpty
                                    ? '${shop.category} · ★ ${shop.score.toStringAsFixed(1)}'
                                    : '${shop.category} · ★ ${shop.score.toStringAsFixed(1)} · ${strings.certificationBadgeLabel(code: shop.merchantCertificationCode, fallback: shop.merchantCertificationLabel)}',
                              ),
                              trailing: Text(
                                formatMoney(
                                  shop.pricePerCapita,
                                  shop.currency,
                                  locale: strings.tag,
                                ),
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ShopDetailScreen(
                                    repository: widget.repository,
                                    shopId: shop.id,
                                    tradeRepository: widget.tradeRepository,
                                    reservationRepository:
                                        widget.reservationRepository,
                                    reviewRepository: widget.reviewRepository,
                                    canInteractReviews:
                                        widget.canInteractReviews,
                                    thirdPartyConfig: widget.thirdPartyConfig,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryPanel() {
    final strings = AppLocalizations.of(context);
    if (_panelLoading && _hotWords.isEmpty && _history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hotWords.isEmpty && _history.isEmpty) {
      if (_panelError != null) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(strings.discoveryFailed(_panelError!)),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                key: const Key('search-panel-retry'),
                onPressed: _retryingPanel ? null : _retryPanel,
                icon: const Icon(Icons.refresh),
                label: Text(
                  _retryingPanel ? strings.processing : strings.retry,
                ),
              ),
            ],
          ),
        );
      }
      return Center(child: Text(strings.enterKeyword));
    }
    return ListView(
      children: [
        if (_history.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.recentSearches,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              TextButton(
                key: const Key('search-history-clear'),
                onPressed: _clearingHistory || _removingHistoryIds.isNotEmpty
                    ? null
                    : _clearHistory,
                child: Text(
                  _clearingHistory ? strings.clearing : strings.clear,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _history
                .map(
                  (item) => InputChip(
                    key: ValueKey('history-${item.id}'),
                    label: Text(item.keyword),
                    onPressed: () {
                      _controller.text = item.keyword;
                      _search(item.keyword);
                    },
                    onDeleted:
                        _clearingHistory ||
                            _removingHistoryIds.contains(item.id)
                        ? null
                        : () => _removeHistoryItem(item),
                    deleteIcon: const Icon(Icons.close, size: 16),
                  ),
                )
                .toList(),
          ),
          if (_historyPage?.hasMore ?? false) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('search-history-load-more'),
                onPressed:
                    _loadingMoreHistory ||
                        _clearingHistory ||
                        _removingHistoryIds.isNotEmpty
                    ? null
                    : _loadMoreHistory,
                icon: _loadingMoreHistory
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more),
                label: Text(
                  _loadingMoreHistory ? strings.loading : strings.moreHistory,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
        ],
        if (_hotWords.isNotEmpty) ...[
          Text(
            strings.hotSearches,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _hotWords
                .map(
                  (item) => ActionChip(
                    key: ValueKey('hot-${item.term}'),
                    label: Text('${item.term} · ${item.score}'),
                    onPressed: () {
                      _controller.text = item.term;
                      _search(item.term);
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
