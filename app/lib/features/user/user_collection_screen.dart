import 'dart:convert';

import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/shop_detail_screen.dart';
import 'package:dazhongdianping_app/features/community/community_repository.dart';
import 'package:dazhongdianping_app/features/community/post_detail_screen.dart';
import 'package:dazhongdianping_app/features/community/post_editor_screen.dart';
import 'package:dazhongdianping_app/features/review/review_detail_screen.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/reservation/reservations_list_screen.dart';
import 'package:dazhongdianping_app/features/trade/coupons_screen.dart';
import 'package:dazhongdianping_app/features/trade/orders_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';

String _localizedCollectionError(AppLocalizations strings, Object error) {
  return localizeAuthError(
    strings,
    error,
    overrides: {'用户登录状态不存在': strings.userCollectionErrorSessionMissing},
  );
}

class UserCollectionScreen extends StatelessWidget {
  const UserCollectionScreen({
    super.key,
    required this.repository,
    required this.collection,
    this.reviewRepository,
    this.couponStatus,
    this.highlightCouponCode,
    this.orderPayStatus,
    this.reservationStatus,
  });
  final UserRepository repository;
  final UserCollection collection;
  final ReviewRepository? reviewRepository;
  final int? couponStatus;
  final String? highlightCouponCode;
  final int? orderPayStatus;
  final int? reservationStatus;

  @override
  Widget build(BuildContext context) {
    if (collection == UserCollection.coupons) {
      return CouponsScreen(
        repository: TradeRepository(repository.api),
        initialStatus: couponStatus,
        highlightCode: highlightCouponCode,
      );
    }
    if (collection == UserCollection.orders) {
      return OrdersScreen(
        repository: TradeRepository(repository.api),
        initialPayStatus: orderPayStatus,
      );
    }
    if (collection == UserCollection.reservations) {
      return ReservationsListScreen(
        repository: ReservationRepository(repository.api),
        initialStatus: reservationStatus,
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(collection.localizedLabel(AppLocalizations.of(context))),
      ),
      body: _PaginatedCollectionBody(
        repository: repository,
        collection: collection,
        itemBuilder: (context, item, index) {
          final title = _title(context, item, index);
          final destination = _destination(item);
          return Card(
            child: ListTile(
              title: Text(title),
              subtitle: Text(
                _subtitle(context, item),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: destination == null
                  ? null
                  : const Icon(Icons.chevron_right),
              onTap: destination == null
                  ? null
                  : () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => destination)),
            ),
          );
        },
      ),
    );
  }

  String _title(BuildContext context, Map<String, dynamic> item, int index) {
    if (collection == UserCollection.favorites) {
      final target = item['target'];
      if (target is Map<String, dynamic>) {
        final name = target['name'] as String?;
        if (name != null && name.isNotEmpty) return name;
      }
      final targetType = item['targetType'];
      final targetId = item['targetId'];
      if (targetType == 1) {
        return AppLocalizations.of(context).shopHash(targetId);
      }
      if (targetType == 2) {
        return AppLocalizations.of(context).postHash(targetId);
      }
    }
    return '${item['title'] ?? item['name'] ?? item['orderNo'] ?? item['reservationNo'] ?? item['code'] ?? item['shopName'] ?? item['content'] ?? AppLocalizations.of(context).recordHash(item['id'] ?? index + 1)}';
  }

  Widget? _destination(Map<String, dynamic> item) {
    if (collection == UserCollection.favorites) {
      final targetType = item['targetType'];
      final targetId = item['targetId'];
      if (targetId is! num) return null;
      if (targetType == 1) {
        return ShopDetailScreen(
          repository: ApiBrowseRepository(repository.api),
          shopId: targetId.toInt(),
        );
      }
      if (targetType == 2) {
        return PostDetailScreen(
          repository: CommunityRepository(repository.api),
          postId: targetId.toInt(),
          canInteract: true,
        );
      }
      return null;
    }

    final id = item['id'];
    if (id is! int) return null;
    return switch (collection) {
      UserCollection.reviews when reviewRepository != null =>
        ReviewDetailScreen(
          repository: reviewRepository!,
          reviewId: id,
          owned: true,
          canInteract: false,
        ),
      UserCollection.posts => _postDestination(id, item),
      _ => null,
    };
  }

  Widget _postDestination(int id, Map<String, dynamic> item) {
    final communityRepository = CommunityRepository(repository.api);
    final auditStatus = item['auditStatus'] as int? ?? 0;
    if (auditStatus == 1) {
      return PostDetailScreen(
        repository: communityRepository,
        postId: id,
        canInteract: true,
      );
    }
    return PostEditorScreen(repository: communityRepository, postId: id);
  }

  String _subtitle(BuildContext context, Map<String, dynamic> item) {
    final strings = AppLocalizations.of(context);
    final auditStatus = strings.auditStatusLabel(
      status: (item['auditStatus'] as num?)?.toInt(),
      fallback: item['auditStatusText'] as String?,
    );
    final payStatus = strings.payStatusLabel(
      status: (item['payStatus'] as num?)?.toInt(),
      fallback: item['payStatusText'] as String?,
    );
    final couponStatus = strings.couponStatusLabel(
      status: (item['status'] as num?)?.toInt(),
      fallback: item['statusText'] as String?,
    );
    final reservationStatus = strings.reservationStatusLabel(
      status: (item['status'] as num?)?.toInt(),
      fallback: item['statusText'] as String?,
    );
    final auditRemark = item['auditRemark'] as String? ?? '';
    return switch (collection) {
      UserCollection.reviews => '${item['content'] ?? ''}\n$auditStatus',
      UserCollection.posts => [
        '${item['content'] ?? ''}',
        [
          auditStatus,
          if (auditRemark.isNotEmpty) strings.auditRemarkLabel(auditRemark),
        ].where((part) => part.isNotEmpty).join(' · '),
      ].where((part) => part.isNotEmpty).join('\n'),
      UserCollection.orders =>
        '${item['dealTitle'] ?? ''} · ${item['shopName'] ?? ''} · $payStatus',
      UserCollection.coupons =>
        '${item['dealTitle'] ?? ''} · ${item['shopName'] ?? ''} · $couponStatus · ${item['expireAt'] ?? ''}',
      UserCollection.reservations =>
        '${(item['shop'] as Map<String, dynamic>?)?['name'] ?? ''} · ${item['reserveTime'] ?? ''} · $reservationStatus',
      UserCollection.favorites => _favoriteSubtitle(context, item),
    };
  }

  String _favoriteSubtitle(BuildContext context, Map<String, dynamic> item) {
    final targetType = item['targetType'];
    final createdAt = item['createdAt'] ?? '';
    final target = item['target'];
    if (targetType == 1 && target is Map<String, dynamic>) {
      final location = [
        target['cityName'],
        target['areaName'],
      ].whereType<String>().where((part) => part.isNotEmpty).join(' · ');
      final score = target['score'];
      return [
        AppLocalizations.of(context).shopLabel,
        if (location.isNotEmpty) location,
        if (score != null) '★ $score',
        if ('$createdAt'.isNotEmpty)
          AppLocalizations.of(context).favoritedAt('$createdAt'),
      ].join(' · ');
    }
    if (targetType == 2) {
      return [
        AppLocalizations.of(context).postLabel,
        if ('$createdAt'.isNotEmpty)
          AppLocalizations.of(context).favoritedAt('$createdAt'),
      ].join(' · ');
    }
    return jsonEncode(item);
  }
}

class _PaginatedCollectionBody extends StatefulWidget {
  const _PaginatedCollectionBody({
    required this.repository,
    required this.collection,
    required this.itemBuilder,
  });

  final UserRepository repository;
  final UserCollection collection;
  final Widget Function(BuildContext, Map<String, dynamic>, int) itemBuilder;

  @override
  State<_PaginatedCollectionBody> createState() =>
      _PaginatedCollectionBodyState();
}

class _PaginatedCollectionBodyState extends State<_PaginatedCollectionBody> {
  late Future<UserCollectionPage> _page;
  bool _loadingMore = false;
  bool _retrying = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _page = widget.repository.loadCollection(widget.collection);
  }

  Future<void> _reload() async {
    if (_retrying) return;
    final future = widget.repository.loadCollection(widget.collection);
    _requestId++;
    setState(() {
      _page = future;
      _loadingMore = false;
      _retrying = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  Future<void> _loadMore(UserCollectionPage current) async {
    if (_loadingMore || !current.hasMore) return;
    final requestId = _requestId;
    setState(() => _loadingMore = true);
    try {
      final next = await widget.repository.loadCollection(
        widget.collection,
        page: current.page + 1,
        pageSize: current.pageSize,
      );
      if (!mounted || requestId != _requestId) return;
      final knownIds = current.items.map((item) => item['id']).toSet();
      final items = [
        ...current.items,
        ...next.items.where((item) => knownIds.add(item['id'])),
      ];
      setState(() {
        _page = Future.value(
          UserCollectionPage(
            items: items,
            total: next.total,
            page: next.page,
            pageSize: current.pageSize,
          ),
        );
      });
    } catch (error) {
      if (mounted && requestId == _requestId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).loadMoreFailed(
                _localizedCollectionError(AppLocalizations.of(context), error),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return FutureBuilder<UserCollectionPage>(
      future: _page,
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
                  strings.collectionLoadFailed(
                    _localizedCollectionError(strings, snapshot.error!),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  key: const Key('user-collection-retry'),
                  onPressed: _retrying ? null : _reload,
                  icon: const Icon(Icons.refresh),
                  label: Text(_retrying ? strings.processing : strings.retry),
                ),
              ],
            ),
          );
        }
        final page = snapshot.data!;
        if (page.items.isEmpty) {
          return Center(child: Text(strings.noCollectionData));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: page.items.length + (page.hasMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == page.items.length) {
              return Center(
                child: OutlinedButton.icon(
                  key: const Key('user-collection-load-more'),
                  onPressed: _loadingMore ? null : () => _loadMore(page),
                  icon: _loadingMore
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.expand_more),
                  label: Text(
                    _loadingMore ? strings.loading : strings.loadMore,
                  ),
                ),
              );
            }
            return widget.itemBuilder(context, page.items[index], index);
          },
        );
      },
    );
  }
}
