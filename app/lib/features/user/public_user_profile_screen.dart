import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';

class PublicUserProfileScreen extends StatefulWidget {
  const PublicUserProfileScreen({
    super.key,
    required this.repository,
    required this.userId,
    required this.canFollow,
    this.currentUserId,
    this.onMessage,
  });
  final UserRepository repository;
  final int userId;
  final bool canFollow;
  final int? currentUserId;
  final ValueChanged<int>? onMessage;
  @override
  State<PublicUserProfileScreen> createState() =>
      _PublicUserProfileScreenState();
}

class _PublicUserProfileScreenState extends State<PublicUserProfileScreen> {
  late Future<PublicUserProfile> _profile;
  PublicUserProfile? _visibleProfile;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _profile = widget.repository.loadPublicProfile(widget.userId);
  }

  void _reloadProfile() {
    final future = widget.repository.loadPublicProfile(widget.userId);
    setState(() {
      _profile = future;
      _visibleProfile = null;
      _saving = false;
    });
  }

  Future<void> _toggle(PublicUserProfile profile) async {
    if (_saving) return;
    final previous = profile;
    final optimisticFollowing = !profile.followedByCurrentUser;
    setState(() {
      _saving = true;
      _visibleProfile = profile.withFollow(
        following: optimisticFollowing,
        followers: profile.followerCount + (optimisticFollowing ? 1 : -1),
      );
    });
    try {
      final result = optimisticFollowing
          ? await widget.repository.follow(widget.userId)
          : await widget.repository.unfollow(widget.userId);
      if (mounted) {
        setState(
          () => _visibleProfile = profile.withFollow(
            following: result.following,
            followers: result.followerCount,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _visibleProfile = previous);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('关注状态更新失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openRelationships(bool followers) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => UserRelationshipsScreen(
        repository: widget.repository,
        userId: widget.userId,
        followers: followers,
        canFollow: widget.canFollow,
        currentUserId: widget.currentUserId,
        onMessage: widget.onMessage,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('公开主页')),
    body: FutureBuilder<PublicUserProfile>(
      future: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('用户主页加载失败：${snapshot.error}'),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  key: const Key('public-profile-retry'),
                  onPressed: _reloadProfile,
                  icon: const Icon(Icons.refresh),
                  label: const Text('重试'),
                ),
              ],
            ),
          );
        }
        final profile = _visibleProfile ?? snapshot.data!;
        final isSelf = widget.currentUserId == profile.id;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CircleAvatar(
              radius: 38,
              child: Text(
                profile.nickname.isEmpty
                    ? 'TA'
                    : profile.nickname.substring(0, 1),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              profile.nickname,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
            ),
            if (profile.expertCertificationLabel != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Chip(
                  avatar: const Icon(Icons.verified, size: 16),
                  label: Text(profile.expertCertificationLabel!),
                ),
              ),
            ],
            Text(
              profile.signature.isEmpty ? '暂未填写签名' : profile.signature,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _Metric(label: '点评', value: '${profile.reviewCount}'),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _openRelationships(true),
                    child: _Metric(
                      label: '粉丝',
                      value: '${profile.followerCount}',
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => _openRelationships(false),
                    child: _Metric(
                      label: '关注',
                      value: '${profile.followingCount}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (!isSelf && widget.canFollow)
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : () => _toggle(profile),
                      child: Text(profile.followedByCurrentUser ? '已关注' : '关注'),
                    ),
                  ),
                  if (widget.onMessage != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => widget.onMessage!(profile.id),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('发私信'),
                      ),
                    ),
                  ],
                ],
              ),
            if (!isSelf && !widget.canFollow)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('登录后可以关注这位用户。'),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Column(
      children: [
        Text(
          '$label $value',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class UserRelationshipsScreen extends StatefulWidget {
  const UserRelationshipsScreen({
    super.key,
    required this.repository,
    required this.userId,
    required this.followers,
    this.canFollow = false,
    this.currentUserId,
    this.onMessage,
  });
  final UserRepository repository;
  final int userId;
  final bool followers;
  final bool canFollow;
  final int? currentUserId;
  final ValueChanged<int>? onMessage;

  @override
  State<UserRelationshipsScreen> createState() =>
      _UserRelationshipsScreenState();
}

class _UserRelationshipsScreenState extends State<UserRelationshipsScreen> {
  late Future<SocialUserPage> page;
  bool loadingMore = false;

  @override
  void initState() {
    super.initState();
    page = widget.repository.loadRelationships(
      widget.userId,
      followers: widget.followers,
    );
  }

  void reload() {
    final future = widget.repository.loadRelationships(
      widget.userId,
      followers: widget.followers,
    );
    setState(() {
      page = future;
      loadingMore = false;
    });
  }

  Future<void> loadMore(SocialUserPage current) async {
    if (loadingMore || !current.hasMore) return;
    setState(() => loadingMore = true);
    try {
      final next = await widget.repository.loadRelationships(
        widget.userId,
        followers: widget.followers,
        page: current.page + 1,
        pageSize: current.pageSize,
      );
      if (!mounted) return;
      final knownIds = current.items.map((user) => user.id).toSet();
      setState(() {
        page = Future.value(
          SocialUserPage(
            items: [
              ...current.items,
              ...next.items.where((user) => knownIds.add(user.id)),
            ],
            total: next.total,
            page: next.page,
            pageSize: current.pageSize,
          ),
        );
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('加载更多用户失败：$error')));
      }
    } finally {
      if (mounted) setState(() => loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.followers ? '粉丝' : '关注')),
    body: FutureBuilder<SocialUserPage>(
      future: page,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return snapshot.hasError
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('关系列表加载失败：${snapshot.error}'),
                      const SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        key: const Key('relationships-retry'),
                        onPressed: reload,
                        icon: const Icon(Icons.refresh),
                        label: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : const Center(child: CircularProgressIndicator());
        }
        final current = snapshot.data!;
        final items = current.items;
        if (items.isEmpty) {
          return Center(child: Text(widget.followers ? '暂无粉丝' : '暂无关注'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length + (current.hasMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index == items.length) {
              return Center(
                child: OutlinedButton.icon(
                  key: const Key('relationships-load-more'),
                  onPressed: loadingMore ? null : () => loadMore(current),
                  icon: loadingMore
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.expand_more),
                  label: Text(loadingMore ? '加载中...' : '加载更多'),
                ),
              );
            }
            final user = items[index];
            return Card(
              child: ListTile(
                title: Text(user.nickname),
                subtitle: Text(
                  user.signature.isEmpty
                      ? 'Lv.${user.level} · 粉丝 ${user.followerCount}'
                      : user.signature,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PublicUserProfileScreen(
                      repository: widget.repository,
                      userId: user.id,
                      canFollow: widget.canFollow,
                      currentUserId: widget.currentUserId,
                      onMessage: widget.onMessage,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
