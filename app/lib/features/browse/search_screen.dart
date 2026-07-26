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
  List<SearchHotWord> _hotWords = const [];
  List<SearchHistoryItem> _history = const [];
  List<SearchSuggestion> _suggestions = const [];
  bool _panelLoading = false;
  bool _clearingHistory = false;
  bool _suggestLoading = false;
  int _suggestRequestId = 0;

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
    setState(() => _panelLoading = true);
    try {
      final hotFuture = widget.repository.loadHotWords(limit: 8);
      final historyFuture = widget.repository.loadSearchHistory(
        page: 1,
        pageSize: 8,
      );
      final hot = await hotFuture;
      final history = await historyFuture;
      if (!mounted) return;
      setState(() {
        _hotWords = hot;
        _history = history;
        _panelLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _panelLoading = false);
    }
  }

  Future<void> _search(String value) async {
    final keyword = value.trim();
    if (keyword.isEmpty) return;
    setState(() {
      _searchedKeyword = keyword;
      _results = widget.repository.searchShopPage(keyword);
      _suggestions = const [];
    });
    // Refresh history after a successful search so the new keyword appears.
    try {
      await _results;
      if (!mounted) return;
      final history = await widget.repository.loadSearchHistory(
        page: 1,
        pageSize: 8,
      );
      if (!mounted) return;
      setState(() => _history = history);
    } catch (_) {
      // Search failure is already rendered by FutureBuilder; history refresh is best-effort.
    }
  }

  Future<void> _loadMore(ShopSearchPage current) async {
    if (_loadingMore || !current.hasMore || _searchedKeyword.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final next = await widget.repository.searchShopPage(
        _searchedKeyword,
        page: current.page + 1,
        pageSize: current.pageSize,
      );
      if (!mounted) return;
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载更多门店失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _clearHistory() async {
    if (_clearingHistory) return;
    setState(() => _clearingHistory = true);
    try {
      await widget.repository.clearSearchHistory();
      if (!mounted) return;
      setState(() => _history = const []);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('清空搜索历史失败：$error')));
    } finally {
      if (mounted) setState(() => _clearingHistory = false);
    }
  }

  Future<void> _removeHistoryItem(SearchHistoryItem item) async {
    try {
      await widget.repository.removeSearchHistoryItem(item.id);
      if (!mounted) return;
      setState(() {
        _history = _history.where((row) => row.id != item.id).toList();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('删除搜索历史失败：$error')));
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
    return Scaffold(
      appBar: AppBar(title: const Text('Search results')),
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
                hintText: 'Restaurant, supermarket, service',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () => _search(_controller.text),
                  icon: const Icon(Icons.arrow_forward),
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            if (_suggestions.isNotEmpty || _suggestLoading) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _suggestLoading ? '联想加载中...' : '搜索联想',
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
                            child: Text('Search failed: ${snapshot.error}'),
                          );
                        }
                        final page = snapshot.data!;
                        final items = page.items;
                        if (items.isEmpty) {
                          return const Center(
                            child: Text('No matching places'),
                          );
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
                                  label: Text(_loadingMore ? '加载中...' : '加载更多'),
                                ),
                              );
                            }
                            final shop = items[index];
                            return ListTile(
                              title: Text(shop.name),
                              subtitle: Text(
                                shop.merchantCertificationLabel == null
                                    ? '${shop.category} · ★ ${shop.score.toStringAsFixed(1)}'
                                    : '${shop.category} · ★ ${shop.score.toStringAsFixed(1)} · ${shop.merchantCertificationLabel}',
                              ),
                              trailing: Text(
                                '${shop.currency} ${shop.pricePerCapita}',
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
    if (_panelLoading && _hotWords.isEmpty && _history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hotWords.isEmpty && _history.isEmpty) {
      return const Center(child: Text('Enter a keyword to search'));
    }
    return ListView(
      children: [
        if (_history.isNotEmpty) ...[
          Row(
            children: [
              const Expanded(
                child: Text(
                  '最近搜过',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: _clearingHistory ? null : _clearHistory,
                child: Text(_clearingHistory ? '清空中...' : '清空'),
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
                    onDeleted: () => _removeHistoryItem(item),
                    deleteIcon: const Icon(Icons.close, size: 16),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
        ],
        if (_hotWords.isNotEmpty) ...[
          const Text(
            '当前热词',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
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
