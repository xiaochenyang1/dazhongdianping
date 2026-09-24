import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/marketing/marketing_repository.dart';
import 'package:flutter/material.dart';

/// 我的营销券钱包：展示已领取的满减券/立减券及其状态。
class MyMarketingCouponsScreen extends StatefulWidget {
  const MyMarketingCouponsScreen({super.key, required this.repository});

  final MarketingRepository repository;

  @override
  State<MyMarketingCouponsScreen> createState() =>
      _MyMarketingCouponsScreenState();
}

class _MyMarketingCouponsScreenState extends State<MyMarketingCouponsScreen> {
  late Future<List<MarketingCoupon>> _coupons;

  @override
  void initState() {
    super.initState();
    _coupons = widget.repository.loadMyCoupons();
  }

  Future<void> _reload() async {
    final future = widget.repository.loadMyCoupons();
    setState(() => _coupons = future);
    await future.catchError((_) => <MarketingCoupon>[]);
  }

  String _statusLabel(AppLocalizations strings, MarketingCoupon c) {
    switch (c.status) {
      case 2:
        return strings.marketingCouponStatusUsed;
      case 3:
        return strings.marketingCouponStatusExpired;
      default:
        return strings.marketingCouponStatusUnused;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.myMarketingCouponsTitle)),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<MarketingCoupon>>(
          future: _coupons,
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
                      strings.myMarketingCouponsLoadFailed(snapshot.error!),
                      key: const Key('my-marketing-coupons-error'),
                    ),
                  ),
                ],
              );
            }
            final coupons = snapshot.data ?? const [];
            if (coupons.isEmpty) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      strings.marketingCouponsEmpty,
                      key: const Key('my-marketing-coupons-empty'),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: coupons.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final c = coupons[index];
                final typeLabel = c.type == 2
                    ? strings.couponTypeNewcomer
                    : strings.couponTypeThreshold;
                final discount =
                    '${c.discountAmount.toStringAsFixed(2)} ${c.currency}';
                final detail = c.type == 2
                    ? typeLabel
                    : '$typeLabel · ≥${c.thresholdAmount.toStringAsFixed(2)} ${c.currency}';
                return Card(
                  key: Key('my-marketing-coupon-${c.id}'),
                  child: ListTile(
                    title: Text(c.templateName),
                    subtitle: Text('$discount\n$detail · ${_statusLabel(strings, c)}'),
                    isThreeLine: true,
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
