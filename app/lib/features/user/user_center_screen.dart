import 'package:dazhongdianping_app/features/auth/auth_controller.dart';
import 'package:dazhongdianping_app/features/review/review_repository.dart';
import 'package:dazhongdianping_app/features/user/privacy_overview_screen.dart';
import 'package:dazhongdianping_app/features/user/privacy_repository.dart';
import 'package:dazhongdianping_app/features/user/user_collection_screen.dart';
import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';

class UserCenterScreen extends StatelessWidget {
  const UserCenterScreen({
    super.key,
    required this.repository,
    required this.authController,
    this.onLoggedOut,
    this.onMessages,
    this.onCircles,
  });
  final UserRepository repository;
  final AuthController authController;
  final VoidCallback? onLoggedOut;
  final VoidCallback? onMessages;
  final VoidCallback? onCircles;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          TextButton(
            onPressed: () async {
              await authController.logout();
              onLoggedOut?.call();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('退出'),
          ),
        ],
      ),
      body: FutureBuilder<UserProfile>(
        future: repository.loadProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('用户资料加载失败：${snapshot.error}'));
          }
          final profile = snapshot.data!;
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
              if (onMessages != null)
                ListTile(
                  leading: const Icon(Icons.forum_outlined),
                  title: const Text('我的私信'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onMessages,
                ),
              if (onCircles != null)
                ListTile(
                  leading: const Icon(Icons.groups_2_outlined),
                  title: const Text('我的圈子'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onCircles,
                ),
              ...UserCollection.values.map(
                (collection) => ListTile(
                  title: Text(collection.label),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserCollectionScreen(
                        repository: repository,
                        collection: collection,
                        reviewRepository: collection == UserCollection.reviews
                            ? ReviewRepository(repository.api)
                            : null,
                      ),
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
                      repository: PrivacyRepository(repository.api),
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
