import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/auth/auth_controller.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';
import 'package:dazhongdianping_app/features/auth/auth_repository.dart';
import 'package:dazhongdianping_app/features/auth/ban_appeal_screen.dart';
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
  bool sendingCode = false;
  String? localError;
  String? codeHint;
  String? bannedAccount;

  @override
  void dispose() {
    accountController.dispose();
    passwordController.dispose();
    codeController.dispose();
    super.dispose();
  }

  String get accountType =>
      accountController.text.trim().contains('@') ? 'email' : 'phone';

  bool _isBannedError(Object error) =>
      error is ApiException &&
      (error.messageKey == 'auth.user_banned' ||
          error.message.trim() == '账号已被封禁，暂时无法登录' ||
          error.message.trim() == '账号已被封禁');

  Future<void> submit() async {
    if (widget.controller.busy) return;
    final account = accountController.text.trim();
    if (account.isEmpty) {
      setState(
        () => localError = AppLocalizations.of(context).enterEmailOrPhone,
      );
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
          bannedAccount = null;
        });
        widget.onAuthenticated(user);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        localError = localizeAuthError(AppLocalizations.of(context), error);
        bannedAccount = _isBannedError(error) ? account : null;
      });
    }
  }

  Future<void> sendCode() async {
    if (sendingCode) return;
    final account = accountController.text.trim();
    if (account.isEmpty) {
      setState(
        () => localError = AppLocalizations.of(context).enterEmailOrPhoneFirst,
      );
      return;
    }
    setState(() => sendingCode = true);
    try {
      final result = await widget.controller.sendCode(
        account: account,
        type: accountType,
      );
      if (mounted) {
        setState(() {
          codeHint = result.mockCode.isEmpty
              ? AppLocalizations.of(context).codeSent
              : AppLocalizations.of(context).localCodeHint(result.mockCode);
          localError = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => localError = localizeAuthError(
            AppLocalizations.of(context),
            error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => sendingCode = false);
    }
  }

  void openBanAppeal({String? account}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BanAppealScreen(
          controller: widget.controller,
          initialAccount:
              account ?? bannedAccount ?? accountController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.loginTitle)),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              strings.loginHero,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(strings.loginSubtitle),
            const SizedBox(height: 24),
            SegmentedButton<LoginMode>(
              segments: [
                ButtonSegment(
                  value: LoginMode.password,
                  label: Text(strings.passwordLogin),
                ),
                ButtonSegment(
                  value: LoginMode.code,
                  label: Text(strings.codeLogin),
                ),
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
              decoration: InputDecoration(
                labelText: strings.emailOrPhone,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (mode == LoginMode.password)
              TextField(
                key: const Key('login-password'),
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: strings.password,
                  border: const OutlineInputBorder(),
                ),
              )
            else ...[
              TextField(
                key: const Key('login-code'),
                controller: codeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: strings.verificationCode,
                  border: const OutlineInputBorder(),
                  suffixIcon: TextButton(
                    onPressed: sendingCode ? null : sendCode,
                    child: Text(
                      sendingCode ? strings.sendingCode : strings.sendCode,
                    ),
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
            if (bannedAccount != null)
              Padding(
                key: const Key('login-ban-appeal-cta'),
                padding: const EdgeInsets.only(top: 16),
                child: Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strings.accountBannedHint(bannedAccount!)),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          key: const Key('login-open-ban-appeal'),
                          onPressed: openBanAppeal,
                          child: Text(strings.submitBanAppeal),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (success)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  strings.loginSuccess,
                  style: const TextStyle(color: Colors.green),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: widget.controller.busy ? null : submit,
              child: Text(
                widget.controller.busy ? strings.loggingIn : strings.login,
              ),
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
              child: Text(strings.registerAccount),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ResetPasswordScreen(
                    controller: widget.controller,
                    onReset: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(
                              context,
                            ).passwordResetPleaseLogin,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              child: Text(strings.forgotPassword),
            ),
            TextButton(
              key: const Key('login-ban-appeal-entry'),
              onPressed: () =>
                  openBanAppeal(account: accountController.text.trim()),
              child: Text(strings.banAppeal),
            ),
          ],
        ),
      ),
    );
  }
}
