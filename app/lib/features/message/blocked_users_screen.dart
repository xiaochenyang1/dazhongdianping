import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/message/message_error_localizer.dart';
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
    final revision = ++_pageRevision;
    if (_loadingMore) setState(() => _loadingMore = false);
    try {
      final page = await widget.repository.loadBlockedUserPage();
      if (mounted && revision == _pageRevision) {
        setState(() {
          _page = Future.value(page);
        });
      }
    } catch (error) {
      if (mounted && revision == _pageRevision) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).refreshBlockedUsersFailed(
                localizeMessageError(AppLocalizations.of(context), error),
              ),
            ),
          ),
        );
      }
    }
  }

  void _retryInitialLoad() {
    setState(() {
      _pageRevision++;
      _loadingMore = false;
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
      final knownIds = current.items.map((item) => item.id).toSet();
      if (mounted && revision == _pageRevision) {
        setState(() {
          _page = Future.value(
            BlockedUserPage(
              items: [
                ...current.items,
                ...next.items.where((item) => knownIds.add(item.id)),
              ],
              total: next.total,
              page: next.page,
              pageSize: next.pageSize,
            ),
          );
        });
      }
    } catch (error) {
      if (mounted && revision == _pageRevision) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).loadMoreBlockedUsersFailed(
                localizeMessageError(AppLocalizations.of(context), error),
              ),
            ),
          ),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).unblockedUser(user.nickname),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).unblockFailed(
                localizeMessageError(AppLocalizations.of(context), error),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _unblocking.remove(user.id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).blockedUsers)),
    body: FutureBuilder<BlockedUserPage>(
      future: _page,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context).blockedUsersLoadFailed(
                    localizeMessageError(
                      AppLocalizations.of(context),
                      snapshot.error!,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const Key('blocked-users-retry'),
                  onPressed: _retryInitialLoad,
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.of(context).reload),
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
                return Padding(
                  padding: const EdgeInsets.only(top: 120),
                  child: Center(
                    child: Text(AppLocalizations.of(context).blockedUsersEmpty),
                  ),
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
                      label: Text(
                        _loadingMore
                            ? AppLocalizations.of(context).loading
                            : AppLocalizations.of(context).loadMore,
                      ),
                    ),
                  ),
                );
              }
              final user = page.items[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    user.nickname.isEmpty
                        ? AppLocalizations.of(context).anonymousPeer
                        : user.nickname.substring(0, 1),
                  ),
                ),
                title: Text(
                  user.nickname.isEmpty
                      ? AppLocalizations.of(context).userFallback(user.id)
                      : user.nickname,
                ),
                subtitle: user.blockedAt.isEmpty
                    ? null
                    : Text(
                        AppLocalizations.of(context).blockedAt(user.blockedAt),
                      ),
                trailing: TextButton(
                  key: Key('blocked-user-unblock-${user.id}'),
                  onPressed: _unblocking.contains(user.id)
                      ? null
                      : () => _unblock(user),
                  child: Text(
                    _unblocking.contains(user.id)
                        ? AppLocalizations.of(context).processing
                        : AppLocalizations.of(context).unblockUser,
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
