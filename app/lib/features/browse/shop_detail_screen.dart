import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_screen.dart';
import 'package:dazhongdianping_app/features/review/review_editor_screen.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/trade/deals_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:flutter/material.dart';

class ShopDetailScreen extends StatefulWidget {
  const ShopDetailScreen({
    super.key,
    required this.repository,
    required this.shopId,
    this.tradeRepository,
    this.reservationRepository,
    this.reviewRepository,
    this.thirdPartyConfig = const ThirdPartyConfig(),
  });
  final BrowseRepository repository;
  final int shopId;
  final TradeRepository? tradeRepository;
  final ReservationRepository? reservationRepository;
  final ReviewRepository? reviewRepository;
  final ThirdPartyConfig thirdPartyConfig;

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  late Future<ShopDetail> _detail;

  @override
  void initState() {
    super.initState();
    _detail = widget.repository.loadShopDetail(widget.shopId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Place details')),
      body: FutureBuilder<ShopDetail>(
        future: _detail,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton(
                onPressed: () => setState(
                  () =>
                      _detail = widget.repository.loadShopDetail(widget.shopId),
                ),
                child: const Text('Retry'),
              ),
            );
          }
          final shop = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                shop.name,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${shop.category} · ★ ${shop.score.toStringAsFixed(1)} · ${shop.currency} ${shop.pricePerCapita}',
              ),
              const SizedBox(height: 24),
              _InfoTile(
                icon: Icons.location_on_outlined,
                title: 'Address',
                value: shop.address,
              ),
              _InfoTile(
                icon: Icons.schedule_outlined,
                title: 'Opening hours',
                value: shop.businessHours,
              ),
              _InfoTile(
                icon: Icons.phone_outlined,
                title: 'Phone',
                value: shop.phone,
              ),
              const SizedBox(height: 20),
              Text(shop.summary),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: shop.tags
                    .map((tag) => Chip(label: Text(tag)))
                    .toList(),
              ),
              const SizedBox(height: 24),
              if (widget.reviewRepository != null) ...[
                FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReviewEditorScreen(
                        repository: widget.reviewRepository!,
                        shopId: shop.id,
                        shopName: shop.name,
                        currency: shop.currency,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('写点评'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  if (widget.tradeRepository != null)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DealsScreen(
                              repository: widget.tradeRepository!,
                              shopId: widget.shopId,
                              thirdPartyConfig: widget.thirdPartyConfig,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.local_offer_outlined),
                        label: const Text('团购优惠'),
                      ),
                    ),
                  if (widget.tradeRepository != null &&
                      widget.reservationRepository != null)
                    const SizedBox(width: 12),
                  if (widget.reservationRepository != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReservationScreen(
                              repository: widget.reservationRepository!,
                              shopId: widget.shopId,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.event_available_outlined),
                        label: const Text('在线预订'),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(value.isEmpty ? '--' : value),
  );
}
