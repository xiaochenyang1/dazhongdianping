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
          return Center(child: Text('用户主页加载失败：${snapshot.error}'));
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

class UserRelationshipsScreen extends StatelessWidget {
  const UserRelationshipsScreen({
    super.key,
    required this.repository,
    required this.userId,
    required this.followers,
  });
  final UserRepository repository;
  final int userId;
  final bool followers;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(followers ? '粉丝' : '关注')),
    body: FutureBuilder<SocialUserPage>(
      future: repository.loadRelationships(userId, followers: followers),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return snapshot.hasError
              ? Center(child: Text('关系列表加载失败：${snapshot.error}'))
              : const Center(child: CircularProgressIndicator());
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final user = snapshot.data!.items[index];
            return Card(
              child: ListTile(
                title: Text(user.nickname),
                subtitle: Text(
                  user.signature.isEmpty
                      ? 'Lv.${user.level} · 粉丝 ${user.followerCount}'
                      : user.signature,
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        );
      },
    ),
  );
}
