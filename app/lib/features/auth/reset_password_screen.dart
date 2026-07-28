import 'package:dazhongdianping_app/core/app_localizations.dart';
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
    if (sendingCode) return;
    final account = accountController.text.trim();
    if (account.isEmpty) {
      setState(() => errorMessage = AppLocalizations.of(context).enterEmailOrPhoneFirst);
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
              ? AppLocalizations.of(context).codeSentRetry(result.nextRetrySeconds)
              : AppLocalizations.of(context).localCodeHint(result.mockCode);
        });
      }
    } catch (error) {
      if (mounted) setState(() => errorMessage = '$error');
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
      setState(() => errorMessage = AppLocalizations.of(context).fillAccountCodeNewPassword);
      return;
    }
    if (password != confirmPasswordController.text) {
      setState(() => errorMessage = AppLocalizations.of(context).passwordsDoNotMatch);
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
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.resetPasswordTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            strings.resetPasswordHero,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(strings.resetPasswordSubtitle),
          const SizedBox(height: 24),
          TextField(
            key: const Key('reset-account'),
            controller: accountController,
            decoration: InputDecoration(
              labelText: strings.emailOrPhone,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('reset-code'),
            controller: codeController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: strings.resetCode,
              border: const OutlineInputBorder(),
              suffixIcon: TextButton(
                onPressed: sendingCode ? null : sendCode,
                child: Text(sendingCode ? strings.sendingCode : strings.sendCode),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('reset-password'),
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: strings.newPassword,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('reset-confirm-password'),
            controller: confirmPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: strings.confirmNewPassword,
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
            child: Text(submitting ? strings.resetting : strings.resetPassword),
          ),
        ],
      ),
    );
  }
}
