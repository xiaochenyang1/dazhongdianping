import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';
import 'package:dazhongdianping_app/features/points/points_repository.dart';
import 'package:flutter/material.dart';

typedef L10n = AppLocalizations;

class PointsProductDetailScreen extends StatefulWidget {
  const PointsProductDetailScreen({
    super.key,
    required this.productId,
    required this.repository,
    this.points,
    this.onPointsSpent,
  });

  final int productId;
  final PointsMallRepository repository;
  final int? points;
  final ValueChanged<int>? onPointsSpent;

  @override
  State<PointsProductDetailScreen> createState() =>
      _PointsProductDetailScreenState();
}

class _PointsProductDetailScreenState
    extends State<PointsProductDetailScreen> {
  late Future<PointsProduct> _productFuture;
  int? _points;
  bool _exchanging = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _points = widget.points;
    _productFuture = widget.repository.loadProduct(widget.productId);
  }

  Future<void> _exchange(PointsProduct product) async {
    if (_exchanging) return;

    final l10n = L10n.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.pointsExchangeConfirmTitle),
        content: Text(
          l10n.pointsExchangeConfirmMessage(
            points: product.pointsPrice,
            name: product.name,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirmCancel),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _exchanging = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await widget.repository.exchange(product.id);
      if (!mounted) return;

      setState(() {
        _points = (_points ?? 0) - product.pointsPrice;
        _successMessage = l10n.pointsExchangeSuccess;
      });

      widget.onPointsSpent?.call(product.pointsPrice);

      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      final l10n = L10n.of(context);
      setState(() {
        _errorMessage = localizeAuthError(l10n, error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _exchanging = false;
        });
      }
    }
  }

  bool _canExchange(PointsProduct product) {
    if (product.soldOut || _exchanging) return false;
    final balance = _points ?? 0;
    return balance >= product.pointsPrice;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = L10n.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pointsMallProductDetail),
      ),
      body: FutureBuilder<PointsProduct>(
        future: _productFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      localizeAuthError(l10n, snapshot.error!),
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _productFuture = widget.repository
                              .loadProduct(widget.productId);
                        });
                      },
                      child: Text(l10n.retry),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(child: Text(l10n.noPointsProducts));
          }

          final product = snapshot.data!;
          final balance = _points ?? 0;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover image
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    product.coverImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: theme.colorScheme.surfaceContainer,
                      child: Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name
                      Text(
                        product.name,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),

                      // Price
                      Row(
                        children: [
                          Text(
                            l10n.pointsPriceLabel(product.pointsPrice),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Status badges
                      if (product.soldOut)
                        Chip(
                          label: Text(l10n.pointsSoldOut),
                          backgroundColor: theme.colorScheme.surfaceContainer,
                        )
                      else if (balance < product.pointsPrice)
                        Chip(
                          label: Text(l10n.pointsMallInsufficientBalance),
                          backgroundColor:
                              theme.colorScheme.errorContainer,
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Meta info
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildMetaRow(
                                context,
                                l10n.pointsMallStock,
                                product.stock > 9999
                                    ? l10n.pointsMallAbundant
                                    : l10n.pointsStockLabel(product.stock),
                              ),
                              const Divider(),
                              _buildMetaRow(
                                context,
                                l10n.pointsMallExchangeLimit,
                                product.exchangeLimitPerUser <= 0
                                    ? l10n.pointsLimitUnlimited
                                    : l10n.pointsLimitLabel(
                                        product.exchangeLimitPerUser,
                                      ),
                              ),
                              const Divider(),
                              _buildMetaRow(
                                context,
                                l10n.pointsMallFulfillType,
                                product.fulfillTypeText,
                              ),
                              const Divider(),
                              _buildMetaRow(
                                context,
                                l10n.pointsMallExchangeCount,
                                '${product.exchangeCount}',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      Text(
                        l10n.pointsMallProductDescription,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),

                      // Messages
                      if (_successMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _successMessage!,
                                  style: TextStyle(
                                    color:
                                        theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: _canExchange(product)
                                  ? () => _exchange(product)
                                  : null,
                              child: _exchanging
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(l10n.pointsMallExchangeNow),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Balance
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.pointsMallYourBalance,
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              l10n.pointsBalanceLabel(balance),
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetaRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
