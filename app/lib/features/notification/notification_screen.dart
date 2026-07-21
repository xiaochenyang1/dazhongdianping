import 'package:dazhongdianping_app/features/notification/notification_repository.dart';
import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({
    super.key,
    required this.repository,
    this.onUserTap,
    this.onPostTap,
    this.onConversationTap,
  });

  final NotificationRepository repository;
  final ValueChanged<int>? onUserTap;
  final ValueChanged<int>? onPostTap;
  final void Function(int conversationId, int? peerUserId, String peerName)?
  onConversationTap;

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
    final postMatch = RegExp(
      r'^/community/posts/(\d+)$',
    ).firstMatch(notification.linkUrl);
    final postId = postMatch == null ? null : int.tryParse(postMatch.group(1)!);
    if (postId != null) {
      widget.onPostTap?.call(postId);
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
