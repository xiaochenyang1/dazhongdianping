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
  bool savingProfile = false;
  bool sendingBindCode = false;
  bool bindingAccount = false;
  bool updatingPassword = false;

  @override
  void initState() {
    super.initState();
    _profile = _loadProfile();
  }

  Future<UserProfile> _loadProfile() async {
    final profile = await widget.repository.loadProfile();
    if (!mounted) return profile;
    nicknameController.text = profile.nickname;
    avatarController.text = profile.avatar;
    signatureController.text = profile.signature;
    gender = profile.gender;
    return profile;
  }

  void _reloadProfile() {
    final future = _loadProfile();
    setState(() {
      _profile = future;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveProfile() async {
    if (savingProfile) return;
    setState(() => savingProfile = true);
    try {
      final profile = await widget.repository.updateProfile(
        nickname: nicknameController.text.trim(),
        avatar: avatarController.text.trim(),
        gender: gender,
        signature: signatureController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _profile = Future.value(profile);
      });
      widget.onProfileChanged?.call(profile);
      _showMessage('资料已保存');
    } catch (error) {
      if (mounted) _showMessage('保存资料失败：$error');
    } finally {
      if (mounted) setState(() => savingProfile = false);
    }
  }

  Future<void> _sendBindCode() async {
    final account = bindAccountController.text.trim();
    if (account.isEmpty) {
      _showMessage('请先填写${bindType == 'email' ? '邮箱' : '手机号'}');
      return;
    }
    if (sendingBindCode) return;
    setState(() => sendingBindCode = true);
    try {
      final result = await widget.repository.sendBindCode(
        type: bindType,
        account: account,
      );
      if (!mounted) return;
      final mockCode = result.mockCode;
      _showMessage(mockCode.isEmpty ? '验证码已发送' : '验证码已发送（本地验证码：$mockCode）');
    } catch (error) {
      if (mounted) _showMessage('发送验证码失败：$error');
    } finally {
      if (mounted) setState(() => sendingBindCode = false);
    }
  }

  Future<void> _bindAccount() async {
    final account = bindAccountController.text.trim();
    final code = bindCodeController.text.trim();
    if (account.isEmpty || code.isEmpty) {
      _showMessage('请填写账号和验证码');
      return;
    }
    if (bindingAccount) return;
    setState(() => bindingAccount = true);
    try {
      final profile = await widget.repository.bindAccount(
        type: bindType,
        account: account,
        code: code,
      );
      if (!mounted) return;
      bindCodeController.clear();
      setState(() {
        _profile = Future.value(profile);
      });
      widget.onProfileChanged?.call(profile);
      _showMessage('账号已绑定');
    } catch (error) {
      if (mounted) _showMessage('绑定失败：$error');
    } finally {
      if (mounted) setState(() => bindingAccount = false);
    }
  }

  Future<void> _updatePassword(UserProfile profile) async {
    final oldPassword = oldPasswordController.text;
    final newPassword = newPasswordController.text;
    if (profile.hasPassword && oldPassword.isEmpty) {
      _showMessage('请输入旧密码');
      return;
    }
    if (newPassword.isEmpty) {
      _showMessage('请输入新密码');
      return;
    }
    if (newPassword != confirmPasswordController.text) {
      _showMessage('两次输入的新密码不一致');
      return;
    }
    if (updatingPassword) return;
    setState(() => updatingPassword = true);
    try {
      await widget.repository.updatePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      if (!mounted) return;
      oldPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      _showMessage('密码已更新');
    } catch (error) {
      if (mounted) _showMessage('更新密码失败：$error');
    } finally {
      if (mounted) setState(() => updatingPassword = false);
    }
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
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('账户资料加载失败：${snapshot.error}'),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    key: const Key('account-settings-retry'),
                    onPressed: _reloadProfile,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试'),
                  ),
                ],
              ),
            );
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
                  FilledButton(
                    key: const Key('settings-save-profile'),
                    onPressed: savingProfile ? null : _saveProfile,
                    child: Text(savingProfile ? '保存中...' : '保存资料'),
                  ),
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
                        key: const Key('settings-send-bind-code'),
                        onPressed: sendingBindCode ? null : _sendBindCode,
                        child: Text(sendingBindCode ? '发送中...' : '发送验证码'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const Key('settings-confirm-bind'),
                    onPressed: bindingAccount ? null : _bindAccount,
                    child: Text(bindingAccount ? '绑定中...' : '确认绑定'),
                  ),
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
                  FilledButton(
                    key: const Key('settings-update-password'),
                    onPressed: updatingPassword
                        ? null
                        : () => _updatePassword(profile),
                    child: Text(updatingPassword ? '更新中...' : '更新密码'),
                  ),
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
