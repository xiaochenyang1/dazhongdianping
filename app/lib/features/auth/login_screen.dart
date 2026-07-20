import 'package:dazhongdianping_app/features/auth/auth_controller.dart';
import 'package:dazhongdianping_app/features/auth/auth_repository.dart';
import 'package:dazhongdianping_app/features/auth/register_screen.dart';
import 'package:dazhongdianping_app/features/auth/reset_password_screen.dart';
import 'package:flutter/material.dart';

enum LoginMode { password, code }

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.controller,
    required this.onAuthenticated,
  });
  final AuthController controller;
  final ValueChanged<AuthUser> onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final accountController = TextEditingController();
  final passwordController = TextEditingController();
  final codeController = TextEditingController();
  LoginMode mode = LoginMode.password;
  bool success = false;
  String? localError;
  String? codeHint;

  @override
  void dispose() {
    accountController.dispose();
    passwordController.dispose();
    codeController.dispose();
    super.dispose();
  }

  String get accountType =>
      accountController.text.trim().contains('@') ? 'email' : 'phone';

  Future<void> submit() async {
    final account = accountController.text.trim();
    if (account.isEmpty) {
      setState(() => localError = '请输入邮箱或手机号');
      return;
    }
    try {
      if (mode == LoginMode.password) {
        await widget.controller.loginWithPassword(
          account,
          passwordController.text,
        );
      } else {
        await widget.controller.loginWithCode(
          account: account,
          type: accountType,
          code: codeController.text.trim(),
          preferredRegion: 'EU',
        );
      }
      final user = widget.controller.currentUser;
      if (user != null && mounted) {
        setState(() {
          success = true;
          localError = null;
        });
        widget.onAuthenticated(user);
      }
    } catch (error) {
      if (mounted) setState(() => localError = '$error');
    }
  }

  Future<void> sendCode() async {
    final account = accountController.text.trim();
    if (account.isEmpty) {
      setState(() => localError = '先输入邮箱或手机号');
      return;
    }
    try {
      final result = await widget.controller.sendCode(
        account: account,
        type: accountType,
      );
      if (mounted) {
        setState(() {
          codeHint = result.mockCode.isEmpty
              ? '验证码已发送'
              : '本地验证码：${result.mockCode}';
          localError = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => localError = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录大众点评')),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              '连接欧洲华人生活',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('邮箱和手机号都能登录，别整第三方登录套娃。'),
            const SizedBox(height: 24),
            SegmentedButton<LoginMode>(
              segments: const [
                ButtonSegment(value: LoginMode.password, label: Text('密码登录')),
                ButtonSegment(value: LoginMode.code, label: Text('验证码登录')),
              ],
              selected: {mode},
              onSelectionChanged: (values) =>
                  setState(() => mode = values.first),
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('login-account'),
              controller: accountController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: '邮箱或手机号',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (mode == LoginMode.password)
              TextField(
                key: const Key('login-password'),
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '密码',
                  border: OutlineInputBorder(),
                ),
              )
            else ...[
              TextField(
                key: const Key('login-code'),
                controller: codeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '验证码',
                  border: const OutlineInputBorder(),
                  suffixIcon: TextButton(
                    onPressed: sendCode,
                    child: const Text('发送验证码'),
                  ),
                ),
              ),
              if (codeHint != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(codeHint!),
                ),
            ],
            if (localError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  localError!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (success)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('登录成功', style: TextStyle(color: Colors.green)),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: widget.controller.busy ? null : submit,
              child: Text(widget.controller.busy ? '登录中...' : '登录'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RegisterScreen(
                    controller: widget.controller,
                    onAuthenticated: (user) {
                      Navigator.of(context).pop();
                      widget.onAuthenticated(user);
                    },
                  ),
                ),
              ),
              child: const Text('注册账号'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ResetPasswordScreen(
                    controller: widget.controller,
                    onReset: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('密码已重置，请使用新密码登录')),
                      );
                    },
                  ),
                ),
              ),
              child: const Text('忘记密码'),
            ),
          ],
        ),
      ),
    );
  }
}
