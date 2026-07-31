import 'package:dazhongdianping_app/features/user/user_repository.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:dazhongdianping_app/core/regional_formatters.dart';
import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';
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
    final strings = AppLocalizations.of(context);
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = strings.expertReasonRequired);
      return;
    }
    if (reason.length > 500) {
      setState(() => _error = strings.expertReasonTooLong);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).expertApplicationSubmitted,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _localizedExpertError(AppLocalizations.of(context), error);
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

  String _localizedExpertError(AppLocalizations strings, Object error) {
    return localizeAuthError(
      strings,
      error,
      overrides: {
        '当前已有待审核达人认证申请': strings.expertErrorPendingExists,
        '当前已是认证达人，无需重复申请': strings.expertErrorAlreadyApproved,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.localExpertCertification)),
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
                  Text(
                    strings.expertStatusLoadFailed(
                      _localizedExpertError(strings, snapshot.error!),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('expert-cert-retry'),
                    onPressed: _reloading ? null : _reload,
                    child: Text(
                      _reloading ? strings.processing : strings.retry,
                    ),
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
                        status.badgeCode == 'local_expert' || status.isApproved
                            ? strings.localExpertBadge
                            : status.badgeLabel,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.expertCertificationStatusLabel(
                          status.status,
                          fallback: status.statusText,
                        ),
                        style: TextStyle(
                          color: _statusColor(status.status),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                      if (status.reviewedAt.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          strings.reviewedAtLabel(
                            formatDisplayDateTime(
                              status.reviewedAt,
                              locale: strings.tag,
                            ),
                          ),
                        ),
                      ],
                      if (status.effectiveStartAt.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          strings.effectiveStartLabel(
                            formatDisplayDateTime(
                              status.effectiveStartAt,
                              locale: strings.tag,
                            ),
                          ),
                        ),
                      ],
                      if (status.effectiveEndAt.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          strings.effectiveEndLabel(
                            formatDisplayDateTime(
                              status.effectiveEndAt,
                              locale: strings.tag,
                            ),
                          ),
                        ),
                      ],
                      if (status.rejectReason.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          strings.rejectReasonLabel(status.rejectReason),
                          style: const TextStyle(color: Color(0xFFB91C1C)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.applicationReason,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('expert-cert-reason'),
                controller: _reasonController,
                maxLines: 6,
                maxLength: 500,
                enabled: status.canApply && !_submitting,
                decoration: InputDecoration(
                  hintText: strings.expertReasonHint,
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
                  child: Text(
                    _submitting
                        ? strings.submitting
                        : strings.submitApplication,
                  ),
                )
              else if (status.isPending)
                Text(strings.expertPendingHint)
              else if (status.isApproved)
                Text(strings.expertApprovedHint),
            ],
          );
        },
      ),
    );
  }
}
