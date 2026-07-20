import 'package:dazhongdianping_app/features/user/privacy_export_saver.dart';
import 'package:dazhongdianping_app/features/user/privacy_repository.dart';
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
  bool _cancellingDelete = false;
  bool _submittingDelete = false;
  bool _sendingDeleteCode = false;
  int? _acceptingPolicyType;
  int? _loggingOutDeviceId;
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
      exportTasks: (results[1] as PrivacyExportTaskPage).items,
      policyLogs: results[2] as List<PolicyAcceptLog>,
      devices: results[3] as List<UserDevice>,
    );
  }

  Future<void> _acceptPolicy(int policyType) async {
    setState(() => _acceptingPolicyType = policyType);
    try {
      await widget.repository.acceptPolicy(
        policyType: policyType,
        version: '2026.07',
        locale: widget.localeTag,
      );
      if (!mounted) return;
      setState(() {
        _data = _load();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('协议同意记录已留痕')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('协议留痕失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _acceptingPolicyType = null);
    }
  }

  Future<void> _logoutDevice(UserDevice device) async {
    setState(() => _loggingOutDeviceId = device.id);
    try {
      await widget.repository.logoutDevice(device.id);
      if (!mounted) return;
      setState(() {
        _data = _load();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('设备已停用并清除推送 token')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('停用设备失败：$error')));
      }
    } finally {
      if (mounted) setState(() => _loggingOutDeviceId = null);
    }
  }

  Future<void> _download(PrivacyExportTask task) async {
    setState(() => _downloadingTaskIds.add(task.id));
    try {
      final bytes = await widget.repository.downloadExport(task.id);
      final path = await widget.saver.save(task.id, bytes);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('导出文件已保存：$path')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('下载导出文件失败：$error')));
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingTaskIds.remove(task.id));
      }
    }
  }

  Future<void> _createExport() async {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('至少选择一个导出模块')));
      return;
    }
    setState(() => _creatingExport = true);
    try {
      await widget.repository.createExportTask(modules);
      if (!mounted) return;
      setState(() {
        _data = _load();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('导出任务已创建，准备好后可下载')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('创建导出任务失败：$error')));
      }
    } finally {
      if (mounted) {
        setState(() => _creatingExport = false);
      }
    }
  }

  Future<void> _cancelDelete(PrivacyDeleteTask task) async {
    setState(() => _cancellingDelete = true);
    try {
      await widget.repository.cancelDeleteTask(task.id);
      if (!mounted) return;
      setState(() {
        _data = _load();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('删除申请已撤销，账号会继续保留')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('撤销删除申请失败：$error')));
      }
    } finally {
      if (mounted) {
        setState(() => _cancellingDelete = false);
      }
    }
  }

  Future<void> _submitDelete() async {
    final account = (_selectedAccount ?? _accountController.text).trim();
    final reason = _reasonController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    if (account.isEmpty || reason.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('校验账号和删除原因都得填')));
      return;
    }
    if (_verifyType == 'code' && code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('验证码还没填')));
      return;
    }
    if (_verifyType == 'password' && password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('登录密码还没填')));
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
      setState(() {
        _data = _load();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('删除申请已进入冷静期，到期前可以撤销')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('提交删除申请失败：$error')));
      }
    } finally {
      if (mounted) {
        setState(() => _submittingDelete = false);
      }
    }
  }

  Future<void> _sendDeleteCode() async {
    final account = (_selectedAccount ?? _accountController.text).trim();
    if (account.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('先填写当前已绑定账号')));
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
            ? '${result.nextRetrySeconds} 秒后可重新发送'
            : '本地验证码：${result.mockCode}';
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('发送注销验证码失败：$error')));
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
      appBar: AppBar(title: const Text('隐私中心')),
      body: FutureBuilder<_PrivacyData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('隐私数据加载失败：${snapshot.error}'));
          }
          final data = snapshot.data!;
          final overview = data.overview;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                '你的数据，由你说了算',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text('导出能带走，删除有冷静期，规则和任务状态都摊开讲清楚。'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _RuleCard(
                      icon: Icons.archive_outlined,
                      title: '数据导出',
                      value: '每天最多 ${overview.exportRule.dailyLimit} 次',
                      detail: '文件保留 ${overview.exportRule.expireHours} 小时',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RuleCard(
                      icon: Icons.schedule_outlined,
                      title: '账号删除',
                      value: '${overview.deleteRule.coolingOffDays} 天冷静期',
                      detail: '到期前可以撤销',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                '数据导出',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('账号数据'),
                    selected: _includeAccount,
                    onSelected: (selected) {
                      setState(() => _includeAccount = selected);
                    },
                  ),
                  FilterChip(
                    label: const Text('点评数据'),
                    selected: _includeReviews,
                    onSelected: (selected) {
                      setState(() => _includeReviews = selected);
                    },
                  ),
                  FilterChip(
                    label: const Text('订单数据'),
                    selected: _includeOrders,
                    onSelected: (selected) {
                      setState(() => _includeOrders = selected);
                    },
                  ),
                  FilterChip(
                    label: const Text('帖子数据'),
                    selected: _includePosts,
                    onSelected: (selected) {
                      setState(() => _includePosts = selected);
                    },
                  ),
                  FilterChip(
                    label: const Text('预订数据'),
                    selected: _includeReservations,
                    onSelected: (selected) {
                      setState(() => _includeReservations = selected);
                    },
                  ),
                  FilterChip(
                    label: const Text('收藏数据'),
                    selected: _includeFavorites,
                    onSelected: (selected) {
                      setState(() => _includeFavorites = selected);
                    },
                  ),
                  FilterChip(
                    label: const Text('关注关系'),
                    selected: _includeFollows,
                    onSelected: (selected) {
                      setState(() => _includeFollows = selected);
                    },
                  ),
                  FilterChip(
                    label: const Text('私信数据'),
                    selected: _includeMessages,
                    onSelected: (selected) {
                      setState(() => _includeMessages = selected);
                    },
                  ),
                  FilterChip(
                    label: const Text('圈子关系'),
                    selected: _includeCircles,
                    onSelected: (selected) {
                      setState(() => _includeCircles = selected);
                    },
                  ),
                  FilterChip(
                    label: const Text('话题关注'),
                    selected: _includeTopics,
                    onSelected: (selected) {
                      setState(() => _includeTopics = selected);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('帖子、关注关系、私信、圈子和话题关注均支持真实导出。'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _creatingExport ? null : _createExport,
                icon: const Icon(Icons.archive_outlined),
                label: Text(_creatingExport ? '创建中...' : '创建导出任务'),
              ),
              const SizedBox(height: 16),
              ...data.exportTasks.map(_buildExportTask),
              if (data.exportTasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('还没有导出任务')),
                ),
              const SizedBox(height: 28),
              const Text(
                '协议留痕',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text('记录你确认过的用户协议和隐私政策版本，省得日后各说各话。'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _acceptingPolicyType == null
                        ? () => _acceptPolicy(1)
                        : null,
                    child: Text(
                      _acceptingPolicyType == 1 ? '记录中...' : '确认隐私政策',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _acceptingPolicyType == null
                        ? () => _acceptPolicy(2)
                        : null,
                    child: Text(
                      _acceptingPolicyType == 2 ? '记录中...' : '确认用户协议',
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('还没有协议同意记录。'),
                ),
              const SizedBox(height: 28),
              const Text(
                '设备管理',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text('登录设备会保留生命周期记录；未配置推送时不会冒充 FCM/APNs 已接通。'),
              const SizedBox(height: 12),
              ...data.devices.map(
                (device) => Card(
                  child: ListTile(
                    title: Text(
                      '${_platformName(device.platform)} · ${device.appVersion}',
                    ),
                    subtitle: Text(
                      '${device.deviceUid}\n${_deviceStatusText(device.status)} · 最近活跃 ${device.lastActiveAt ?? '—'}',
                    ),
                    isThreeLine: true,
                    trailing: device.active
                        ? TextButton(
                            onPressed: _loggingOutDeviceId == null
                                ? () => _logoutDevice(device)
                                : null,
                            child: Text(
                              _loggingOutDeviceId == device.id
                                  ? '停用中...'
                                  : '停用此设备',
                            ),
                          )
                        : Text(_deviceStatusText(device.status)),
                  ),
                ),
              ),
              if (data.devices.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('还没有登记设备。'),
                ),
              const SizedBox(height: 28),
              const Text(
                '账号删除',
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
      1 => '隐私政策',
      2 => '用户协议',
      3 => 'Cookie/营销告知',
      _ => '未知协议',
    };
  }

  String _platformName(int platform) {
    return switch (platform) {
      1 => 'iOS',
      2 => 'Android',
      3 => 'Web',
      _ => '未知设备',
    };
  }

  String _deviceStatusText(int status) {
    return switch (status) {
      1 => '启用',
      2 => '已停用',
      3 => '已登出',
      _ => '未知状态',
    };
  }

  Widget _buildExportTask(PrivacyExportTask task) {
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
                      '任务 #${task.id}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(task.statusText),
                ],
              ),
              const SizedBox(height: 8),
              Text(task.modules.join(' / ')),
              Text('创建于 ${task.createdAt}'),
              if (task.expireAt != null) Text('到期 ${task.expireAt}'),
              if (task.failReason.isNotEmpty)
                Text(
                  task.failReason,
                  style: const TextStyle(color: Colors.red),
                ),
              if (task.readyToDownload) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _downloadingTaskIds.contains(task.id)
                      ? null
                      : () => _download(task),
                  icon: const Icon(Icons.download_outlined),
                  label: Text(
                    _downloadingTaskIds.contains(task.id) ? '下载中...' : '下载 ZIP',
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
    return Card(
      color: const Color(0xFFFFF1EC),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '删除任务 #${task.id} · ${task.statusText}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text('原因：${task.reason}'),
            Text('冷静期截止：${task.coolingOffExpireAt ?? '—'}'),
            if (task.canCancel) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _cancellingDelete ? null : () => _cancelDelete(task),
                child: Text(_cancellingDelete ? '撤销中...' : '撤销删除申请'),
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
            const Text(
              '提交删除申请',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'code', label: Text('验证码校验')),
                ButtonSegment(value: 'password', label: Text('密码校验')),
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
                decoration: const InputDecoration(
                  labelText: '当前已绑定账号',
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
                decoration: const InputDecoration(
                  labelText: '当前已绑定账号',
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
                    decoration: const InputDecoration(
                      labelText: '注销验证码',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _sendingDeleteCode ? null : _sendDeleteCode,
                    child: Text(_sendingDeleteCode ? '发送中...' : '发送注销验证码'),
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
                decoration: const InputDecoration(
                  labelText: '当前登录密码',
                  border: OutlineInputBorder(),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('privacy-delete-reason'),
              controller: _reasonController,
              maxLength: 255,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '删除原因',
                border: OutlineInputBorder(),
              ),
            ),
            Text('提交后进入 ${rule.coolingOffDays} 天冷静期，到期前可以撤销。'),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('privacy-delete-submit'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: _submittingDelete ? null : _submitDelete,
              child: Text(_submittingDelete ? '提交中...' : '提交删除申请'),
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
    required this.exportTasks,
    required this.policyLogs,
    required this.devices,
  });

  final PrivacyOverview overview;
  final List<PrivacyExportTask> exportTasks;
  final List<PolicyAcceptLog> policyLogs;
  final List<UserDevice> devices;
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
