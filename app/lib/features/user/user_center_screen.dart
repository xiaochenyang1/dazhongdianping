import 'package:dazhongdianping_app/features/auth/auth_controller.dart';
import 'package:dazhongdianping_app/features/auth/auth_repository.dart';
import 'package:dazhongdianping_app/features/browse/browse_history_screen.dart';
import 'package:dazhongdianping_app/features/browse/browse_repository.dart';
import 'package:dazhongdianping_app/features/message/blocked_users_screen.dart';
import 'package:dazhongdianping_app/features/message/message_repository.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/user/account_settings_screen.dart';
import 'package:dazhongdianping_app/features/user/expert_certification_screen.dart';
import 'package:dazhongdianping_app/features/user/growth_records_screen.dart';
import 'package:dazhongdianping_app/features/user/privacy_overview_screen.dart';
import 'package:dazhongdianping_app/features/user/privacy_repository.dart';
import 'package:dazhongdianping_app/features/user/user_collection_screen.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';

class UserCenterScreen extends StatefulWidget {
  const UserCenterScreen({
    super.key,
    required this.repository,
    required this.authController,
    this.browseRepository,
    this.reviewRepository,
    this.canInteractReviews = false,
    this.onLoggedOut,
    this.onMessages,
    this.onCircles,
  });
  final UserRepository repository;
  final AuthController authController;
  final BrowseRepository? browseRepository;
  final ReviewRepository? reviewRepository;
  final bool canInteractReviews;
  final VoidCallback? onLoggedOut;
  final VoidCallback? onMessages;
  final VoidCallback? onCircles;

  @override
  State<UserCenterScreen> createState() => _UserCenterScreenState();
}

class _UserCenterScreenState extends State<UserCenterScreen> {
  late Future<UserProfile> _profile;
  UserProfile? _profileOverride;
  bool _loggingOut = false;
  bool _reloading = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.repository.loadProfile();
  }

  Future<void> _reload() async {
    if (_reloading) return;
    final future = widget.repository.loadProfile();
    setState(() {
      _profile = future;
      _profileOverride = null;
      _reloading = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => _reloading = false);
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await widget.authController.logout();
      if (!mounted) return;
      widget.onLoggedOut?.call();
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  void _applyProfile(UserProfile updated) {
    widget.authController.replaceCurrentUser(
      AuthUser(
        id: updated.id,
        nickname: updated.nickname,
        avatar: updated.avatar,
        preferredRegion: updated.preferredRegion,
      ),
    );
    if (mounted) {
      setState(() => _profileOverride = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          TextButton(
            key: const Key('user-center-logout'),
            onPressed: _loggingOut ? null : _logout,
            child: Text(_loggingOut ? '退出中...' : '退出'),
          ),
        ],
      ),
      body: FutureBuilder<UserProfile>(
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
                  Text('用户资料加载失败：${snapshot.error}'),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    key: const Key('user-center-retry'),
                    onPressed: _reloading ? null : _reload,
                    icon: const Icon(Icons.refresh),
                    label: Text(_reloading ? '处理中...' : '重试'),
                  ),
                ],
              ),
            );
          }
          final profile = _profileOverride ?? snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        child: Text(profile.nickname.characters.first),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.nickname,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Lv.${profile.level} · ${profile.preferredRegion} · ${profile.points} 积分',
                            ),
                            Text('${profile.growthValue} 成长值'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.manage_accounts_outlined),
                title: const Text('账户设置'),
                subtitle: const Text('资料、绑定账号、修改密码'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AccountSettingsScreen(
                      repository: widget.repository,
                      onProfileChanged: _applyProfile,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.verified_outlined),
                title: const Text('本地达人认证'),
                subtitle: const Text('提交或重提本地达人申请'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ExpertCertificationScreen(
                      repository: widget.repository,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.trending_up),
                title: const Text('成长值流水'),
                subtitle: Text(
                  'Lv.${profile.level} · 成长值 ${profile.growthValue} · 积分 ${profile.points}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        GrowthRecordsScreen(repository: widget.repository),
                  ),
                ),
              ),
              if (widget.onMessages != null)
                ListTile(
                  leading: const Icon(Icons.forum_outlined),
                  title: const Text('我的私信'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: widget.onMessages,
                ),
              ListTile(
                leading: const Icon(Icons.block_outlined),
                title: const Text('黑名单管理'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlockedUsersScreen(
                      repository: MessageRepository(widget.repository.api),
                    ),
                  ),
                ),
              ),
              if (widget.onCircles != null)
                ListTile(
                  leading: const Icon(Icons.groups_2_outlined),
                  title: const Text('我的圈子'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: widget.onCircles,
                ),
              ...UserCollection.values.map(
                (collection) => ListTile(
                  title: Text(collection.label),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserCollectionScreen(
                        repository: widget.repository,
                        collection: collection,
                        reviewRepository: collection == UserCollection.reviews
                            ? ReviewRepository(widget.repository.api)
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.browseRepository != null)
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('我的足迹'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BrowseHistoryScreen(
                        repository: widget.browseRepository!,
                        reviewRepository: widget.reviewRepository,
                        canInteractReviews: widget.canInteractReviews,
                      ),
                    ),
                  ),
                ),
              ListTile(
                title: const Text('隐私中心'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PrivacyOverviewScreen(
                      repository: PrivacyRepository(widget.repository.api),
                      accounts: [
                        profile.email,
                        profile.phone,
                      ].where((account) => account.isNotEmpty).toList(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
