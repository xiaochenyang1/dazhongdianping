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
    this.thirdPartyConfig = const ThirdPartyConfig(),
  });
  final BrowseRepository repository;
  final String initialKeyword;
  final TradeRepository? tradeRepository;
  final ReservationRepository? reservationRepository;
  final ReviewRepository? reviewRepository;
  final ThirdPartyConfig thirdPartyConfig;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;
  Future<List<ShopSummary>>? _results;
  List<SearchHotWord> _hotWords = const [];
  List<SearchHistoryItem> _history = const [];
  bool _panelLoading = false;
  bool _clearingHistory = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialKeyword);
    if (widget.initialKeyword.trim().isNotEmpty) {
      _search(widget.initialKeyword);
    } else {
      _loadPanel();
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
      _results = widget.repository.searchShops(keyword);
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

  Future<void> _clearHistory() async {
    if (_clearingHistory) return;
    setState(() => _clearingHistory = true);
    try {
      await widget.repository.clearSearchHistory();
      if (!mounted) return;
      setState(() => _history = const []);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('清空搜索历史失败：$error')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除搜索历史失败：$error')),
      );
    }
  }

  @override
  void dispose() {
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
            const SizedBox(height: 16),
            Expanded(
              child: _results == null
                  ? _buildDiscoveryPanel()
                  : FutureBuilder<List<ShopSummary>>(
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
                        final items = snapshot.data ?? const [];
                        if (items.isEmpty) {
                          return const Center(
                            child: Text('No matching places'),
                          );
                        }
                        return ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
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
