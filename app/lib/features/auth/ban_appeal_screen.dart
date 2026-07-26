import 'package:dazhongdianping_app/features/auth/auth_controller.dart';
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
    final account = accountController.text.trim();
    if (account.isEmpty) {
      setState(() => errorMessage = '先输入邮箱或手机号');
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
            ? '验证码已发送，${result.nextRetrySeconds} 秒后可重发'
            : '本地验证码：${result.mockCode}';
      });
    } catch (error) {
      if (mounted) setState(() => errorMessage = '$error');
    } finally {
      if (mounted) setState(() => sendingCode = false);
    }
  }

  Future<void> submitAppeal() async {
    final account = accountController.text.trim();
    final code = codeController.text.trim();
    final reason = reasonController.text.trim();
    if (account.isEmpty || code.isEmpty) {
      setState(() => errorMessage = '先填好账号和验证码，再提交申诉');
      return;
    }
    if (reason.length < 10) {
      setState(() => errorMessage = '申诉理由至少写 10 个字，把误封的情况说清楚');
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
        successMessage = '申诉 #${status.id} 已提交，运营会尽快复核';
      });
    } catch (error) {
      if (mounted) setState(() => errorMessage = '$error');
    }
  }

  Future<void> queryProgress() async {
    final account = accountController.text.trim();
    final code = codeController.text.trim();
    if (account.isEmpty || code.isEmpty) {
      setState(() => errorMessage = '查询进度也需要账号和一条新的验证码');
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
        successMessage = '已刷新申诉 #${status.id} 的最新进度';
      });
    } catch (error) {
      if (mounted) setState(() => errorMessage = '$error');
    } finally {
      if (mounted) setState(() => querying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = appealStatus;
    return Scaffold(
      appBar: AppBar(title: const Text('封禁申诉')),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              '账号被封后的救济入口',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text('用当前绑定邮箱或手机号验证身份。运营复核通过后会自动解封，再回登录页继续使用。'),
            const SizedBox(height: 24),
            TextField(
              key: const Key('appeal-account'),
              controller: accountController,
              decoration: const InputDecoration(
                labelText: '邮箱或手机号',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('appeal-code'),
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '申诉验证码',
                border: const OutlineInputBorder(),
                suffixIcon: TextButton(
                  onPressed: sendingCode ? null : sendCode,
                  child: Text(sendingCode ? '发送中...' : '发送验证码'),
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
              decoration: const InputDecoration(
                labelText: '申诉理由（至少 10 个字）',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
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
                        '申诉 #${status.id} · ${status.statusText}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (status.banReason.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('封禁原因：${status.banReason}'),
                      ],
                      if (status.reason.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('申诉内容：${status.reason}'),
                      ],
                      if (status.rejectReason.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('驳回说明：${status.rejectReason}'),
                      ],
                      if (status.submittedAt.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('提交时间：${status.submittedAt}'),
                      ],
                      if (status.auditedAt.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('处理时间：${status.auditedAt}'),
                      ],
                      if (status.isApproved) ...[
                        const SizedBox(height: 12),
                        const Text(
                          '申诉已通过，账号已解封。请返回登录页继续使用。',
                          style: TextStyle(color: Colors.green),
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
              child: Text(widget.controller.busy ? '提交中...' : '提交申诉'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const Key('appeal-query'),
              onPressed: querying || widget.controller.busy
                  ? null
                  : queryProgress,
              child: Text(querying ? '查询中...' : '查询申诉进度'),
            ),
            if (status?.isApproved == true) ...[
              const SizedBox(height: 12),
              TextButton(
                key: const Key('appeal-back-login'),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('返回登录'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
