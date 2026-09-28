import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/marketing/marketing_repository.dart';
import 'package:flutter/material.dart';

/// 领券中心：展示当前区域可领取的营销券，支持领取。
class CouponCenterScreen extends StatefulWidget {
  const CouponCenterScreen({super.key, required this.repository});

  final MarketingRepository repository;

  @override
  State<CouponCenterScreen> createState() => _CouponCenterScreenState();
}

class _CouponCenterScreenState extends State<CouponCenterScreen> {
  late Future<List<CouponCenterItem>> _items;
  final Set<int> _claiming = <int>{};

  @override
  void initState() {
    super.initState();
    _items = widget.repository.loadCenter();
  }

  Future<void> _reload() async {
    final future = widget.repository.loadCenter();
    setState(() => _items = future);
    await future.catchError((_) => <CouponCenterItem>[]);
  }

  Future<void> _claim(CouponCenterItem item) async {
    if (_claiming.contains(item.id)) return;
    setState(() => _claiming.add(item.id));
    final strings = AppLocalizations.of(context);
    try {
      await widget.repository.claim(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.couponClaimSuccess)),
      );
      await _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.couponClaimFailed(error))),
      );
    } finally {
      if (mounted) setState(() => _claiming.remove(item.id));
    }
  }

  String _typeLabel(AppLocalizations strings, CouponCenterItem item) =>
      item.type == 2 ? strings.couponTypeNewcomer : strings.couponTypeThreshold;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.couponCenterTitle)),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<CouponCenterItem>>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      strings.couponCenterLoadFailed(snapshot.error!),
                      key: const Key('coupon-center-error'),
                    ),
                  ),
                ],
              );
            }
            final items = snapshot.data ?? const [];
            if (items.isEmpty) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      strings.couponCenterEmpty,
                      key: const Key('coupon-center-empty'),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final discount =
                    '${item.discountAmount.toStringAsFixed(2)} ${item.currency}';
                final subtitle = item.type == 2
                    ? _typeLabel(strings, item)
                    : '${_typeLabel(strings, item)} · ≥${item.thresholdAmount.toStringAsFixed(2)} ${item.currency}';
                final claimable = item.claimable && !_claiming.contains(item.id);
                final buttonLabel = item.claimed
                    ? strings.couponClaimed
                    : item.soldOut
                        ? strings.couponSoldOut
                        : strings.couponClaim;
                return Card(
                  key: Key('coupon-center-item-${item.id}'),
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text('$discount\n$subtitle'),
                    isThreeLine: true,
                    trailing: FilledButton(
                      key: Key('coupon-center-claim-${item.id}'),
                      onPressed: claimable ? () => _claim(item) : null,
                      child: Text(buttonLabel),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
