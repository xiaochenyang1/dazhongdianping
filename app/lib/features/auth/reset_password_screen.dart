import 'package:dazhongdianping_app/features/auth/auth_controller.dart';
import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.controller,
    required this.onReset,
  });

  final AuthController controller;
  final VoidCallback onReset;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final accountController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
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
    confirmPasswordController.dispose();
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
        scene: 'reset',
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
      setState(() => errorMessage = '账号、验证码和新密码都得填');
      return;
    }
    if (password != confirmPasswordController.text) {
      setState(() => errorMessage = '两次输入的新密码对不上');
      return;
    }
    setState(() {
      submitting = true;
      errorMessage = null;
    });
    try {
      await widget.controller.resetPassword(
        type: accountType,
        account: account,
        code: code,
        newPassword: password,
      );
      if (mounted) widget.onReset();
    } catch (error) {
      if (mounted) setState(() => errorMessage = '$error');
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('找回密码')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            '重新设置登录密码',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('用当前绑定邮箱或手机号验证身份，重置后再返回登录。'),
          const SizedBox(height: 24),
          TextField(
            key: const Key('reset-account'),
            controller: accountController,
            decoration: const InputDecoration(
              labelText: '邮箱或手机号',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('reset-code'),
            controller: codeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '重置验证码',
              border: const OutlineInputBorder(),
              suffixIcon: TextButton(
                onPressed: sendingCode ? null : sendCode,
                child: Text(sendingCode ? '发送中...' : '发送验证码'),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('reset-password'),
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '新密码',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('reset-confirm-password'),
            controller: confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '确认新密码',
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
            child: Text(submitting ? '重置中...' : '重置密码'),
          ),
        ],
      ),
    );
  }
}
