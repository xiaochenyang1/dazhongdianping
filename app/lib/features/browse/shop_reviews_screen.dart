import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/browse_error_localizer.dart';
import 'package:dazhongdianping_app/features/review/review_detail_screen.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:flutter/material.dart';

class ShopReviewsScreen extends StatefulWidget {
  const ShopReviewsScreen({
    super.key,
    required this.repository,
    required this.shopId,
    this.shopName = '',
    this.reviewRepository,
    this.canInteractReviews = false,
  });

  final BrowseRepository repository;
  final int shopId;
  final String shopName;
  final ReviewRepository? reviewRepository;
  final bool canInteractReviews;

  @override
  State<ShopReviewsScreen> createState() => _ShopReviewsScreenState();
}

class _ShopReviewsScreenState extends State<ShopReviewsScreen> {
  static const _pageSize = 20;
  String _sort = 'latest';
  double? _minScore;
  bool? _hasImages;
  late Future<ShopReviewPage> _page;
  final List<ShopReviewPreview> _items = <ShopReviewPreview>[];
  int _currentPage = 1;
  bool _hasMore = false;
  bool _loadingMore = false;
  bool _retrying = false;
  String? _loadMoreError;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _startReload();

  Future<ShopReviewPage> _startReload() {
    final requestId = ++_requestId;
    final future = widget.repository.loadShopReviewPage(
      widget.shopId,
      page: 1,
      pageSize: _pageSize,
      sort: _sort,
      minScore: _minScore,
      hasImages: _hasImages,
    );
    setState(() {
      _page = future;
      _items.clear();
      _currentPage = 1;
      _hasMore = false;
      _loadMoreError = null;
    });
    future
        .then((result) {
          if (!mounted || requestId != _requestId) return;
          setState(() {
            _items
              ..clear()
              ..addAll(result.items);
            _currentPage = result.page;
            _hasMore = result.hasMore;
          });
        })
        .catchError((_) {});
    return future;
  }

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await _startReload();
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final requestId = _requestId;
    setState(() {
      _loadingMore = true;
      _loadMoreError = null;
    });
    try {
      final result = await widget.repository.loadShopReviewPage(
        widget.shopId,
        page: _currentPage + 1,
        pageSize: _pageSize,
        sort: _sort,
        minScore: _minScore,
        hasImages: _hasImages,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        final knownIds = _items.map((item) => item.id).toSet();
        _items.addAll(result.items.where((item) => knownIds.add(item.id)));
        _currentPage = result.page;
        _hasMore = result.hasMore;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      final strings = AppLocalizations.of(context);
      setState(() => _loadMoreError = localizeBrowseError(strings, error));
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loadingMore = false);
      }
    }
  }

  void _openReview(ShopReviewPreview item) {
    final reviewRepository = widget.reviewRepository;
    if (reviewRepository == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewDetailScreen(
          repository: reviewRepository,
          reviewId: item.id,
          canInteract: widget.canInteractReviews,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final title = widget.shopName.isEmpty
        ? strings.shopReviewsSection
        : '${widget.shopName} · ${strings.reviewsMetric}';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      key: const Key('shop-reviews-sort-latest'),
                      label: Text(strings.sortLatest),
                      selected: _sort == 'latest',
                      onSelected: (_) {
                        if (_sort == 'latest') return;
                        setState(() => _sort = 'latest');
                        _reload();
                      },
                    ),
                    ChoiceChip(
                      key: const Key('shop-reviews-sort-popular'),
                      label: Text(strings.sortHottest),
                      selected: _sort == 'popular',
                      onSelected: (_) {
                        if (_sort == 'popular') return;
                        setState(() => _sort = 'popular');
                        _reload();
                      },
                    ),
                    ChoiceChip(
                      key: const Key('shop-reviews-sort-score'),
                      label: Text(strings.sortBestRated),
                      selected: _sort == 'score',
                      onSelected: (_) {
                        if (_sort == 'score') return;
                        setState(() => _sort = 'score');
                        _reload();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      key: const Key('shop-reviews-filter-score4'),
                      label: Text(strings.minScoreFour),
                      selected: _minScore == 4,
                      onSelected: (selected) {
                        setState(() => _minScore = selected ? 4 : null);
                        _reload();
                      },
                    ),
                    FilterChip(
                      key: const Key('shop-reviews-filter-images'),
                      label: Text(strings.withPhotosOnly),
                      selected: _hasImages == true,
                      onSelected: (selected) {
                        setState(() => _hasImages = selected ? true : null);
                        _reload();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<ShopReviewPage>(
              future: _page,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done &&
                    _items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError && _items.isEmpty) {
                  final error = localizeBrowseError(strings, snapshot.error!);
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(strings.shopReviewsLoadFailed(error)),
                        const SizedBox(height: 12),
                        FilledButton.tonalIcon(
                          key: const Key('shop-reviews-retry'),
                          onPressed: _retrying ? null : _retry,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            _retrying ? strings.processing : strings.retry,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                if (_items.isEmpty) {
                  return Center(child: Text(strings.noPublicReviews));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: _items.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == _items.length) {
                      if (_loadMoreError != null) {
                        return Text(strings.loadMoreFailed(_loadMoreError!));
                      }
                      if (!_hasMore) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: Text(strings.alreadyAtEnd)),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Center(
                          child: FilledButton.tonal(
                            key: const Key('shop-reviews-load-more'),
                            onPressed: _loadingMore ? null : _loadMore,
                            child: Text(
                              _loadingMore ? strings.loading : strings.loadMore,
                            ),
                          ),
                        ),
                      );
                    }
                    final item = _items[index];
                    final userName = item.userName.isEmpty
                        ? strings.anonymousUser
                        : item.userName;
                    return Card(
                      child: ListTile(
                        title: Text(
                          strings
                                  .certificationBadgeLabel(
                                    code: item.authorCertificationCode,
                                    fallback: item.authorCertificationLabel,
                                  )
                                  .isEmpty
                              ? '$userName · ★ ${item.score.toStringAsFixed(1)}'
                              : '$userName · ${strings.certificationBadgeLabel(code: item.authorCertificationCode, fallback: item.authorCertificationLabel)} · ★ ${item.score.toStringAsFixed(1)}',
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text(item.content),
                            if (item.merchantReply != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                strings.merchantReplyLabel(
                                  item.merchantReply ?? '',
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              '${strings.likeCommentStats(likes: item.likedCount, comments: item.commentCount)}'
                              '${item.createdAt.isEmpty ? '' : ' · ${formatDisplayDateTime(item.createdAt, locale: strings.tag)}'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: widget.reviewRepository == null
                            ? null
                            : const Icon(Icons.chevron_right),
                        onTap: widget.reviewRepository == null
                            ? null
                            : () => _openReview(item),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
