import 'package:dazhongdianping_app/features/user/user_repository.dart';
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

  void _reload() {
    setState(() {
      _error = null;
      _statusFuture = _load();
    });
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
      ).showSnackBar(const SnackBar(content: Text('达人认证申请已提交')));
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
      appBar: AppBar(title: const Text('本地达人认证')),
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
                  Text('认证状态加载失败：${snapshot.error}'),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _reload, child: const Text('重试')),
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
                        Text('提交时间：${status.submittedAt}'),
                      ],
                      if (status.reviewedAt.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('审核时间：${status.reviewedAt}'),
                      ],
                      if (status.effectiveStartAt.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('生效开始：${status.effectiveStartAt}'),
                      ],
                      if (status.effectiveEndAt.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('生效结束：${status.effectiveEndAt}'),
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
                decoration: const InputDecoration(
                  hintText: '说明你在本地区的内容贡献、探店经验或持续输出计划',
                  border: OutlineInputBorder(),
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
                const Text('申请审核中，请耐心等待结果。')
              else if (status.isApproved)
                const Text('你已通过本地达人认证，公开内容会展示达人标识。'),
            ],
          );
        },
      ),
    );
  }
}
