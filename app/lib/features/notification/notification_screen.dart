import 'package:dazhongdianping_app/core/app_localizations.dart';
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
  static const _notificationSeparator = ' · ';

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
    final revision = ++_pageRevision;
    setState(() {
      _loadingMore = false;
      _reloading = true;
    });
    try {
      final page = await widget.repository.loadPage();
      if (mounted && revision == _pageRevision) {
        setState(() {
          _notifications = Future.value(page);
        });
      }
    } catch (error) {
      if (mounted && revision == _pageRevision) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).refreshNotificationsFailed(error),
            ),
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).loadMoreFailed(error)),
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).markReadFailed(error)),
          ),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).allNotificationsMarkedRead,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).markAllReadFailed(error),
            ),
          ),
        );
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

  String _localizedNotificationTitle(
    AppLocalizations strings,
    AppNotification notification,
  ) {
    switch (notification.type) {
      case 'social.follow':
        return strings.notificationTitleSocialFollow;
      case 'message.direct':
        return strings.notificationTitleDirectMessage;
      case 'post.audit.result':
        return switch (_notificationQueryValue(notification.linkUrl, 'audit')) {
          'approved' => strings.notificationTitlePostApproved,
          'rejected' => strings.notificationTitlePostRejected,
          _ => notification.title,
        };
      case 'order.paid':
        return strings.notificationTitleOrderPaid;
      case 'reservation.created':
        return switch (_notificationQueryValue(
          notification.linkUrl,
          'status',
        )) {
          'confirmed' => strings.notificationTitleReservationConfirmed,
          'pending' => strings.notificationTitleReservationSubmitted,
          _ => notification.title,
        };
      case 'coupon.reminder':
        return strings.notificationTitleCouponReminder;
      case 'coupon.verified':
        return strings.notificationTitleCouponVerified;
      case 'review.reply':
        return _canLocalizeMerchantReplyTitle(notification.title)
            ? strings.notificationTitleMerchantReply
            : notification.title;
      case 'expert.certification.result':
        return switch (_notificationQueryValue(
          notification.linkUrl,
          'expert',
        )) {
          'approved' => strings.expertCertificationApprovedNotice,
          'rejected' => strings.expertCertificationRejectedNotice,
          _ => notification.title,
        };
      default:
        return notification.title;
    }
  }

  String _localizedNotificationContent(
    AppLocalizations strings,
    AppNotification notification,
  ) {
    switch (notification.type) {
      case 'social.follow':
        return _localizedSocialFollowContent(strings, notification);
      case 'message.direct':
        return _localizedDirectMessageContent(strings, notification);
      case 'post.audit.result':
        return _localizedPostAuditContent(strings, notification);
      case 'order.paid':
        return _localizedOrderPaidContent(strings, notification);
      case 'reservation.created':
        return _localizedReservationContent(strings, notification);
      case 'coupon.reminder':
        return _localizedCouponReminderContent(strings, notification);
      case 'coupon.verified':
        return _localizedCouponVerifiedContent(strings, notification);
      case 'expert.certification.result':
        return _localizedExpertCertificationContent(strings, notification);
      default:
        return notification.content;
    }
  }

  String _localizedSocialFollowContent(
    AppLocalizations strings,
    AppNotification notification,
  ) {
    final actorName = notification.actorName.trim();
    if (actorName.isEmpty) {
      return notification.content;
    }
    return strings.notificationFollowedYou(actorName);
  }

  String _localizedDirectMessageContent(
    AppLocalizations strings,
    AppNotification notification,
  ) {
    final namedPreview = _extractNamedPreview(notification.content);
    final actorName = notification.actorName.trim().isNotEmpty
        ? notification.actorName.trim()
        : namedPreview?.name;
    final preview = namedPreview?.preview;
    if (actorName == null ||
        actorName.isEmpty ||
        preview == null ||
        preview.isEmpty) {
      return notification.content;
    }
    return strings.notificationDirectMessagePreview(
      name: actorName,
      preview: preview,
    );
  }

  String _localizedPostAuditContent(
    AppLocalizations strings,
    AppNotification notification,
  ) {
    final parsed = _extractPostAuditContent(notification.content);
    if (parsed == null) {
      return notification.content;
    }
    return switch (_notificationQueryValue(notification.linkUrl, 'audit')) {
      'approved' => strings.notificationPostApprovedContent(
        parsed.title,
        remark: parsed.remark,
      ),
      'rejected' => strings.notificationPostRejectedContent(
        parsed.title,
        remark: parsed.remark,
      ),
      _ => notification.content,
    };
  }

  String _localizedOrderPaidContent(
    AppLocalizations strings,
    AppNotification notification,
  ) {
    final segments = _notificationSegments(notification.content);
    if (segments.isEmpty) {
      return notification.content;
    }
    final localized = <String>[];
    for (final segment in segments) {
      final orderNo = _extractOrderNumber(segment);
      if (orderNo != null && orderNo.isNotEmpty) {
        localized.add(strings.notificationOrderNumber(orderNo));
        continue;
      }
      if (segment == '券码已发放，可在我的券查看') {
        localized.add(strings.notificationCouponsReady);
        continue;
      }
      localized.add(segment);
    }
    return localized.join(_notificationSeparator);
  }

  String _localizedReservationContent(
    AppLocalizations strings,
    AppNotification notification,
  ) {
    final segments = _notificationSegments(notification.content);
    if (segments.isEmpty) {
      return notification.content;
    }
    final reservationStatus = _notificationQueryValue(
      notification.linkUrl,
      'status',
    );
    final localized = <String>[];
    for (var index = 0; index < segments.length; index += 1) {
      final segment = segments[index];
      final peopleCount = _extractPeopleCount(segment);
      if (peopleCount != null) {
        localized.add(strings.peopleCount(peopleCount));
        continue;
      }
      final isLastSegment = index == segments.length - 1;
      if (isLastSegment && reservationStatus == 'confirmed') {
        localized.add(strings.notificationReservationAutoConfirmedAction);
        continue;
      }
      if (isLastSegment && reservationStatus == 'pending') {
        localized.add(strings.notificationReservationSubmittedAction);
        continue;
      }
      localized.add(segment);
    }
    return localized.join(_notificationSeparator);
  }

  String _localizedCouponReminderContent(
    AppLocalizations strings,
    AppNotification notification,
  ) {
    final expiring = _extractCouponExpiringInDays(notification.content);
    if (expiring != null) {
      return strings.notificationCouponExpiringInDays(
        code: expiring.code,
        days: expiring.days,
      );
    }
    final segments = _notificationSegments(notification.content);
    if (segments.isEmpty) {
      return notification.content;
    }
    final localized = <String>[];
    for (final segment in segments) {
      final expiryDate = _extractExpiryDate(segment);
      if (expiryDate != null && expiryDate.isNotEmpty) {
        localized.add(strings.validUntilDate(expiryDate));
        continue;
      }
      final couponCode = _extractCouponCode(segment);
      if (couponCode != null && couponCode.isNotEmpty) {
        localized.add(strings.notificationCouponCodeLabel(couponCode));
        continue;
      }
      localized.add(segment);
    }
    return localized.join(_notificationSeparator);
  }

  String _localizedCouponVerifiedContent(
    AppLocalizations strings,
    AppNotification notification,
  ) {
    final redeemedAt = _extractCouponRedeemedAt(notification.content);
    if (redeemedAt != null) {
      return strings.notificationCouponRedeemedAt(
        code: redeemedAt.code,
        shop: redeemedAt.shop,
      );
    }
    final segments = _notificationSegments(notification.content);
    if (segments.isEmpty) {
      return notification.content;
    }
    final localized = <String>[];
    for (final segment in segments) {
      final redeemedCode = _extractRedeemedCouponCode(segment);
      if (redeemedCode != null && redeemedCode.isNotEmpty) {
        localized.add(strings.notificationCouponCodeLabel(redeemedCode));
        localized.add(strings.notificationCouponRedeemed);
        continue;
      }
      localized.add(segment);
    }
    return localized.join(_notificationSeparator);
  }

  String _localizedExpertCertificationContent(
    AppLocalizations strings,
    AppNotification notification,
  ) {
    final remark = _extractNotificationRemark(notification.content);
    return switch (_notificationQueryValue(notification.linkUrl, 'expert')) {
      'approved' => _appendLocalizedNotificationRemark(
        strings,
        strings.notificationExpertApprovedContent,
        remark,
      ),
      'rejected' => _appendLocalizedNotificationRemark(
        strings,
        strings.notificationExpertRejectedContent,
        remark,
      ),
      _ => notification.content,
    };
  }

  String _appendLocalizedNotificationRemark(
    AppLocalizations strings,
    String base,
    String? remark,
  ) {
    if (remark == null || remark.trim().isEmpty) {
      return base;
    }
    final separator = strings.tag.startsWith('en') ? ': ' : '：';
    return '$base$separator${remark.trim()}';
  }

  String? _notificationQueryValue(String linkUrl, String key) {
    final uri = Uri.tryParse(linkUrl);
    final value = uri?.queryParameters[key]?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  List<String> _notificationSegments(String content) => content
      .split(_notificationSeparator)
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty)
      .toList();

  bool _canLocalizeMerchantReplyTitle(String title) {
    final normalized = title.trim();
    return normalized.isEmpty ||
        normalized == '商家回复' ||
        normalized == '商家回复了你的点评' ||
        normalized == '商家回覆' ||
        normalized == '商家回覆了你的點評' ||
        normalized == 'Merchant reply';
  }

  ({String name, String preview})? _extractNamedPreview(String content) {
    final match = RegExp(r'^(.+?)[：:]\s*(.+)$').firstMatch(content.trim());
    final name = match?.group(1)?.trim();
    final preview = match?.group(2)?.trim();
    if (name == null || name.isEmpty || preview == null || preview.isEmpty) {
      return null;
    }
    return (name: name, preview: preview);
  }

  ({String title, String? remark})? _extractPostAuditContent(String content) {
    final match = RegExp(
      r'^《(.+?)》\s*(?:已公开|已公開|未通过审核|未通過審核)(?:：(.+))?$',
    ).firstMatch(content.trim());
    final title = match?.group(1)?.trim();
    if (title == null || title.isEmpty) {
      return null;
    }
    return (title: title, remark: match?.group(2)?.trim());
  }

  String? _extractOrderNumber(String segment) {
    final match = RegExp(r'^订单\s+(.+)$').firstMatch(segment);
    return match?.group(1)?.trim();
  }

  int? _extractPeopleCount(String segment) {
    final match = RegExp(r'^(\d+)\s*(?:人|位)$').firstMatch(segment);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  ({String code, int days})? _extractCouponExpiringInDays(String content) {
    final match = RegExp(
      r'^(.+?)\s+将在\s+(\d+)\s+天后过期$',
    ).firstMatch(content.trim());
    final code = match?.group(1)?.trim();
    final days = match == null ? null : int.tryParse(match.group(2)!);
    if (code == null || code.isEmpty || days == null) {
      return null;
    }
    return (code: code, days: days);
  }

  String? _extractExpiryDate(String segment) {
    final match = RegExp(r'^有效期至\s+(.+)$').firstMatch(segment);
    return match?.group(1)?.trim();
  }

  String? _extractCouponCode(String segment) {
    final match = RegExp(r'^券码\s+(.+)$').firstMatch(segment);
    return match?.group(1)?.trim();
  }

  ({String code, String shop})? _extractCouponRedeemedAt(String content) {
    final match = RegExp(
      r'^(.+?)\s+已在\s*(.+?)\s*核销$',
    ).firstMatch(content.trim());
    final code = match?.group(1)?.trim();
    final shop = match?.group(2)?.trim();
    if (code == null || code.isEmpty || shop == null || shop.isEmpty) {
      return null;
    }
    return (code: code, shop: shop);
  }

  String? _extractRedeemedCouponCode(String segment) {
    final match = RegExp(r'^券码\s+(.+?)\s+已核销成功$').firstMatch(segment.trim());
    return match?.group(1)?.trim();
  }

  String? _extractNotificationRemark(String content) {
    final index = content.indexOf('：');
    if (index < 0) {
      return null;
    }
    final remark = content.substring(index + 1).trim();
    return remark.isEmpty ? null : remark;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.notifications),
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
                      ? strings.processing
                      : unread == 0
                      ? strings.markAllRead
                      : strings.markAllReadWithCount(unread),
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
              segments: [
                ButtonSegment(value: false, label: Text(strings.filterAll)),
                ButtonSegment(
                  value: true,
                  label: Text(strings.filterUnreadOnly),
                ),
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
                        Text(strings.notificationsLoadFailed(snapshot.error!)),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          key: const Key('notifications-retry'),
                          onPressed: _reloading ? null : _reload,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            _reloading ? strings.processing : strings.reload,
                          ),
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
                        Text(
                          _showUnreadOnly
                              ? strings.noUnreadNotifications
                              : strings.noNotifications,
                        ),
                        if (!_showUnreadOnly) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            key: const Key('notifications-empty-refresh'),
                            onPressed: _reloading ? null : _reload,
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              _reloading ? strings.processing : strings.refresh,
                            ),
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
                                  ? strings.loading
                                  : _showUnreadOnly && visible.isEmpty
                                  ? strings.continueFindUnread
                                  : strings.loadMore,
                            ),
                          ),
                        );
                      }
                      final notification = visible[index];
                      final localizedTitle = _localizedNotificationTitle(
                        strings,
                        notification,
                      );
                      final localizedContent = _localizedNotificationContent(
                        strings,
                        notification,
                      );
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
                                  localizedTitle,
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
                                Text(
                                  strings.unreadBadge,
                                  style: const TextStyle(
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
                                Text(localizedContent),
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
