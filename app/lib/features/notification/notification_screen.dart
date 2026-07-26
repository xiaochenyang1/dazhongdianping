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
  late Future<NotificationPage> _notifications;
  bool _markingAll = false;
  bool _loadingMore = false;
  bool _reloading = false;
  bool _showUnreadOnly = false;
  int _pageRevision = 0;
  final Set<int> _handlingNotificationIds = {};

  @override
  void initState() {
    super.initState();
    _notifications = widget.repository.loadPage();
  }

  Future<void> _reload() async {
    if (_reloading) return;
    final revision = _pageRevision;
    setState(() => _reloading = true);
    try {
      final page = await widget.repository.loadPage();
      if (mounted && revision == _pageRevision) {
        setState(() {
          _notifications = Future.value(page);
        });
      }
    } catch (error) {
      if (mounted && revision == _pageRevision) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('刷新消息失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _reloading = false);
    }
  }

  Future<void> _loadMore(NotificationPage current) async {
    if (_loadingMore || _markingAll || !current.hasMore) return;
    final revision = _pageRevision;
    setState(() => _loadingMore = true);
    try {
      final next = await widget.repository.loadPage(
        page: current.page + 1,
        pageSize: current.pageSize,
      );
      if (!mounted || revision != _pageRevision) return;
      final knownIds = current.items.map((item) => item.id).toSet();
      final combined = [
        ...current.items,
        ...next.items.where((item) => knownIds.add(item.id)),
      ];
      setState(() {
        _notifications = Future.value(
          NotificationPage(
            items: combined,
            total: next.total,
            page: next.page,
            pageSize: current.pageSize,
          ),
        );
      });
    } catch (error) {
      if (mounted && revision == _pageRevision) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载更多失败：$error')));
      }
    } finally {
      if (mounted && revision == _pageRevision) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _ack(AppNotification notification) async {
    setState(() {
      _pageRevision++;
      _loadingMore = false;
    });
    try {
      final acknowledged = await widget.repository.ack(notification.id);
      if (!mounted) return;
      final page = await _notifications;
      if (!mounted) return;
      setState(() {
        _notifications = Future.value(
          page.copyWith(
            items: page.items
                .map((item) => item.id == acknowledged.id ? acknowledged : item)
                .toList(),
          ),
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

  Future<void> _markAllRead(NotificationPage page) async {
    if (_markingAll || _loadingMore) return;
    final hasUnread = page.items.any((item) => !item.read);
    if (!hasUnread) return;
    setState(() {
      _pageRevision++;
      _markingAll = true;
    });
    try {
      await widget.repository.markAllRead();
      if (!mounted) return;
      final latest = await _notifications;
      if (!mounted) return;
      setState(() {
        _notifications = Future.value(
          latest.copyWith(
            items: latest.items
                .map(
                  (item) => AppNotification(
                    id: item.id,
                    type: item.type,
                    actorUserId: item.actorUserId,
                    actorName: item.actorName,
                    title: item.title,
                    content: item.content,
                    linkUrl: item.linkUrl,
                    aggregateCount: item.aggregateCount,
                    read: true,
                    createdAt: item.createdAt,
                  ),
                )
                .toList(),
          ),
        );
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('全部通知已标记为已读')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('全部已读失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _handleTap(AppNotification notification) async {
    if (_handlingNotificationIds.contains(notification.id)) return;
    setState(() => _handlingNotificationIds.add(notification.id));
    try {
      if (!notification.read) {
        await _ack(notification);
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
      final postId = postMatch == null
          ? null
          : int.tryParse(postMatch.group(1)!);
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
    } finally {
      if (mounted) {
        setState(() => _handlingNotificationIds.remove(notification.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息通知'),
        actions: [
          FutureBuilder<NotificationPage>(
            future: _notifications,
            builder: (context, snapshot) {
              final notifications = snapshot.data?.items ?? const [];
              final unread = notifications.where((item) => !item.read).length;
              return TextButton(
                key: const Key('notifications-mark-all'),
                onPressed: unread == 0 || _markingAll || _loadingMore
                    ? null
                    : () => _markAllRead(snapshot.data!),
                child: Text(
                  _markingAll
                      ? '处理中...'
                      : unread == 0
                      ? '全部已读'
                      : '全部已读（$unread）',
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<bool>(
              key: const Key('notification-read-filter'),
              segments: const [
                ButtonSegment(value: false, label: Text('全部')),
                ButtonSegment(value: true, label: Text('只看未读')),
              ],
              selected: {_showUnreadOnly},
              onSelectionChanged: (selection) {
                setState(() => _showUnreadOnly = selection.first);
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<NotificationPage>(
              future: _notifications,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('消息加载失败：${snapshot.error}'),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          key: const Key('notifications-retry'),
                          onPressed: _reloading ? null : _reload,
                          icon: const Icon(Icons.refresh),
                          label: Text(_reloading ? '处理中...' : '重新加载'),
                        ),
                      ],
                    ),
                  );
                }
                final page = snapshot.data!;
                final notifications = page.items;
                final visible = _showUnreadOnly
                    ? notifications.where((item) => !item.read).toList()
                    : notifications;
                if (visible.isEmpty && !page.hasMore) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_showUnreadOnly ? '暂无未读消息' : '暂无消息'),
                        if (!_showUnreadOnly) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            key: const Key('notifications-empty-refresh'),
                            onPressed: _reloading ? null : _reload,
                            icon: const Icon(Icons.refresh),
                            label: Text(_reloading ? '处理中...' : '刷新'),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    key: const Key('notification-list'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: visible.length + (page.hasMore ? 1 : 0),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == visible.length) {
                        return Center(
                          child: OutlinedButton.icon(
                            key: const Key('notifications-load-more'),
                            onPressed: _loadingMore || _markingAll
                                ? null
                                : () => _loadMore(page),
                            icon: _loadingMore
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.expand_more),
                            label: Text(
                              _loadingMore
                                  ? '加载中...'
                                  : _showUnreadOnly && visible.isEmpty
                                  ? '继续查找未读消息'
                                  : '加载更多',
                            ),
                          ),
                        );
                      }
                      final notification = visible[index];
                      return Card(
                        child: ListTile(
                          key: Key('notification-${notification.id}'),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
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
                          onTap:
                              _handlingNotificationIds.contains(notification.id)
                              ? null
                              : () => _handleTap(notification),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
