import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/features/trade/trade_error_localizer.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';

class DealDetailScreen extends StatefulWidget {
  const DealDetailScreen({
    super.key,
    required this.repository,
    required this.dealId,
  });

  final TradeRepository repository;
  final int dealId;

  @override
  State<DealDetailScreen> createState() => _DealDetailScreenState();
}

class _DealDetailScreenState extends State<DealDetailScreen> {
  late Future<DealDetail> _detail;
  bool _reloading = false;

  @override
  void initState() {
    super.initState();
    _detail = widget.repository.loadDeal(widget.dealId);
  }

  Future<void> _reload() async {
    if (_reloading) return;
    final future = widget.repository.loadDeal(widget.dealId);
    setState(() {
      _detail = future;
      _reloading = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => _reloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.dealDetail)),
      body: FutureBuilder<DealDetail>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    strings.dealDetailLoadFailed(
                      localizeTradeError(strings, snapshot.error!),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    key: const Key('deal-detail-retry'),
                    onPressed: _reloading ? null : _reload,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      _reloading ? strings.processing : strings.retry,
                    ),
                  ),
                ],
              ),
            );
          }

          final detail = snapshot.data!;
          final validity = [
            if (detail.validStart.isNotEmpty) detail.validStart,
            if (detail.validEnd.isNotEmpty) detail.validEnd,
          ].join(' ~ ');
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (detail.coverImage.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      detail.coverImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: Color(0xFFF1F1F1),
                        child: Center(child: Icon(Icons.broken_image_outlined)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                detail.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              if (detail.shopName.isNotEmpty) Text(detail.shopName),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(detail.price, detail.currency),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (detail.originalPrice > detail.price)
                    Text(
                      formatMoney(detail.originalPrice, detail.currency),
                      style: const TextStyle(
                        color: Colors.black54,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                strings.soldAndStock(
                  sold: detail.soldCount,
                  stock: detail.stock,
                ),
              ),
              if (validity.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(strings.validUntil(validity)),
              ],
              if (detail.rules.isNotEmpty) ...[
                const SizedBox(height: 22),
                Text(
                  strings.usageRules,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(detail.rules),
              ],
              const SizedBox(height: 22),
              Text(
                strings.packageContents,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              if (detail.items.isEmpty)
                Text(strings.noPackageItems)
              else
                ...detail.items.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.name),
                    subtitle: Text(strings.quantityLabel(item.quantity)),
                    trailing: Text(formatMoney(item.price, detail.currency)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
