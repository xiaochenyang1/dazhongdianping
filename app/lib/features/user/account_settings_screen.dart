import 'package:dazhongdianping_app/core/app_localizations.dart';
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
  bool reloadingProfile = false;

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

  Future<void> _reloadProfile() async {
    if (reloadingProfile) return;
    final future = _loadProfile();
    setState(() {
      _profile = future;
      reloadingProfile = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => reloadingProfile = false);
    }
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
      _showMessage(AppLocalizations.of(context).profileSaved);
    } catch (error) {
      if (mounted) _showMessage(AppLocalizations.of(context).saveProfileFailed(error));
    } finally {
      if (mounted) setState(() => savingProfile = false);
    }
  }

  Future<void> _sendBindCode() async {
    final account = bindAccountController.text.trim();
    if (account.isEmpty) {
      _showMessage(AppLocalizations.of(context).fillTargetFirst(bindType == 'email' ? AppLocalizations.of(context).email : AppLocalizations.of(context).phone));
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
      _showMessage(mockCode.isEmpty ? AppLocalizations.of(context).codeSent : AppLocalizations.of(context).codeSentWithLocal(mockCode));
    } catch (error) {
      if (mounted) _showMessage(AppLocalizations.of(context).sendCodeFailed(error));
    } finally {
      if (mounted) setState(() => sendingBindCode = false);
    }
  }

  Future<void> _bindAccount() async {
    final account = bindAccountController.text.trim();
    final code = bindCodeController.text.trim();
    if (account.isEmpty || code.isEmpty) {
      _showMessage(AppLocalizations.of(context).fillAccountAndCode);
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
      _showMessage(AppLocalizations.of(context).accountBound);
    } catch (error) {
      if (mounted) _showMessage(AppLocalizations.of(context).bindFailed(error));
    } finally {
      if (mounted) setState(() => bindingAccount = false);
    }
  }

  Future<void> _updatePassword(UserProfile profile) async {
    final oldPassword = oldPasswordController.text;
    final newPassword = newPasswordController.text;
    if (profile.hasPassword && oldPassword.isEmpty) {
      _showMessage(AppLocalizations.of(context).enterOldPassword);
      return;
    }
    if (newPassword.isEmpty) {
      _showMessage(AppLocalizations.of(context).enterNewPassword);
      return;
    }
    if (newPassword != confirmPasswordController.text) {
      _showMessage(AppLocalizations.of(context).newPasswordsDoNotMatch);
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
      _showMessage(AppLocalizations.of(context).passwordUpdated);
    } catch (error) {
      if (mounted) _showMessage(AppLocalizations.of(context).updatePasswordFailed(error));
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
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.accountSettings)),
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
                  Text(strings.accountProfileLoadFailed(snapshot.error!)),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    key: const Key('account-settings-retry'),
                    onPressed: reloadingProfile ? null : _reloadProfile,
                    icon: const Icon(Icons.refresh),
                    label: Text(reloadingProfile ? strings.processing : strings.retry),
                  ),
                ],
              ),
            );
          }
          final profile = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                strings.accountSettingsHero,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(strings.accountSettingsSubtitleLong),
              const SizedBox(height: 20),
              _SettingsCard(
                title: strings.basicProfile,
                icon: Icons.badge_outlined,
                children: [
                  TextField(
                    key: const Key('settings-nickname'),
                    controller: nicknameController,
                    maxLength: 64,
                    decoration: InputDecoration(
                      labelText: strings.nickname,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('settings-avatar'),
                    controller: avatarController,
                    maxLength: 255,
                    decoration: InputDecoration(
                      labelText: strings.avatarUrl,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: gender,
                    decoration: InputDecoration(
                      labelText: strings.gender,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 0, child: Text(strings.genderUnknown)),
                      DropdownMenuItem(value: 1, child: Text(strings.genderMale)),
                      DropdownMenuItem(value: 2, child: Text(strings.genderFemale)),
                    ],
                    onChanged: (value) => setState(() => gender = value ?? 0),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('settings-signature'),
                    controller: signatureController,
                    maxLength: 255,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: strings.signature,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const Key('settings-save-profile'),
                    onPressed: savingProfile ? null : _saveProfile,
                    child: Text(savingProfile ? strings.saving : strings.saveProfile),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                title: strings.accountBinding,
                icon: Icons.link_outlined,
                children: [
                  Text(strings.emailLabel(profile.email.isEmpty ? strings.unbound : profile.email)),
                  Text(strings.phoneLabel(profile.phone.isEmpty ? strings.unbound : profile.phone)),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'email', label: Text(strings.email)),
                      ButtonSegment(value: 'phone', label: Text(strings.phone)),
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
                      labelText: bindType == 'email' ? strings.email : strings.phone,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('settings-bind-code'),
                    controller: bindCodeController,
                    decoration: InputDecoration(
                      labelText: strings.bindVerificationCode,
                      border: const OutlineInputBorder(),
                      suffixIcon: TextButton(
                        key: const Key('settings-send-bind-code'),
                        onPressed: sendingBindCode ? null : _sendBindCode,
                        child: Text(sendingBindCode ? strings.sendingCode : strings.sendCode),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const Key('settings-confirm-bind'),
                    onPressed: bindingAccount ? null : _bindAccount,
                    child: Text(bindingAccount ? strings.binding : strings.confirmBind),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                title: strings.changePassword,
                icon: Icons.lock_outline,
                children: [
                  Text(
                    profile.hasPassword
                        ? strings.hasPasswordHint
                        : strings.noPasswordHint,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('settings-old-password'),
                    controller: oldPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: strings.oldPassword,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('settings-new-password'),
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: strings.newPassword,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('settings-confirm-password'),
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: strings.confirmNewPassword,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const Key('settings-update-password'),
                    onPressed: updatingPassword
                        ? null
                        : () => _updatePassword(profile),
                    child: Text(updatingPassword ? strings.updating : strings.updatePassword),
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
