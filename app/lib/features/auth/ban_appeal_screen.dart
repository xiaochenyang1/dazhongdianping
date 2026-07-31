import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/features/auth/auth_controller.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';
import 'package:dazhongdianping_app/features/auth/auth_repository.dart';
import 'package:flutter/material.dart';

class BanAppealScreen extends StatefulWidget {
  const BanAppealScreen({
    super.key,
    required this.controller,
    this.initialAccount = '',
  });

  final AuthController controller;
  final String initialAccount;

  @override
  State<BanAppealScreen> createState() => _BanAppealScreenState();
}

class _BanAppealScreenState extends State<BanAppealScreen> {
  late final TextEditingController accountController;
  final codeController = TextEditingController();
  final reasonController = TextEditingController();
  String? codeHint;
  String? errorMessage;
  String? successMessage;
  BanAppealStatus? appealStatus;
  bool sendingCode = false;
  bool querying = false;

  String get accountType =>
      accountController.text.trim().contains('@') ? 'email' : 'phone';

  @override
  void initState() {
    super.initState();
    accountController = TextEditingController(text: widget.initialAccount);
  }

  @override
  void dispose() {
    accountController.dispose();
    codeController.dispose();
    reasonController.dispose();
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
      successMessage = null;
    });
    try {
      final result = await widget.controller.sendCode(
        account: account,
        type: accountType,
        scene: 'appeal',
      );
      if (!mounted) return;
      setState(() {
        codeHint = result.mockCode.isEmpty
            ? AppLocalizations.of(
                context,
              ).codeSentRetry(result.nextRetrySeconds)
            : AppLocalizations.of(context).localCodeHint(result.mockCode);
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => errorMessage = _localizedBanAppealError(
            AppLocalizations.of(context),
            error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => sendingCode = false);
    }
  }

  Future<void> submitAppeal() async {
    if (widget.controller.busy || querying) return;
    final account = accountController.text.trim();
    final code = codeController.text.trim();
    final reason = reasonController.text.trim();
    if (account.isEmpty || code.isEmpty) {
      setState(
        () => errorMessage = AppLocalizations.of(
          context,
        ).fillAccountAndCodeBeforeAppeal,
      );
      return;
    }
    if (reason.length < 10) {
      setState(
        () => errorMessage = AppLocalizations.of(context).appealReasonTooShort,
      );
      return;
    }
    setState(() {
      errorMessage = null;
      successMessage = null;
    });
    try {
      final status = await widget.controller.submitBanAppeal(
        type: accountType,
        account: account,
        code: code,
        reason: reason,
      );
      if (!mounted) return;
      setState(() {
        appealStatus = status;
        codeController.clear();
        reasonController.clear();
        successMessage = AppLocalizations.of(
          context,
        ).appealSubmitted(status.id);
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => errorMessage = _localizedBanAppealError(
            AppLocalizations.of(context),
            error,
          ),
        );
      }
    }
  }

  Future<void> queryProgress() async {
    if (querying || widget.controller.busy) return;
    final account = accountController.text.trim();
    final code = codeController.text.trim();
    if (account.isEmpty || code.isEmpty) {
      setState(
        () => errorMessage = AppLocalizations.of(
          context,
        ).queryNeedsAccountAndCode,
      );
      return;
    }
    setState(() {
      querying = true;
      errorMessage = null;
      successMessage = null;
    });
    try {
      final status = await widget.controller.queryBanAppeal(
        type: accountType,
        account: account,
        code: code,
      );
      if (!mounted) return;
      setState(() {
        appealStatus = status;
        codeController.clear();
        successMessage = AppLocalizations.of(
          context,
        ).appealProgressRefreshed(status.id);
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => errorMessage = _localizedBanAppealError(
            AppLocalizations.of(context),
            error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => querying = false);
    }
  }

  String _localizedBanAppealError(AppLocalizations strings, Object error) {
    return localizeAuthError(
      strings,
      error,
      overrides: {
        '账号不存在': strings.banAppealErrorAccountNotFound,
        '账号未被封禁，无需申诉': strings.banAppealErrorAccountNotBanned,
        '已有申诉正在处理中，请耐心等待审核结果': strings.banAppealErrorPendingExists,
        '该账号暂无申诉记录': strings.banAppealErrorNoRecord,
        '申诉状态已变化，请刷新后重试': strings.banAppealErrorStatusChanged,
        '验证码无效或已过期': strings.banAppealErrorCodeInvalid,
        '邮箱格式不合法': strings.banAppealErrorInvalidEmail,
        '手机号格式不合法': strings.banAppealErrorInvalidPhone,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final status = appealStatus;
    final statusLabel = status == null
        ? null
        : strings.banAppealStatusLabel(
            status: status.status,
            fallback: status.statusText,
          );
    return Scaffold(
      appBar: AppBar(title: Text(strings.banAppealTitle)),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              strings.banAppealHero,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(strings.banAppealSubtitle),
            const SizedBox(height: 24),
            TextField(
              key: const Key('appeal-account'),
              controller: accountController,
              decoration: InputDecoration(
                labelText: strings.emailOrPhone,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('appeal-code'),
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: strings.appealCode,
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
              key: const Key('appeal-reason'),
              controller: reasonController,
              minLines: 4,
              maxLines: 6,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: strings.appealReasonMin10,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(),
              ),
            ),
            if (codeHint != null) ...[
              const SizedBox(height: 8),
              Text(codeHint!),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                key: const Key('appeal-error'),
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (successMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                successMessage!,
                key: const Key('appeal-success'),
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
            if (status != null) ...[
              const SizedBox(height: 16),
              Card(
                key: const Key('appeal-status-card'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.appealStatusTitle(
                          id: status.id,
                          status: statusLabel!,
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (status.banReason.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(strings.banReasonLabel(status.banReason)),
                      ],
                      if (status.reason.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(strings.appealContentLabel(status.reason)),
                      ],
                      if (status.rejectReason.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(strings.rejectReasonLabel(status.rejectReason)),
                      ],
                      if (status.submittedAt.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          strings.submittedAtLabel(
                            formatDisplayDateTime(
                              status.submittedAt,
                              locale: strings.tag,
                            ),
                          ),
                        ),
                      ],
                      if (status.auditedAt.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          strings.processedAtLabel(
                            formatDisplayDateTime(
                              status.auditedAt,
                              locale: strings.tag,
                            ),
                          ),
                        ),
                      ],
                      if (status.isApproved) ...[
                        const SizedBox(height: 12),
                        Text(
                          strings.appealApprovedHint,
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('appeal-submit'),
              onPressed: widget.controller.busy ? null : submitAppeal,
              child: Text(
                widget.controller.busy
                    ? strings.submittingAppeal
                    : strings.submitAppeal,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('appeal-query'),
              onPressed: querying || widget.controller.busy
                  ? null
                  : queryProgress,
              child: Text(
                querying ? strings.querying : strings.queryAppealProgress,
              ),
            ),
            if (status?.isApproved == true) ...[
              const SizedBox(height: 12),
              TextButton(
                key: const Key('appeal-back-login'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(strings.backToLogin),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
