import 'dart:convert';

import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/browse/shop_detail_screen.dart';
import 'package:dazhongdianping_app/features/community/community_repository.dart';
import 'package:dazhongdianping_app/features/community/post_detail_screen.dart';
import 'package:dazhongdianping_app/features/community/post_editor_screen.dart';
import 'package:dazhongdianping_app/features/review/review_detail_screen.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_detail_screen.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/trade/coupons_screen.dart';
import 'package:dazhongdianping_app/features/trade/orders_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';

class UserCollectionScreen extends StatelessWidget {
  const UserCollectionScreen({
    super.key,
    required this.repository,
    required this.collection,
    this.reviewRepository,
    this.couponStatus,
    this.highlightCouponCode,
    this.orderPayStatus,
  });
  final UserRepository repository;
  final UserCollection collection;
  final ReviewRepository? reviewRepository;
  final int? couponStatus;
  final String? highlightCouponCode;
  final int? orderPayStatus;

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
    return Scaffold(
      appBar: AppBar(title: Text(collection.label)),
      body: FutureBuilder<UserCollectionPage>(
        future: repository.loadCollection(collection),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }
          final page = snapshot.data!;
          if (page.items.isEmpty) return const Center(child: Text('暂无数据'));
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: page.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = page.items[index];
              final title = _title(item, index);
              final destination = _destination(item);
              return Card(
                child: ListTile(
                  title: Text(title),
                  subtitle: Text(
                    _subtitle(item),
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
          );
        },
      ),
    );
  }

  String _title(Map<String, dynamic> item, int index) {
    if (collection == UserCollection.favorites) {
      final target = item['target'];
      if (target is Map<String, dynamic>) {
        final name = target['name'] as String?;
        if (name != null && name.isNotEmpty) return name;
      }
      final targetType = item['targetType'];
      final targetId = item['targetId'];
      if (targetType == 1) return '门店 #$targetId';
      if (targetType == 2) return '帖子 #$targetId';
    }
    return '${item['title'] ?? item['name'] ?? item['orderNo'] ?? item['reservationNo'] ?? item['code'] ?? item['shopName'] ?? item['content'] ?? '记录 #${item['id'] ?? index + 1}'}';
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
      UserCollection.reservations => ReservationDetailScreen(
        repository: ReservationRepository(repository.api),
        reservationId: id,
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
    return PostEditorScreen(
      repository: communityRepository,
      postId: id,
    );
  }

  String _subtitle(Map<String, dynamic> item) {
    return switch (collection) {
      UserCollection.reviews =>
        '${item['content'] ?? ''}\n${item['auditStatusText'] ?? ''}',
      UserCollection.posts =>
        '${item['content'] ?? ''}\n${item['auditStatusText'] ?? ''}${item['auditRemark'] == null || item['auditRemark'] == '' ? '' : '：${item['auditRemark']}'}',
      UserCollection.orders =>
        '${item['dealTitle'] ?? ''} · ${item['shopName'] ?? ''} · ${item['payStatusText'] ?? ''}',
      UserCollection.coupons =>
        '${item['dealTitle'] ?? ''} · ${item['shopName'] ?? ''} · ${item['statusText'] ?? ''} · ${item['expireAt'] ?? ''}',
      UserCollection.reservations =>
        '${(item['shop'] as Map<String, dynamic>?)?['name'] ?? ''} · ${item['reserveTime'] ?? ''} · ${item['statusText'] ?? ''}',
      UserCollection.favorites => _favoriteSubtitle(item),
      _ => jsonEncode(item),
    };
  }

  String _favoriteSubtitle(Map<String, dynamic> item) {
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
        '门店',
        if (location.isNotEmpty) location,
        if (score != null) '★ $score',
        if ('$createdAt'.isNotEmpty) '收藏于 $createdAt',
      ].join(' · ');
    }
    if (targetType == 2) {
      return [
        '帖子',
        if ('$createdAt'.isNotEmpty) '收藏于 $createdAt',
      ].join(' · ');
    }
    return jsonEncode(item);
  }
}
