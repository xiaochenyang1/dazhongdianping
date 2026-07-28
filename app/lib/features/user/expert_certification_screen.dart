import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:flutter/material.dart';

class ExpertCertificationScreen extends StatefulWidget {
  const ExpertCertificationScreen({super.key, required this.repository});

  final UserRepository repository;

  @override
  State<ExpertCertificationScreen> createState() =>
      _ExpertCertificationScreenState();
}

class _ExpertCertificationScreenState extends State<ExpertCertificationScreen> {
  late Future<ExpertCertificationStatus> _statusFuture;
  final _reasonController = TextEditingController();
  bool _submitting = false;
  bool _reloading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _statusFuture = _load();
  }

  Future<ExpertCertificationStatus> _load() async {
    final status = await widget.repository.loadExpertCertification();
    if (mounted && status.reason.isNotEmpty && _reasonController.text.isEmpty) {
      _reasonController.text = status.reason;
    }
    return status;
  }

  Future<void> _reload() async {
    if (_reloading) return;
    final future = _load();
    setState(() {
      _error = null;
      _statusFuture = future;
      _reloading = true;
    });
    try {
      await future;
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => _reloading = false);
    }
  }

  Future<void> _submit(ExpertCertificationStatus current) async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = '请先填写申请理由');
      return;
    }
    if (reason.length > 500) {
      setState(() => _error = '申请理由不能超过 500 字');
      return;
    }
    if (!current.canApply || _submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final updated = await widget.repository.applyExpertCertification(reason);
      if (!mounted) return;
      setState(() {
        _statusFuture = Future.value(updated);
        _submitting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).expertApplicationSubmitted)));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = '$error';
      });
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Color _statusColor(int status) {
    return switch (status) {
      1 => const Color(0xFFB45309),
      2 => const Color(0xFF0F766E),
      3 => const Color(0xFFB91C1C),
      _ => const Color(0xFF4B5563),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).localExpertCertification)),
      body: FutureBuilder<ExpertCertificationStatus>(
        future: _statusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context).expertStatusLoadFailed(snapshot.error!)),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('expert-cert-retry'),
                    onPressed: _reloading ? null : _reload,
                    child: Text(_reloading ? '处理中...' : '重试'),
                  ),
                ],
              ),
            );
          }

          final status = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.badgeLabel.isNotEmpty
                            ? status.badgeLabel
                            : '本地达人',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        status.statusText,
                        style: TextStyle(
                          color: _statusColor(status.status),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (status.submittedAt.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(AppLocalizations.of(context).submittedAtLabel(status.submittedAt)),
                      ],
                      if (status.reviewedAt.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(AppLocalizations.of(context).reviewedAtLabel(status.reviewedAt)),
                      ],
                      if (status.effectiveStartAt.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(AppLocalizations.of(context).effectiveStartLabel(status.effectiveStartAt)),
                      ],
                      if (status.effectiveEndAt.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(AppLocalizations.of(context).effectiveEndLabel(status.effectiveEndAt)),
                      ],
                      if (status.rejectReason.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          '驳回原因：${status.rejectReason}',
                          style: const TextStyle(color: Color(0xFFB91C1C)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '申请理由',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('expert-cert-reason'),
                controller: _reasonController,
                maxLines: 6,
                maxLength: 500,
                enabled: status.canApply && !_submitting,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).expertReasonHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C))),
              ],
              const SizedBox(height: 12),
              if (status.canApply)
                FilledButton(
                  onPressed: _submitting ? null : () => _submit(status),
                  child: Text(_submitting ? '提交中...' : '提交申请'),
                )
              else if (status.isPending)
                Text(AppLocalizations.of(context).expertPendingHint)
              else if (status.isApproved)
                Text(AppLocalizations.of(context).expertApprovedHint),
            ],
          );
        },
      ),
    );
  }
}
