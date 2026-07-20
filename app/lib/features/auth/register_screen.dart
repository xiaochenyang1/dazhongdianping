import 'package:dazhongdianping_app/features/auth/auth_controller.dart';
import 'package:dazhongdianping_app/features/auth/auth_repository.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.controller,
    required this.onAuthenticated,
  });

  final AuthController controller;
  final ValueChanged<AuthUser> onAuthenticated;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final accountController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final nicknameController = TextEditingController();
  String? codeHint;
  String? errorMessage;
  bool sendingCode = false;
  bool submitting = false;

  String get accountType =>
      accountController.text.trim().contains('@') ? 'email' : 'phone';

  @override
  void dispose() {
    accountController.dispose();
    codeController.dispose();
    passwordController.dispose();
    nicknameController.dispose();
    super.dispose();
  }

  Future<void> sendCode() async {
    final account = accountController.text.trim();
    if (account.isEmpty) {
      setState(() => errorMessage = '先输入邮箱或手机号');
      return;
    }
    setState(() {
      sendingCode = true;
      errorMessage = null;
    });
    try {
      final result = await widget.controller.sendCode(
        account: account,
        type: accountType,
        scene: 'register',
      );
      if (mounted) {
        setState(() {
          codeHint = result.mockCode.isEmpty
              ? '验证码已发送，${result.nextRetrySeconds} 秒后可重发'
              : '本地验证码：${result.mockCode}';
        });
      }
    } catch (error) {
      if (mounted) setState(() => errorMessage = '$error');
    } finally {
      if (mounted) setState(() => sendingCode = false);
    }
  }

  Future<void> submit() async {
    final account = accountController.text.trim();
    final code = codeController.text.trim();
    final password = passwordController.text;
    if (account.isEmpty || code.isEmpty || password.isEmpty) {
      setState(() => errorMessage = '账号、验证码和密码都得填');
      return;
    }
    setState(() {
      submitting = true;
      errorMessage = null;
    });
    try {
      await widget.controller.register(
        type: accountType,
        account: account,
        code: code,
        password: password,
        nickname: nicknameController.text.trim(),
        preferredRegion: 'EU',
      );
      final user = widget.controller.currentUser;
      if (mounted && user != null) widget.onAuthenticated(user);
    } catch (error) {
      if (mounted) setState(() => errorMessage = '$error');
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('注册账号')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            '加入欧洲华人生活圈',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('邮箱或手机号都能注册，验证码只用于本次注册。'),
          const SizedBox(height: 24),
          TextField(
            key: const Key('register-account'),
            controller: accountController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: '邮箱或手机号',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('register-nickname'),
            controller: nicknameController,
            decoration: const InputDecoration(
              labelText: '昵称（可选）',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('register-code'),
            controller: codeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '注册验证码',
              border: const OutlineInputBorder(),
              suffixIcon: TextButton(
                onPressed: sendingCode ? null : sendCode,
                child: Text(sendingCode ? '发送中...' : '发送验证码'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('register-password'),
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '设置密码',
              border: OutlineInputBorder(),
            ),
          ),
          if (codeHint != null) ...[const SizedBox(height: 8), Text(codeHint!)],
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: submitting ? null : submit,
            child: Text(submitting ? '注册中...' : '注册并登录'),
          ),
        ],
      ),
    );
  }
}
