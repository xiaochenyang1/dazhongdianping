import 'package:dazhongdianping_app/features/message/message_repository.dart';
import 'package:flutter/material.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key, required this.repository});

  final MessageRepository repository;

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  late Future<BlockedUserPage> _page = widget.repository.loadBlockedUserPage();
  bool _loadingMore = false;
  final Set<int> _unblocking = {};
  int _pageRevision = 0;

  Future<void> _reload() async {
    final revision = _pageRevision;
    try {
      final page = await widget.repository.loadBlockedUserPage();
      if (mounted && revision == _pageRevision) {
        setState(() {
          _page = Future.value(page);
        });
      }
    } catch (error) {
      if (mounted && revision == _pageRevision) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('刷新黑名单失败：$error')));
      }
    }
  }

  void _retryInitialLoad() {
    setState(() {
      _page = widget.repository.loadBlockedUserPage();
    });
  }

  Future<void> _loadMore(BlockedUserPage current) async {
    if (_loadingMore || !current.hasMore) return;
    final revision = _pageRevision;
    setState(() => _loadingMore = true);
    try {
      final next = await widget.repository.loadBlockedUserPage(
        page: current.page + 1,
        pageSize: current.pageSize,
      );
      final byId = <int, BlockedUser>{
        for (final item in current.items) item.id: item,
        for (final item in next.items) item.id: item,
      };
      if (mounted && revision == _pageRevision) {
        setState(() {
          _page = Future.value(
            BlockedUserPage(
              items: byId.values.toList(),
              total: next.total,
              page: next.page,
              pageSize: next.pageSize,
            ),
          );
        });
      }
    } catch (error) {
      if (mounted && revision == _pageRevision) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载更多黑名单失败：$error')));
      }
    } finally {
      if (mounted && revision == _pageRevision) {
        setState(() => _loadingMore = false);
      }
    }
  }

  Future<void> _unblock(BlockedUser user) async {
    if (_unblocking.contains(user.id)) return;
    _pageRevision++;
    setState(() {
      _unblocking.add(user.id);
      _loadingMore = false;
    });
    try {
      await widget.repository.unblock(user.id);
      if (mounted) {
        final latest = await _page;
        if (!mounted) return;
        setState(() {
          _page = Future.value(
            BlockedUserPage(
              items: latest.items.where((item) => item.id != user.id).toList(),
              total: latest.total > 0 ? latest.total - 1 : 0,
              page: latest.page,
              pageSize: latest.pageSize,
            ),
          );
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已解除对 ${user.nickname} 的拉黑')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('解除拉黑失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _unblocking.remove(user.id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('黑名单管理')),
    body: FutureBuilder<BlockedUserPage>(
      future: _page,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('黑名单加载失败：${snapshot.error}', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const Key('blocked-users-retry'),
                  onPressed: _retryInitialLoad,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重新加载'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final page = snapshot.data!;
        return RefreshIndicator(
          onRefresh: _reload,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: page.items.isEmpty
                ? 1
                : page.items.length + (page.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (page.items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 120),
                  child: Center(child: Text('黑名单为空')),
                );
              }
              if (index == page.items.length) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Center(
                    child: FilledButton.tonalIcon(
                      onPressed: _loadingMore ? null : () => _loadMore(page),
                      icon: _loadingMore
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.expand_more),
                      label: Text(_loadingMore ? '加载中...' : '加载更多'),
                    ),
                  ),
                );
              }
              final user = page.items[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    user.nickname.isEmpty
                        ? 'TA'
                        : user.nickname.substring(0, 1),
                  ),
                ),
                title: Text(
                  user.nickname.isEmpty ? '用户 ${user.id}' : user.nickname,
                ),
                subtitle: user.blockedAt.isEmpty
                    ? null
                    : Text('拉黑时间：${user.blockedAt}'),
                trailing: TextButton(
                  key: Key('blocked-user-unblock-${user.id}'),
                  onPressed: _unblocking.contains(user.id)
                      ? null
                      : () => _unblock(user),
                  child: Text(
                    _unblocking.contains(user.id) ? '处理中...' : '解除拉黑',
                  ),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}
