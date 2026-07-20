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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialKeyword);
    if (widget.initialKeyword.trim().isNotEmpty) _search(widget.initialKeyword);
  }

  void _search(String value) {
    final keyword = value.trim();
    if (keyword.isEmpty) return;
    setState(() {
      _results = widget.repository.searchShops(keyword);
    });
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
                  ? const Center(child: Text('Enter a keyword to search'))
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
                                '${shop.category} · ★ ${shop.score.toStringAsFixed(1)}',
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
}
