import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';
import 'package:dazhongdianping_app/features/points/points_repository.dart';
import 'package:flutter/material.dart';

class PointsMallScreen extends StatefulWidget {
  const PointsMallScreen({
    super.key,
    required this.repository,
    this.points,
    this.onPointsSpent,
  });

  final PointsMallRepository repository;

  /// Balance rendered in the header; refreshed locally after each redemption.
  final int? points;
  final ValueChanged<int>? onPointsSpent;

  @override
  State<PointsMallScreen> createState() => _PointsMallScreenState();
}

class _PointsMallScreenState extends State<PointsMallScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<PointsProductPage> _productsFuture;
  Future<PointsExchangePage>? _exchangesFuture;
  final List<PointsProduct> _products = <PointsProduct>[];
  final List<PointsExchange> _exchanges = <PointsExchange>[];
  int? _points;
  int _productPage = 1;
  int _exchangePage = 1;
  bool _productsHasMore = false;
  bool _exchangesHasMore = false;
  bool _loadingMoreProducts = false;
  bool _loadingMoreExchanges = false;
  bool _reloadingProducts = false;
  bool _reloadingExchanges = false;
  bool _exchangeDialogOpen = false;
  int _productRevision = 0;
  int _exchangeRevision = 0;
  int? _exchangingProductId;
  String? _productError;
  String? _exchangeError;

  @override
  void initState() {
    super.initState();
    _points = widget.points;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _productsFuture = _loadProducts(reset: true, revision: _productRevision);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1 && _exchangesFuture == null) {
      final future = _loadExchanges(reset: true, revision: _exchangeRevision);
      future.ignore();
      setState(() {
        _exchangesFuture = future;
      });
    }
  }

  Future<PointsProductPage> _loadProducts({
    required bool reset,
    required int revision,
  }) async {
    final nextPage = reset ? 1 : _productPage + 1;
    final page = await widget.repository.loadProducts(page: nextPage);
    if (!mounted || revision != _productRevision) return page;
    setState(() {
      if (reset) {
        _products
          ..clear()
          ..addAll(page.items);
      } else {
        final knownIds = _products.map((item) => item.id).toSet();
        _products.addAll(page.items.where((item) => knownIds.add(item.id)));
      }
      _productPage = page.page;
      _productsHasMore = page.hasMore;
      _productError = null;
      _loadingMoreProducts = false;
      _productsFuture = Future.value(page);
    });
    return page;
  }

  Future<PointsExchangePage> _loadExchanges({
    required bool reset,
    required int revision,
  }) async {
    final nextPage = reset ? 1 : _exchangePage + 1;
    final page = await widget.repository.loadExchanges(page: nextPage);
    if (!mounted || revision != _exchangeRevision) return page;
    setState(() {
      if (reset) {
        _exchanges
          ..clear()
          ..addAll(page.items);
      } else {
        final knownIds = _exchanges.map((item) => item.id).toSet();
        _exchanges.addAll(page.items.where((item) => knownIds.add(item.id)));
      }
      _exchangePage = page.page;
      _exchangesHasMore = page.hasMore;
      _exchangeError = null;
      _loadingMoreExchanges = false;
      _exchangesFuture = Future.value(page);
    });
    return page;
  }

  Future<void> _reloadProducts() async {
    if (_reloadingProducts) return;
    final revision = ++_productRevision;
    setState(() {
      _loadingMoreProducts = false;
      _reloadingProducts = true;
    });
    try {
      await _loadProducts(reset: true, revision: revision);
    } catch (error) {
      if (!mounted || revision != _productRevision) return;
      final strings = AppLocalizations.of(context);
      setState(
        () => _productError = strings.pointsProductsLoadFailed(
          localizeAuthError(strings, error),
        ),
      );
    } finally {
      if (mounted && revision == _productRevision) {
        setState(() => _reloadingProducts = false);
      }
    }
  }

  Future<void> _reloadExchanges() async {
    if (_reloadingExchanges) return;
    final revision = ++_exchangeRevision;
    setState(() => _reloadingExchanges = true);
    try {
      await _loadExchanges(reset: true, revision: revision);
    } catch (error) {
      if (!mounted || revision != _exchangeRevision) return;
      final strings = AppLocalizations.of(context);
      setState(
        () => _exchangeError = strings.pointsExchangesLoadFailed(
          localizeAuthError(strings, error),
        ),
      );
    } finally {
      if (mounted && revision == _exchangeRevision) {
        setState(() => _reloadingExchanges = false);
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_loadingMoreProducts || !_productsHasMore) return;
    final revision = _productRevision;
    setState(() => _loadingMoreProducts = true);
    try {
      await _loadProducts(reset: false, revision: revision);
    } catch (error) {
      if (!mounted || revision != _productRevision) return;
      final strings = AppLocalizations.of(context);
      setState(() {
        _loadingMoreProducts = false;
        _productError = strings.loadMoreFailed(
          localizeAuthError(strings, error),
        );
      });
    }
  }

  Future<void> _loadMoreExchanges() async {
    if (_loadingMoreExchanges || !_exchangesHasMore) return;
    final revision = _exchangeRevision;
    setState(() => _loadingMoreExchanges = true);
    try {
      await _loadExchanges(reset: false, revision: revision);
    } catch (error) {
      if (!mounted || revision != _exchangeRevision) return;
      final strings = AppLocalizations.of(context);
      setState(() {
        _loadingMoreExchanges = false;
        _exchangeError = strings.loadMoreFailed(
          localizeAuthError(strings, error),
        );
      });
    }
  }

  Future<void> _exchange(PointsProduct product) async {
    if (_exchangingProductId != null || _exchangeDialogOpen) return;
    _exchangeDialogOpen = true;
    final strings = AppLocalizations.of(context);
    bool? confirmed;
    try {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(strings.pointsExchangeConfirmTitle),
          content: Text(
            strings.pointsExchangeConfirmMessage(
              points: product.pointsPrice,
              name: product.name,
            ),
          ),
          actions: [
            TextButton(
              key: const Key('points-exchange-cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(strings.cancelAction),
            ),
            FilledButton(
              key: const Key('points-exchange-confirm'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(strings.pointsExchangeAction),
            ),
          ],
        ),
      );
    } finally {
      _exchangeDialogOpen = false;
    }
    if (confirmed != true || !mounted) return;

    setState(() {
      _exchangingProductId = product.id;
      _productError = null;
    });
    try {
      final exchange = await widget.repository.exchange(product.id);
      if (!mounted) return;
      setState(() {
        _exchanges.insert(0, exchange);
        if (_points != null) {
          _points = (_points! - exchange.pointsCost).clamp(0, 1 << 31);
        }
      });
      widget.onPointsSpent?.call(exchange.pointsCost);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.pointsExchangeSuccess)));
      await _reloadProducts();
      if (_exchangesFuture != null) await _reloadExchanges();
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _productError = strings.pointsExchangeFailed(
          localizeAuthError(strings, error),
        ),
      );
    } finally {
      if (mounted) setState(() => _exchangingProductId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.pointsMall),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: strings.pointsProductsTab),
            Tab(text: strings.pointsExchangesTab),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                _points == null
                    ? strings.pointsMallSubtitle
                    : strings.pointsBalanceLabel(_points!),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(strings),
                _buildExchangesTab(strings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab(AppLocalizations strings) {
    return FutureBuilder<PointsProductPage>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done &&
            _products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError && _products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings.pointsProductsLoadFailed(
                    localizeAuthError(strings, snapshot.error!),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('points-products-retry'),
                  onPressed: _reloadingProducts ? null : _reloadProducts,
                  child: Text(
                    _reloadingProducts ? strings.processing : strings.retry,
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _reloadProducts,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_productError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _productError!,
                    style: const TextStyle(color: Color(0xFFB91C1C)),
                  ),
                ),
              if (_products.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: Text(strings.noPointsProducts)),
                )
              else
                ..._products.map(
                  (product) => _buildProductCard(strings, product),
                ),
              if (_productsHasMore)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  child: Center(
                    child: FilledButton.tonal(
                      key: const Key('points-products-load-more'),
                      onPressed: _loadingMoreProducts
                          ? null
                          : _loadMoreProducts,
                      child: Text(
                        _loadingMoreProducts
                            ? strings.loading
                            : strings.loadMore,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductCard(AppLocalizations strings, PointsProduct product) {
    final busy = _exchangingProductId == product.id;
    final limitText = product.unlimitedPerUser
        ? strings.pointsLimitUnlimited
        : strings.pointsLimitLabel(product.exchangeLimitPerUser);
    return Card(
      key: Key('points-product-${product.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.coverImage.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    product.coverImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFE5E7EB),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              product.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (product.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                product.description,
                style: const TextStyle(color: Color(0xFF4B5563)),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              [
                strings.pointsPriceLabel(product.pointsPrice),
                strings.pointsStockLabel(product.stock),
                limitText,
                strings.pointsFulfillTypeLabel(
                  product.fulfillType,
                  fallback: product.fulfillTypeText,
                ),
              ].where((part) => part.isNotEmpty).join(' · '),
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                key: Key('points-exchange-${product.id}'),
                onPressed: product.soldOut || busy
                    ? null
                    : () => _exchange(product),
                child: Text(
                  busy
                      ? strings.processing
                      : product.soldOut
                      ? strings.pointsSoldOut
                      : strings.pointsExchangeAction,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExchangesTab(AppLocalizations strings) {
    final future = _exchangesFuture;
    if (future == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder<PointsExchangePage>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done &&
            _exchanges.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError && _exchanges.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  strings.pointsExchangesLoadFailed(
                    localizeAuthError(strings, snapshot.error!),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const Key('points-exchanges-retry'),
                  onPressed: _reloadingExchanges ? null : _reloadExchanges,
                  child: Text(
                    _reloadingExchanges ? strings.processing : strings.retry,
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _reloadExchanges,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_exchangeError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _exchangeError!,
                    style: const TextStyle(color: Color(0xFFB91C1C)),
                  ),
                ),
              if (_exchanges.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: Text(strings.noPointsExchanges)),
                )
              else
                ..._exchanges.map((exchange) {
                  final codeText = exchange.redeemCode.isNotEmpty
                      ? strings.pointsRedeemCodeLabel(exchange.redeemCode)
                      : exchange.cancelled
                      ? ''
                      : strings.pointsRedeemCodePending;
                  return Card(
                    key: Key('points-exchange-row-${exchange.id}'),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(exchange.productName),
                      subtitle: Text(
                        [
                          strings.pointsExchangeStatusLabel(
                            exchange.status,
                            fallback: exchange.statusText,
                          ),
                          strings.pointsPriceLabel(exchange.pointsCost),
                          if (codeText.isNotEmpty) codeText,
                          if (exchange.remark.isNotEmpty) exchange.remark,
                          if (exchange.createdAt.isNotEmpty)
                            formatDisplayDateTime(
                              exchange.createdAt,
                              locale: strings.tag,
                            ),
                        ].where((part) => part.isNotEmpty).join(' · '),
                      ),
                    ),
                  );
                }),
              if (_exchangesHasMore)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  child: Center(
                    child: FilledButton.tonal(
                      key: const Key('points-exchanges-load-more'),
                      onPressed: _loadingMoreExchanges
                          ? null
                          : _loadMoreExchanges,
                      child: Text(
                        _loadingMoreExchanges
                            ? strings.loading
                            : strings.loadMore,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
