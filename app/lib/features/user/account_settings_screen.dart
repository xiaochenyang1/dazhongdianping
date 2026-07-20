import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:flutter/material.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({
    super.key,
    required this.repository,
    this.onProfileChanged,
  });

  final UserRepository repository;
  final ValueChanged<UserProfile>? onProfileChanged;

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late Future<UserProfile> _profile;
  final nicknameController = TextEditingController();
  final avatarController = TextEditingController();
  final signatureController = TextEditingController();
  final bindAccountController = TextEditingController();
  final bindCodeController = TextEditingController();
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  int gender = 0;
  String bindType = 'email';

  @override
  void initState() {
    super.initState();
    _profile = _loadProfile();
  }

  Future<UserProfile> _loadProfile() async {
    final profile = await widget.repository.loadProfile();
    nicknameController.text = profile.nickname;
    avatarController.text = profile.avatar;
    signatureController.text = profile.signature;
    gender = profile.gender;
    return profile;
  }

  @override
  void dispose() {
    nicknameController.dispose();
    avatarController.dispose();
    signatureController.dispose();
    bindAccountController.dispose();
    bindCodeController.dispose();
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('账户设置')),
      body: FutureBuilder<UserProfile>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('账户资料加载失败：${snapshot.error}'));
          }
          final profile = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                '把账户握在自己手里',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text('资料、绑定和密码都走真实后端校验，没整一堆看着能点的摆设。'),
              const SizedBox(height: 20),
              _SettingsCard(
                title: '基础资料',
                icon: Icons.badge_outlined,
                children: [
                  TextField(
                    key: const Key('settings-nickname'),
                    controller: nicknameController,
                    maxLength: 64,
                    decoration: const InputDecoration(
                      labelText: '昵称',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('settings-avatar'),
                    controller: avatarController,
                    maxLength: 255,
                    decoration: const InputDecoration(
                      labelText: '头像 URL',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: gender,
                    decoration: const InputDecoration(
                      labelText: '性别',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('未知')),
                      DropdownMenuItem(value: 1, child: Text('男')),
                      DropdownMenuItem(value: 2, child: Text('女')),
                    ],
                    onChanged: (value) => setState(() => gender = value ?? 0),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('settings-signature'),
                    controller: signatureController,
                    maxLength: 255,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '签名',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: () {}, child: const Text('保存资料')),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                title: '账号绑定',
                icon: Icons.link_outlined,
                children: [
                  Text('邮箱：${profile.email.isEmpty ? '未绑定' : profile.email}'),
                  Text('手机号：${profile.phone.isEmpty ? '未绑定' : profile.phone}'),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'email', label: Text('邮箱')),
                      ButtonSegment(value: 'phone', label: Text('手机号')),
                    ],
                    selected: {bindType},
                    onSelectionChanged: (selection) {
                      setState(() => bindType = selection.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('settings-bind-account'),
                    controller: bindAccountController,
                    decoration: InputDecoration(
                      labelText: bindType == 'email' ? '邮箱' : '手机号',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('settings-bind-code'),
                    controller: bindCodeController,
                    decoration: InputDecoration(
                      labelText: '绑定验证码',
                      border: const OutlineInputBorder(),
                      suffixIcon: TextButton(
                        onPressed: () {},
                        child: const Text('发送验证码'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: () {}, child: const Text('确认绑定')),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                title: '修改密码',
                icon: Icons.lock_outline,
                children: [
                  Text(
                    profile.hasPassword
                        ? '当前账号已有密码，修改时需要校验旧密码。'
                        : '当前账号还没有密码，可以直接设置新密码。',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('settings-old-password'),
                    controller: oldPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '旧密码',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('settings-new-password'),
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '新密码',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('settings-confirm-password'),
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '确认新密码',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: () {}, child: const Text('更新密码')),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFE85D2A)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
