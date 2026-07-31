import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';
import 'package:flutter/material.dart';

String _localizedPublicProfileError(AppLocalizations strings, Object error) {
  return localizeAuthError(
    strings,
    error,
    overrides: {
      '用户不存在': strings.publicProfileErrorUserNotFound,
      '用户登录状态不存在': strings.publicProfileErrorSessionMissing,
      '不能关注自己': strings.publicProfileErrorCannotFollowSelf,
    },
  );
}

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
  bool _reloadingProfile = false;
  bool _openingRelationships = false;
  @override
  void initState() {
    super.initState();
    _profile = widget.repository.loadPublicProfile(widget.userId);
  }

  Future<void> _reloadProfile() async {
    if (_reloadingProfile) return;
    final future = widget.repository.loadPublicProfile(widget.userId);
    setState(() {
      _profile = future;
      _visibleProfile = null;
      _saving = false;
      _reloadingProfile = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => _reloadingProfile = false);
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).followStatusUpdateFailed(
                _localizedPublicProfileError(
                  AppLocalizations.of(context),
                  error,
                ),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openRelationships(bool followers) async {
    if (_openingRelationships) return;
    setState(() => _openingRelationships = true);
    try {
      await Navigator.of(context).push(
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
    } finally {
      if (mounted) setState(() => _openingRelationships = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(AppLocalizations.of(context).publicProfile)),
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
                Text(
                  AppLocalizations.of(context).publicProfileLoadFailed(
                    _localizedPublicProfileError(
                      AppLocalizations.of(context),
                      snapshot.error!,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                FilledButton.tonalIcon(
                  key: const Key('public-profile-retry'),
                  onPressed: _reloadingProfile ? null : _reloadProfile,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    _reloadingProfile
                        ? AppLocalizations.of(context).processing
                        : AppLocalizations.of(context).retry,
                  ),
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
            if (AppLocalizations.of(context)
                .certificationBadgeLabel(
                  code: profile.expertCertificationCode,
                  fallback: profile.expertCertificationLabel,
                )
                .isNotEmpty) ...[
              const SizedBox(height: 8),
              Center(
                child: Chip(
                  avatar: const Icon(Icons.verified, size: 16),
                  label: Text(
                    AppLocalizations.of(context).certificationBadgeLabel(
                      code: profile.expertCertificationCode,
                      fallback: profile.expertCertificationLabel,
                    ),
                  ),
                ),
              ),
            ],
            Text(
              profile.signature.isEmpty
                  ? AppLocalizations.of(context).noSignature
                  : profile.signature,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: AppLocalizations.of(context).reviewsMetric,
                    value: '${profile.reviewCount}',
                  ),
                ),
                Expanded(
                  child: InkWell(
                    key: const Key('public-profile-followers'),
                    onTap: _openingRelationships
                        ? null
                        : () => _openRelationships(true),
                    child: _Metric(
                      label: AppLocalizations.of(context).followers,
                      value: '${profile.followerCount}',
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    key: const Key('public-profile-following'),
                    onTap: _openingRelationships
                        ? null
                        : () => _openRelationships(false),
                    child: _Metric(
                      label: AppLocalizations.of(context).followingUsers,
                      value: '${profile.followingCount}',
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 18),
            if (!isSelf && widget.canFollow)
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : () => _toggle(profile),
                      child: Text(
                        profile.followedByCurrentUser
                            ? AppLocalizations.of(context).followed
                            : AppLocalizations.of(context).followingUsers,
                      ),
                    ),
                  ),
                  if (widget.onMessage != null) ...[
                    SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => widget.onMessage!(profile.id),
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: Text(
                          AppLocalizations.of(context).sendDirectMessage,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            if (!isSelf && !widget.canFollow)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(AppLocalizations.of(context).loginToFollowUser),
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
  bool reloading = false;

  @override
  void initState() {
    super.initState();
    page = widget.repository.loadRelationships(
      widget.userId,
      followers: widget.followers,
    );
  }

  Future<void> reload() async {
    if (reloading) return;
    final future = widget.repository.loadRelationships(
      widget.userId,
      followers: widget.followers,
    );
    setState(() {
      page = future;
      loadingMore = false;
      reloading = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => reloading = false);
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).loadMoreUsersFailed(
                _localizedPublicProfileError(
                  AppLocalizations.of(context),
                  error,
                ),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.followers
            ? AppLocalizations.of(context).followers
            : AppLocalizations.of(context).followingUsers,
      ),
    ),
    body: FutureBuilder<SocialUserPage>(
      future: page,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return snapshot.hasError
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AppLocalizations.of(context).relationListLoadFailed(
                          _localizedPublicProfileError(
                            AppLocalizations.of(context),
                            snapshot.error!,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      FilledButton.tonalIcon(
                        key: const Key('relationships-retry'),
                        onPressed: reloading ? null : reload,
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          reloading
                              ? AppLocalizations.of(context).processing
                              : AppLocalizations.of(context).retry,
                        ),
                      ),
                    ],
                  ),
                )
              : const Center(child: CircularProgressIndicator());
        }
        final current = snapshot.data!;
        final items = current.items;
        if (items.isEmpty) {
          return Center(
            child: Text(
              widget.followers
                  ? AppLocalizations.of(context).noFollowers
                  : AppLocalizations.of(context).noFollowing,
            ),
          );
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
                  label: Text(
                    loadingMore
                        ? AppLocalizations.of(context).loading
                        : AppLocalizations.of(context).loadMore,
                  ),
                ),
              );
            }
            final user = items[index];
            return Card(
              child: ListTile(
                title: Text(user.nickname),
                subtitle: Text(
                  [
                    user.signature.isEmpty
                        ? AppLocalizations.of(context).levelFollowersMeta(
                            level: user.level,
                            count: user.followerCount,
                          )
                        : user.signature,
                    if (user.followedAt.isNotEmpty)
                      AppLocalizations.of(context).followedAtLabel(
                        formatDisplayDateTime(
                          user.followedAt,
                          locale: AppLocalizations.of(context).tag,
                        ),
                      ),
                  ].join('\n'),
                ),
                isThreeLine: user.followedAt.isNotEmpty,
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
