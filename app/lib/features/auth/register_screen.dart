import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/features/auth/auth_controller.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';
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
    if (sendingCode) return;
    final account = accountController.text.trim();
    if (account.isEmpty) {
      setState(
        () =>
            errorMessage = AppLocalizations.of(context).enterEmailOrPhoneFirst,
      );
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
              ? AppLocalizations.of(
                  context,
                ).codeSentRetry(result.nextRetrySeconds)
              : AppLocalizations.of(context).localCodeHint(result.mockCode);
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => errorMessage = localizeAuthError(
            AppLocalizations.of(context),
            error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => sendingCode = false);
    }
  }

  Future<void> submit() async {
    if (submitting) return;
    final account = accountController.text.trim();
    final code = codeController.text.trim();
    final password = passwordController.text;
    if (account.isEmpty || code.isEmpty || password.isEmpty) {
      setState(
        () =>
            errorMessage = AppLocalizations.of(context).fillAccountCodePassword,
      );
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
      if (mounted) {
        setState(
          () => errorMessage = localizeAuthError(
            AppLocalizations.of(context),
            error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.registerTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            strings.registerHero,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(strings.registerSubtitle),
          const SizedBox(height: 24),
          TextField(
            key: const Key('register-account'),
            controller: accountController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: strings.emailOrPhone,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('register-nickname'),
            controller: nicknameController,
            decoration: InputDecoration(
              labelText: strings.nicknameOptional,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('register-code'),
            controller: codeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: strings.registerCode,
              border: const OutlineInputBorder(),
              suffixIcon: TextButton(
                onPressed: sendingCode ? null : sendCode,
                child: Text(
                  sendingCode ? strings.sendingCode : strings.sendCode,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('register-password'),
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: strings.setPassword,
              border: const OutlineInputBorder(),
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
            child: Text(
              submitting ? strings.registering : strings.registerAndLogin,
            ),
          ),
        ],
      ),
    );
  }
}
