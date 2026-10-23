import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';

class PostShopPickerScreen extends StatefulWidget {
  const PostShopPickerScreen({super.key, required this.repository});
  final BrowseRepository repository;

  @override
  State<PostShopPickerScreen> createState() => _PostShopPickerScreenState();
}

class _PostShopPickerScreenState extends State<PostShopPickerScreen> {
  final _query = TextEditingController();
  final List<ShopSummary> _items = [];
  String _keyword = '';
  int _page = 0;
  int _total = 0;
  int _request = 0;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load({required bool reset}) async {
    if (!reset && _loading) return;
    final request = ++_request;
    if (reset) _keyword = _query.text.trim();
    final page = reset ? 1 : _page + 1;
    setState(() {
      _loading = true;
      _failed = false;
      if (reset) {
        _items.clear();
        _page = 0;
        _total = 0;
      }
    });
    try {
      final result = await widget.repository.searchShopPage(
        _keyword,
        page: page,
        pageSize: 20,
      );
      if (!mounted || request != _request) return;
      setState(() {
        final ids = _items.map((item) => item.id).toSet();
        _items.addAll(result.items.where((item) => ids.add(item.id)));
        _page = result.page;
        _total = result.total;
      });
    } catch (_) {
      if (mounted && request == _request) setState(() => _failed = true);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.postChooseShop)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              key: const Key('post-shop-search'),
              controller: _query,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(reset: true),
              decoration: InputDecoration(
                labelText: strings.searchHint,
                suffixIcon: IconButton(
                  key: const Key('post-shop-search-submit'),
                  tooltip: strings.searchHint,
                  onPressed: () => _load(reset: true),
                  icon: const Icon(Icons.search),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ..._items.map(
                  (shop) => ListTile(
                    key: Key('post-shop-choice-${shop.id}'),
                    title: Text(shop.name),
                    subtitle: Text(shop.address),
                    leading: const Icon(Icons.storefront_outlined),
                    onTap: () => Navigator.of(context).pop(shop),
                  ),
                ),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (_failed)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(strings.postLinksLoadFailed),
                        TextButton(
                          key: const Key('post-shop-picker-retry'),
                          onPressed: () => _load(reset: _page == 0),
                          child: Text(strings.retry),
                        ),
                      ],
                    ),
                  ),
                if (!_loading && !_failed && _items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(strings.postNoMatchingShops),
                  ),
                if (!_loading && !_failed && _items.length < _total)
                  TextButton(
                    key: const Key('post-shop-picker-more'),
                    onPressed: () => _load(reset: false),
                    child: Text(strings.postLoadMoreShops),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PostDealPickerScreen extends StatefulWidget {
  const PostDealPickerScreen({
    super.key,
    required this.repository,
    required this.shopId,
  });
  final TradeRepository repository;
  final int shopId;

  @override
  State<PostDealPickerScreen> createState() => _PostDealPickerScreenState();
}

class _PostDealPickerScreenState extends State<PostDealPickerScreen> {
  late Future<List<DealSummary>> _deals;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_loading) return;
    final future = widget.repository.loadShopDeals(widget.shopId);
    setState(() {
      _deals = future;
      _loading = true;
    });
    try {
      await future;
    } catch (_) {
      // The FutureBuilder displays the error and a retry action.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.postChooseDeal)),
      body: FutureBuilder<List<DealSummary>>(
        future: _deals,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(strings.postLinksLoadFailed),
                  TextButton(
                    key: const Key('post-deal-picker-retry'),
                    onPressed: _loading ? null : _load,
                    child: Text(strings.retry),
                  ),
                ],
              ),
            );
          }
          final deals = snapshot.data!
              .where((deal) => deal.shopId == widget.shopId)
              .toList();
          if (deals.isEmpty) return Center(child: Text(strings.noDealsForShop));
          return ListView(
            children: deals
                .map(
                  (deal) => ListTile(
                    key: Key('post-deal-choice-${deal.id}'),
                    title: Text(deal.title),
                    subtitle: Text(
                      formatMoney(
                        deal.price,
                        deal.currency,
                        locale: strings.tag,
                      ),
                    ),
                    leading: const Icon(Icons.local_offer_outlined),
                    onTap: () => Navigator.of(context).pop(deal),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}
