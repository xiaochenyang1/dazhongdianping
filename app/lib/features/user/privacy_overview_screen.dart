import 'package:dazhongdianping_app/features/auth/auth_error_localizer.dart';
import 'package:dazhongdianping_app/features/user/privacy_export_saver.dart';
import 'package:dazhongdianping_app/features/user/privacy_repository.dart';
import 'package:dazhongdianping_app/core/app_localizations.dart';
import 'package:flutter/material.dart';

class PrivacyOverviewScreen extends StatefulWidget {
  PrivacyOverviewScreen({
    super.key,
    required this.repository,
    required this.accounts,
    PrivacyExportSaver? saver,
    this.localeTag = 'zh-CN',
  }) : saver = saver ?? PrivacyExportSaver();

  final PrivacyRepository repository;
  final List<String> accounts;
  final PrivacyExportSaver saver;
  final String localeTag;

  @override
  State<PrivacyOverviewScreen> createState() => _PrivacyOverviewScreenState();
}

class _PrivacyOverviewScreenState extends State<PrivacyOverviewScreen> {
  late Future<_PrivacyData> _data;
  final Set<int> _downloadingTaskIds = {};
  bool _includeAccount = true;
  bool _includeReviews = true;
  bool _includePosts = true;
  bool _includeOrders = true;
  bool _includeReservations = true;
  bool _includeFavorites = true;
  bool _includeFollows = true;
  bool _includeMessages = true;
  bool _includeCircles = true;
  bool _includeTopics = true;
  bool _creatingExport = false;
  bool _loadingMoreExports = false;
  bool _retrying = false;
  bool _cancellingDelete = false;
  bool _submittingDelete = false;
  bool _sendingDeleteCode = false;
  final Set<int> _acceptingPolicyTypes = <int>{};
  final Set<int> _loggingOutDeviceIds = <int>{};
  int _dataRevision = 0;
  String _codeHint = '';
  String _verifyType = 'code';
  String? _selectedAccount;
  final _accountController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedAccount = widget.accounts.firstOrNull;
    _data = _load();
  }

  @override
  void dispose() {
    _accountController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<_PrivacyData> _load() async {
    final results = await Future.wait([
      widget.repository.loadOverview(),
      widget.repository.loadExportTasks(),
      widget.repository.loadPolicyLogs(),
      widget.repository.loadDevices(),
    ]);
    return _PrivacyData(
      overview: results[0] as PrivacyOverview,
      exportTaskPage: results[1] as PrivacyExportTaskPage,
      policyLogs: results[2] as List<PolicyAcceptLog>,
      devices: results[3] as List<UserDevice>,
    );
  }

  void _reload() => _startReload();

  Future<_PrivacyData> _startReload() {
    _dataRevision++;
    final future = _load();
    setState(() {
      _data = future;
      _loadingMoreExports = false;
    });
    return future;
  }

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await _startReload();
    } catch (_) {
      // FutureBuilder renders the request error.
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  Future<void> _loadMoreExports(_PrivacyData current) async {
    final currentPage = current.exportTaskPage;
    if (_loadingMoreExports || !currentPage.hasMore) return;
    final revision = _dataRevision;
    setState(() => _loadingMoreExports = true);
    try {
      final next = await widget.repository.loadExportTasks(
        page: currentPage.page + 1,
        pageSize: currentPage.pageSize,
      );
      if (!mounted || revision != _dataRevision) return;
      final knownIds = currentPage.items.map((task) => task.id).toSet();
      final merged = PrivacyExportTaskPage(
        items: [
          ...currentPage.items,
          ...next.items.where((task) => knownIds.add(task.id)),
        ],
        total: next.total,
        page: next.page,
        pageSize: currentPage.pageSize,
      );
      setState(() {
        _data = Future.value(current.withExportTaskPage(merged));
      });
    } catch (error) {
      if (mounted && revision == _dataRevision) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).loadMoreExportTasksFailed(error),
            ),
          ),
        );
      }
    } finally {
      if (mounted && revision == _dataRevision) {
        setState(() => _loadingMoreExports = false);
      }
    }
  }

  Future<void> _acceptPolicy(int policyType) async {
    if (_acceptingPolicyTypes.contains(policyType)) return;
    setState(() => _acceptingPolicyTypes.add(policyType));
    try {
      await widget.repository.acceptPolicy(
        policyType: policyType,
        version: '2026.07',
        locale: widget.localeTag,
      );
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).agreementRecorded)),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).agreementRecordFailed(error),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _acceptingPolicyTypes.remove(policyType));
      }
    }
  }

  Future<void> _logoutDevice(UserDevice device) async {
    if (_loggingOutDeviceIds.contains(device.id)) return;
    setState(() => _loggingOutDeviceIds.add(device.id));
    try {
      await widget.repository.logoutDevice(device.id);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).deviceDeactivated)),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).deviceDeactivateFailed(error),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loggingOutDeviceIds.remove(device.id));
      }
    }
  }

  Future<void> _download(PrivacyExportTask task) async {
    if (_downloadingTaskIds.contains(task.id)) return;
    setState(() => _downloadingTaskIds.add(task.id));
    try {
      final bytes = await widget.repository.downloadExport(task.id);
      final path = await widget.saver.save(task.id, bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).exportSaved(path)),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).exportDownloadFailed(error),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingTaskIds.remove(task.id));
      }
    }
  }

  Future<void> _createExport() async {
    if (_creatingExport) return;
    final modules = [
      if (_includeAccount) 'account',
      if (_includeReviews) 'reviews',
      if (_includePosts) 'posts',
      if (_includeOrders) 'orders',
      if (_includeReservations) 'reservations',
      if (_includeFavorites) 'favorites',
      if (_includeFollows) 'follows',
      if (_includeMessages) 'messages',
      if (_includeCircles) 'circles',
      if (_includeTopics) 'topics',
    ];
    if (modules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).selectExportModule),
        ),
      );
      return;
    }
    setState(() => _creatingExport = true);
    try {
      await widget.repository.createExportTask(modules);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).exportTaskCreated)),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).createExportFailed(error),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _creatingExport = false);
      }
    }
  }

  Future<void> _cancelDelete(PrivacyDeleteTask task) async {
    if (_cancellingDelete) return;
    setState(() => _cancellingDelete = true);
    try {
      await widget.repository.cancelDeleteTask(task.id);
      if (!mounted) return;
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).deleteRequestCanceled),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).cancelDeleteFailed(error),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cancellingDelete = false);
      }
    }
  }

  Future<void> _submitDelete() async {
    if (_submittingDelete) return;
    final account = (_selectedAccount ?? _accountController.text).trim();
    final reason = _reasonController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    if (account.isEmpty || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).fillAccountAndDeleteReason,
          ),
        ),
      );
      return;
    }
    if (_verifyType == 'code' && code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).codeNotFilled)),
      );
      return;
    }
    if (_verifyType == 'password' && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).passwordNotFilled)),
      );
      return;
    }
    setState(() => _submittingDelete = true);
    try {
      await widget.repository.createDeleteTask(
        verifyType: _verifyType,
        account: account,
        verifyCode: _verifyType == 'code' ? code : null,
        password: _verifyType == 'password' ? password : null,
        reason: reason,
      );
      if (!mounted) return;
      _codeController.clear();
      _passwordController.clear();
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).deleteEnteredCoolingOff),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).submitDeleteFailed(
                _localizedDeleteError(AppLocalizations.of(context), error),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submittingDelete = false);
      }
    }
  }

  Future<void> _sendDeleteCode() async {
    if (_sendingDeleteCode) return;
    final account = (_selectedAccount ?? _accountController.text).trim();
    if (account.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).fillBoundAccountFirst),
        ),
      );
      return;
    }
    setState(() {
      _sendingDeleteCode = true;
      _codeHint = '';
    });
    try {
      final result = await widget.repository.sendDeleteCode(account);
      if (!mounted) return;
      setState(() {
        _codeHint = result.mockCode.isEmpty
            ? AppLocalizations.of(
                context,
              ).codeSentRetry(result.nextRetrySeconds)
            : AppLocalizations.of(context).localCodeOnly(result.mockCode);
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).sendDeleteCodeFailed(
                _localizedDeleteError(AppLocalizations.of(context), error),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sendingDeleteCode = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).privacyCenter)),
      body: FutureBuilder<_PrivacyData>(
        future: _data,
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
                    AppLocalizations.of(
                      context,
                    ).privacyLoadFailed(snapshot.error!),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    key: const Key('privacy-overview-retry'),
                    onPressed: _retrying ? null : _retry,
                    icon: const Icon(Icons.refresh),
                    label: Text(
                      _retrying
                          ? AppLocalizations.of(context).processing
                          : AppLocalizations.of(context).retry,
                    ),
                  ),
                ],
              ),
            );
          }
          final data = snapshot.data!;
          final overview = data.overview;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                AppLocalizations.of(context).privacyHero,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context).privacySubtitle),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _RuleCard(
                      icon: Icons.archive_outlined,
                      title: AppLocalizations.of(context).dataExport,
                      value: AppLocalizations.of(
                        context,
                      ).exportDailyLimit(overview.exportRule.dailyLimit),
                      detail: AppLocalizations.of(
                        context,
                      ).exportFileRetention(overview.exportRule.expireHours),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RuleCard(
                      icon: Icons.schedule_outlined,
                      title: AppLocalizations.of(context).accountDeletion,
                      value: AppLocalizations.of(
                        context,
                      ).coolingOffDays(overview.deleteRule.coolingOffDays),
                      detail: AppLocalizations.of(
                        context,
                      ).canCancelBeforeDeadline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                AppLocalizations.of(context).dataExport,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text(
                      AppLocalizations.of(context).exportModuleAccount,
                    ),
                    selected: _includeAccount,
                    onSelected: (selected) {
                      setState(() => _includeAccount = selected);
                    },
                  ),
                  FilterChip(
                    label: Text(
                      AppLocalizations.of(context).exportModuleReviews,
                    ),
                    selected: _includeReviews,
                    onSelected: (selected) {
                      setState(() => _includeReviews = selected);
                    },
                  ),
                  FilterChip(
                    label: Text(
                      AppLocalizations.of(context).exportModuleOrders,
                    ),
                    selected: _includeOrders,
                    onSelected: (selected) {
                      setState(() => _includeOrders = selected);
                    },
                  ),
                  FilterChip(
                    label: Text(AppLocalizations.of(context).exportModulePosts),
                    selected: _includePosts,
                    onSelected: (selected) {
                      setState(() => _includePosts = selected);
                    },
                  ),
                  FilterChip(
                    label: Text(
                      AppLocalizations.of(context).exportModuleReservations,
                    ),
                    selected: _includeReservations,
                    onSelected: (selected) {
                      setState(() => _includeReservations = selected);
                    },
                  ),
                  FilterChip(
                    label: Text(
                      AppLocalizations.of(context).exportModuleFavorites,
                    ),
                    selected: _includeFavorites,
                    onSelected: (selected) {
                      setState(() => _includeFavorites = selected);
                    },
                  ),
                  FilterChip(
                    label: Text(
                      AppLocalizations.of(context).exportModuleFollows,
                    ),
                    selected: _includeFollows,
                    onSelected: (selected) {
                      setState(() => _includeFollows = selected);
                    },
                  ),
                  FilterChip(
                    label: Text(
                      AppLocalizations.of(context).exportModuleMessages,
                    ),
                    selected: _includeMessages,
                    onSelected: (selected) {
                      setState(() => _includeMessages = selected);
                    },
                  ),
                  FilterChip(
                    label: Text(
                      AppLocalizations.of(context).exportModuleCircles,
                    ),
                    selected: _includeCircles,
                    onSelected: (selected) {
                      setState(() => _includeCircles = selected);
                    },
                  ),
                  FilterChip(
                    label: Text(
                      AppLocalizations.of(context).exportModuleTopics,
                    ),
                    selected: _includeTopics,
                    onSelected: (selected) {
                      setState(() => _includeTopics = selected);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context).privacyExportHint),
              const SizedBox(height: 12),
              FilledButton.icon(
                key: const Key('privacy-create-export'),
                onPressed: _creatingExport ? null : _createExport,
                icon: const Icon(Icons.archive_outlined),
                label: Text(
                  _creatingExport
                      ? AppLocalizations.of(context).creatingExport
                      : AppLocalizations.of(context).createExportTask,
                ),
              ),
              const SizedBox(height: 16),
              ...data.exportTasks.map(_buildExportTask),
              if (data.exportTaskPage.hasMore)
                Center(
                  child: OutlinedButton.icon(
                    key: const Key('privacy-exports-load-more'),
                    onPressed: _loadingMoreExports
                        ? null
                        : () => _loadMoreExports(data),
                    icon: _loadingMoreExports
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more),
                    label: Text(
                      _loadingMoreExports
                          ? AppLocalizations.of(context).loading
                          : AppLocalizations.of(context).loadMoreExportTasks,
                    ),
                  ),
                ),
              if (data.exportTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(AppLocalizations.of(context).noExportTasks),
                  ),
                ),
              const SizedBox(height: 28),
              Text(
                AppLocalizations.of(context).agreementTrace,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context).agreementRecordsHint),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    key: const Key('privacy-accept-policy-1'),
                    onPressed: !_acceptingPolicyTypes.contains(1)
                        ? () => _acceptPolicy(1)
                        : null,
                    child: Text(
                      _acceptingPolicyTypes.contains(1)
                          ? AppLocalizations.of(context).recordingAcceptance
                          : AppLocalizations.of(context).confirmPrivacyPolicy,
                    ),
                  ),
                  OutlinedButton(
                    key: const Key('privacy-accept-policy-2'),
                    onPressed: !_acceptingPolicyTypes.contains(2)
                        ? () => _acceptPolicy(2)
                        : null,
                    child: Text(
                      _acceptingPolicyTypes.contains(2)
                          ? AppLocalizations.of(context).recordingAcceptance
                          : AppLocalizations.of(context).confirmUserAgreement,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...data.policyLogs.map(
                (log) => Card(
                  child: ListTile(
                    title: Text(
                      '${_policyName(log.policyType)} · ${log.version}',
                    ),
                    subtitle: Text(
                      '${log.acceptedAt} · ${log.locale}\n${log.userAgent}',
                    ),
                    isThreeLine: true,
                  ),
                ),
              ),
              if (data.policyLogs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(AppLocalizations.of(context).noAgreementRecords),
                ),
              const SizedBox(height: 28),
              Text(
                AppLocalizations.of(context).deviceManagement,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context).deviceLifecycleHint),
              const SizedBox(height: 12),
              ...data.devices.map(
                (device) => Card(
                  child: ListTile(
                    title: Text(
                      '${_platformName(device.platform)} · ${device.appVersion}',
                    ),
                    subtitle: Text(
                      '${device.deviceUid}\n${_deviceStatusText(AppLocalizations.of(context), device.status)} · ${AppLocalizations.of(context).lastActiveAt(device.lastActiveAt ?? '—')}',
                    ),
                    isThreeLine: true,
                    trailing: device.active
                        ? TextButton(
                            key: Key('privacy-logout-device-${device.id}'),
                            onPressed: !_loggingOutDeviceIds.contains(device.id)
                                ? () => _logoutDevice(device)
                                : null,
                            child: Text(
                              _loggingOutDeviceIds.contains(device.id)
                                  ? AppLocalizations.of(
                                      context,
                                    ).deactivatingDevice
                                  : AppLocalizations.of(
                                      context,
                                    ).deactivateThisDevice,
                            ),
                          )
                        : Text(
                            _deviceStatusText(
                              AppLocalizations.of(context),
                              device.status,
                            ),
                          ),
                  ),
                ),
              ),
              if (data.devices.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(AppLocalizations.of(context).noRegisteredDevices),
                ),
              const SizedBox(height: 28),
              Text(
                AppLocalizations.of(context).accountDeletion,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (overview.latestDeleteTask case final task?)
                _buildDeleteTask(task),
              if (overview.latestDeleteTask?.canCancel != true) ...[
                const SizedBox(height: 12),
                _buildDeleteForm(overview.deleteRule),
              ],
            ],
          );
        },
      ),
    );
  }

  String _policyName(int policyType) {
    return switch (policyType) {
      1 => AppLocalizations.of(context).privacyPolicy,
      2 => AppLocalizations.of(context).userAgreement,
      3 => AppLocalizations.of(context).cookieMarketingNotice,
      _ => AppLocalizations.of(context).unknownAgreement,
    };
  }

  String _platformName(int platform) {
    return switch (platform) {
      1 => 'iOS',
      2 => 'Android',
      3 => 'Web',
      _ => AppLocalizations.of(context).unknownDevice,
    };
  }

  String _deviceStatusText(AppLocalizations strings, int status) {
    return switch (status) {
      1 => strings.deviceEnabled,
      2 => strings.deviceDisabled,
      3 => strings.deviceLoggedOut,
      _ => strings.unknownStatus,
    };
  }

  String _localizedDeleteError(AppLocalizations strings, Object error) {
    return localizeAuthError(
      strings,
      error,
      overrides: {
        '删除校验账号必须是当前已绑定账号': strings.privacyDeleteErrorBoundAccountOnly,
        '当前账号还没有可校验的登录密码': strings.privacyDeleteErrorNoPassword,
        '删除校验密码不正确': strings.privacyDeleteErrorWrongPassword,
      },
    );
  }

  Widget _buildExportTask(PrivacyExportTask task) {
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.exportTaskTitle(task.id),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    strings.privacyExportTaskStatusLabel(
                      task.status,
                      fallback: task.statusText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(task.modules.map(strings.exportModuleLabel).join(' / ')),
              Text(strings.createdAtLabel(task.createdAt)),
              if (task.expireAt != null)
                Text(strings.expiresAtLabel('${task.expireAt}')),
              if (task.failReason.isNotEmpty)
                Text(
                  task.failReason,
                  style: const TextStyle(color: Colors.red),
                ),
              if (task.readyToDownload) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: Key('privacy-download-export-${task.id}'),
                  onPressed: _downloadingTaskIds.contains(task.id)
                      ? null
                      : () => _download(task),
                  icon: const Icon(Icons.download_outlined),
                  label: Text(
                    _downloadingTaskIds.contains(task.id)
                        ? strings.downloadingZip
                        : strings.downloadZip,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteTask(PrivacyDeleteTask task) {
    final strings = AppLocalizations.of(context);
    final statusText = strings.privacyDeleteTaskStatusLabel(
      task.status,
      fallback: task.statusText,
    );
    return Card(
      color: const Color(0xFFFFF1EC),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.deleteTaskTitle(id: task.id, status: statusText),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(strings.reasonLabel(task.reason)),
            Text(strings.coolingOffDeadline(task.coolingOffExpireAt ?? '—')),
            if (task.canCancel) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                key: Key('privacy-cancel-delete-${task.id}'),
                onPressed: _cancellingDelete ? null : () => _cancelDelete(task),
                child: Text(
                  _cancellingDelete
                      ? strings.cancellingDelete
                      : strings.cancelDeleteRequest,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteForm(PrivacyDeleteRule rule) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppLocalizations.of(context).submitDeleteRequest,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'code',
                  label: Text(AppLocalizations.of(context).verifyByCode),
                ),
                ButtonSegment(
                  value: 'password',
                  label: Text(AppLocalizations.of(context).verifyByPassword),
                ),
              ],
              selected: {_verifyType},
              onSelectionChanged: (selection) {
                setState(() => _verifyType = selection.first);
              },
            ),
            const SizedBox(height: 12),
            if (widget.accounts.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: _selectedAccount,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).boundAccount,
                  border: OutlineInputBorder(),
                ),
                items: widget.accounts
                    .map(
                      (account) => DropdownMenuItem(
                        value: account,
                        child: Text(account, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedAccount = value),
              )
            else
              TextField(
                key: const Key('privacy-delete-account'),
                controller: _accountController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).boundAccount,
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 12),
            if (_verifyType == 'code')
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const Key('privacy-delete-code'),
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      ).deleteVerificationCode,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    key: const Key('privacy-send-delete-code'),
                    onPressed: _sendingDeleteCode ? null : _sendDeleteCode,
                    child: Text(
                      _sendingDeleteCode
                          ? AppLocalizations.of(context).sendingCode
                          : AppLocalizations.of(context).sendDeleteCode,
                    ),
                  ),
                  if (_codeHint.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_codeHint),
                  ],
                ],
              )
            else
              TextField(
                key: const Key('privacy-delete-password'),
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).currentLoginPassword,
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('privacy-delete-reason'),
              controller: _reasonController,
              maxLength: 255,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).deleteReason,
                border: OutlineInputBorder(),
              ),
            ),
            Text(
              AppLocalizations.of(context).coolingOffIntro(rule.coolingOffDays),
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('privacy-delete-submit'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: _submittingDelete ? null : _submitDelete,
              child: Text(
                _submittingDelete
                    ? AppLocalizations.of(context).submitting
                    : AppLocalizations.of(context).submitDeleteRequest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyData {
  const _PrivacyData({
    required this.overview,
    required this.exportTaskPage,
    required this.policyLogs,
    required this.devices,
  });

  final PrivacyOverview overview;
  final PrivacyExportTaskPage exportTaskPage;
  final List<PolicyAcceptLog> policyLogs;
  final List<UserDevice> devices;

  List<PrivacyExportTask> get exportTasks => exportTaskPage.items;

  _PrivacyData withExportTaskPage(PrivacyExportTaskPage value) => _PrivacyData(
    overview: overview,
    exportTaskPage: value,
    policyLogs: policyLogs,
    devices: devices,
  );
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFE85D2A)),
            const SizedBox(height: 12),
            Text(title),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(detail, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
