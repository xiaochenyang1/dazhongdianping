import 'package:dazhongdianping_app/features/notification/notification_repository.dart';
import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({
    super.key,
    required this.repository,
    this.onUserTap,
    this.onPostTap,
    this.onConversationTap,
    this.onOrderTap,
    this.onReservationTap,
    this.onReviewTap,
    this.onCouponListTap,
    this.onCouponDetailTap,
    this.onExpertCertificationTap,
  });

  final NotificationRepository repository;
  final ValueChanged<int>? onUserTap;
  final ValueChanged<int>? onPostTap;
  final void Function(int conversationId, int? peerUserId, String peerName)?
  onConversationTap;
  final ValueChanged<int>? onOrderTap;
  final ValueChanged<int>? onReservationTap;
  final void Function(int reviewId, {required bool owned})? onReviewTap;
  final void Function({int? status, String? code})? onCouponListTap;
  final ValueChanged<String>? onCouponDetailTap;
  final ValueChanged<String?>? onExpertCertificationTap;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late Future<List<AppNotification>> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = widget.repository.load();
  }

  Future<void> _ack(
    AppNotification notification,
    List<AppNotification> notifications,
  ) async {
    try {
      final acknowledged = await widget.repository.ack(notification.id);
      if (!mounted) return;
      setState(() {
        _notifications = Future.value(
          notifications
              .map((item) => item.id == acknowledged.id ? acknowledged : item)
              .toList(),
        );
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('标记已读失败：$error')));
      }
    }
  }

  Future<void> _handleTap(
    AppNotification notification,
    List<AppNotification> notifications,
  ) async {
    if (!notification.read) {
      await _ack(notification, notifications);
    }
    final match = RegExp(r'^/users/(\d+)$').firstMatch(notification.linkUrl);
    final userId = match == null ? null : int.tryParse(match.group(1)!);
    if (notification.type == 'social.follow' && userId != null) {
      widget.onUserTap?.call(userId);
      return;
    }
    // Accept optional query markers such as ?audit=approved/rejected.
    final postMatch = RegExp(
      r'^/community/posts/(\d+)(?:\?.*)?$',
    ).firstMatch(notification.linkUrl);
    final postId = postMatch == null ? null : int.tryParse(postMatch.group(1)!);
    if (postId != null) {
      widget.onPostTap?.call(postId);
      return;
    }
    final orderMatch = RegExp(
      r'^/user/orders/(\d+)(?:\?.*)?$',
    ).firstMatch(notification.linkUrl);
    final orderId = orderMatch == null
        ? null
        : int.tryParse(orderMatch.group(1)!);
    if (orderId != null) {
      widget.onOrderTap?.call(orderId);
      return;
    }
    final ownedReviewMatch = RegExp(
      r'^/user/reviews/(\d+)(?:\?.*)?$',
    ).firstMatch(notification.linkUrl);
    final ownedReviewId = ownedReviewMatch == null
        ? null
        : int.tryParse(ownedReviewMatch.group(1)!);
    if (ownedReviewId != null) {
      widget.onReviewTap?.call(ownedReviewId, owned: true);
      return;
    }
    final publicReviewMatch = RegExp(
      r'^/reviews/(\d+)(?:\?.*)?$',
    ).firstMatch(notification.linkUrl);
    final publicReviewId = publicReviewMatch == null
        ? null
        : int.tryParse(publicReviewMatch.group(1)!);
    if (publicReviewId != null) {
      widget.onReviewTap?.call(publicReviewId, owned: false);
      return;
    }
    final couponDetailMatch = RegExp(
      r'^/user/coupons/([^?]+)$',
    ).firstMatch(notification.linkUrl);
    if (couponDetailMatch != null) {
      final code = Uri.decodeComponent(couponDetailMatch.group(1)!);
      if (code.isNotEmpty && code != 'coupons') {
        widget.onCouponDetailTap?.call(code);
        return;
      }
    }
    final couponListMatch = RegExp(
      r'^/user/coupons(?:\?(.*))?$',
    ).firstMatch(notification.linkUrl);
    if (couponListMatch != null) {
      final query = Uri.splitQueryString(couponListMatch.group(1) ?? '');
      final statusRaw = query['status'];
      final status = statusRaw == null ? null : int.tryParse(statusRaw);
      widget.onCouponListTap?.call(status: status, code: query['code']);
      return;
    }
    final expertMatch = RegExp(
      r'^/user/profile(?:\?(.*))?$',
    ).firstMatch(notification.linkUrl);
    if (expertMatch != null ||
        notification.type == 'expert.certification.result') {
      final query = Uri.splitQueryString(expertMatch?.group(1) ?? '');
      widget.onExpertCertificationTap?.call(query['expert']);
      return;
    }
    final reservationMatch = RegExp(
      r'^/user/reservations/(\d+)(?:\?.*)?$',
    ).firstMatch(notification.linkUrl);
    final reservationId = reservationMatch == null
        ? null
        : int.tryParse(reservationMatch.group(1)!);
    if (reservationId != null) {
      widget.onReservationTap?.call(reservationId);
      return;
    }
    final conversationMatch = RegExp(
      r'^/messages/conversations/(\d+)$',
    ).firstMatch(notification.linkUrl);
    final conversationId = conversationMatch == null
        ? null
        : int.tryParse(conversationMatch.group(1)!);
    if (notification.type == 'message.direct' && conversationId != null) {
      widget.onConversationTap?.call(
        conversationId,
        notification.actorUserId,
        notification.actorName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('消息通知')),
      body: FutureBuilder<List<AppNotification>>(
        future: _notifications,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('消息加载失败：${snapshot.error}'));
          }
          final notifications = snapshot.data ?? const [];
          if (notifications.isEmpty) {
            return const Center(child: Text('暂无消息'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFFE4D5),
                    foregroundColor: const Color(0xFFB83D16),
                    child: const Icon(Icons.notifications_outlined),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (notification.aggregateCount > 1)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE7DE),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'x${notification.aggregateCount}',
                            style: const TextStyle(
                              color: Color(0xFFB83D16),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      if (!notification.read)
                        const Text(
                          '未读',
                          style: TextStyle(
                            color: Color(0xFFE85D2A),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification.content),
                        const SizedBox(height: 8),
                        Text(
                          notification.createdAt,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  onTap: () => _handleTap(notification, notifications),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
