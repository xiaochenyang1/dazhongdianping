import 'dart:convert';

import 'package:dazhongdianping_app/features/review/review_editor_screen.dart';
import 'package:dazhongdianping_app/features/community/community_repository.dart';
import 'package:dazhongdianping_app/features/community/post_editor_screen.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_detail_screen.dart';
import 'package:dazhongdianping_app/features/reservation/reservation_repository.dart';
import 'package:dazhongdianping_app/features/trade/order_detail_screen.dart';
import 'package:dazhongdianping_app/features/trade/trade_repository.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';

class UserCollectionScreen extends StatelessWidget {
  const UserCollectionScreen({
    super.key,
    required this.repository,
    required this.collection,
    this.reviewRepository,
  });
  final UserRepository repository;
  final UserCollection collection;
  final ReviewRepository? reviewRepository;

  @override
  Widget build(BuildContext context) {
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
              final title =
                  item['title'] ??
                  item['name'] ??
                  item['orderNo'] ??
                  item['reservationNo'] ??
                  item['code'] ??
                  item['shopName'] ??
                  item['content'] ??
                  '记录 #${item['id'] ?? index + 1}';
              final destination = _destination(item);
              return Card(
                child: ListTile(
                  title: Text('$title'),
                  subtitle: Text(
                    _subtitle(item),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: destination == null
                      ? null
                      : Icon(
                          collection == UserCollection.reviews
                              ? Icons.edit_outlined
                              : Icons.chevron_right,
                        ),
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

  Widget? _destination(Map<String, dynamic> item) {
    final id = item['id'];
    if (id is! int) return null;
    return switch (collection) {
      UserCollection.reviews
          when reviewRepository != null && item['shopId'] is int =>
        ReviewEditorScreen(
          repository: reviewRepository!,
          reviewId: id,
          shopId: item['shopId'] as int,
          shopName: item['shopName'] as String? ?? '',
          currency: item['currency'] as String? ?? 'CNY',
        ),
      UserCollection.orders => OrderDetailScreen(
        repository: TradeRepository(repository.api),
        orderId: id,
      ),
      UserCollection.coupons => CouponDetailScreen(
        coupon: Coupon.fromJson(item),
      ),
      UserCollection.reservations => ReservationDetailScreen(
        repository: ReservationRepository(repository.api),
        reservationId: id,
      ),
      UserCollection.posts => PostEditorScreen(
        repository: CommunityRepository(repository.api),
        postId: id,
      ),
      _ => null,
    };
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
      _ => jsonEncode(item),
    };
  }
}
