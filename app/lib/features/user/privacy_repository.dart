import 'dart:typed_data';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/auth/auth_repository.dart';

class PrivacyExportRule {
  const PrivacyExportRule({
    required this.dailyLimit,
    required this.defaultFormat,
    required this.expireHours,
  });

  final int dailyLimit;
  final String defaultFormat;
  final int expireHours;

  factory PrivacyExportRule.fromJson(Map<String, dynamic> json) {
    return PrivacyExportRule(
      dailyLimit: (json['dailyLimit'] as num?)?.toInt() ?? 0,
      defaultFormat: json['defaultFormat'] as String? ?? 'zip',
      expireHours: (json['expireHours'] as num?)?.toInt() ?? 0,
    );
  }
}

class PrivacyDeleteRule {
  const PrivacyDeleteRule({
    required this.coolingOffDays,
    required this.reverifyRequired,
  });

  final int coolingOffDays;
  final bool reverifyRequired;

  factory PrivacyDeleteRule.fromJson(Map<String, dynamic> json) {
    return PrivacyDeleteRule(
      coolingOffDays: (json['coolingOffDays'] as num?)?.toInt() ?? 0,
      reverifyRequired: json['reverifyRequired'] as bool? ?? true,
    );
  }
}

class PrivacyExportTask {
  const PrivacyExportTask({
    required this.id,
    required this.status,
    required this.statusText,
    required this.modules,
    required this.format,
    required this.downloadUrl,
    required this.expireAt,
    required this.failReason,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int status;
  final String statusText;
  final List<String> modules;
  final String format;
  final String downloadUrl;
  final String? expireAt;
  final String failReason;
  final String createdAt;
  final String updatedAt;

  bool get readyToDownload => status == 2 && downloadUrl.isNotEmpty;

  factory PrivacyExportTask.fromJson(Map<String, dynamic> json) {
    return PrivacyExportTask(
      id: (json['id'] as num).toInt(),
      status: (json['status'] as num?)?.toInt() ?? 0,
      statusText: json['statusText'] as String? ?? '',
      modules: (json['modules'] as List<dynamic>? ?? const []).cast<String>(),
      format: json['format'] as String? ?? 'zip',
      downloadUrl: json['downloadUrl'] as String? ?? '',
      expireAt: json['expireAt'] as String?,
      failReason: json['failReason'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}

class PrivacyDeleteTask {
  const PrivacyDeleteTask({
    required this.id,
    required this.status,
    required this.statusText,
    required this.verifyType,
    required this.account,
    required this.reason,
    required this.coolingOffExpireAt,
    required this.completedAt,
    required this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int status;
  final String statusText;
  final String verifyType;
  final String account;
  final String reason;
  final String? coolingOffExpireAt;
  final String? completedAt;
  final String? cancelledAt;
  final String createdAt;
  final String updatedAt;

  bool get canCancel => status == 1;

  factory PrivacyDeleteTask.fromJson(Map<String, dynamic> json) {
    return PrivacyDeleteTask(
      id: (json['id'] as num).toInt(),
      status: (json['status'] as num?)?.toInt() ?? 0,
      statusText: json['statusText'] as String? ?? '',
      verifyType: json['verifyType'] as String? ?? '',
      account: json['account'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      coolingOffExpireAt: json['coolingOffExpireAt'] as String?,
      completedAt: json['completedAt'] as String?,
      cancelledAt: json['cancelledAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}

class PrivacyOverview {
  const PrivacyOverview({
    required this.exportRule,
    required this.deleteRule,
    required this.latestExportTask,
    required this.latestDeleteTask,
  });

  final PrivacyExportRule exportRule;
  final PrivacyDeleteRule deleteRule;
  final PrivacyExportTask? latestExportTask;
  final PrivacyDeleteTask? latestDeleteTask;

  factory PrivacyOverview.fromJson(Map<String, dynamic> json) {
    final latestExportTask = json['latestExportTask'];
    final latestDeleteTask = json['latestDeleteTask'];
    return PrivacyOverview(
      exportRule: PrivacyExportRule.fromJson(
        json['exportRule'] as Map<String, dynamic>? ?? const {},
      ),
      deleteRule: PrivacyDeleteRule.fromJson(
        json['deleteRule'] as Map<String, dynamic>? ?? const {},
      ),
      latestExportTask: latestExportTask is Map<String, dynamic>
          ? PrivacyExportTask.fromJson(latestExportTask)
          : null,
      latestDeleteTask: latestDeleteTask is Map<String, dynamic>
          ? PrivacyDeleteTask.fromJson(latestDeleteTask)
          : null,
    );
  }
}

class PrivacyExportTaskPage {
  const PrivacyExportTaskPage({required this.items, required this.total});

  final List<PrivacyExportTask> items;
  final int total;
}

class PolicyAcceptLog {
  const PolicyAcceptLog({
    required this.id,
    required this.policyType,
    required this.version,
    required this.locale,
    required this.source,
    required this.requestIp,
    required this.userAgent,
    required this.acceptedAt,
  });

  final int id;
  final int policyType;
  final String version;
  final String locale;
  final int source;
  final String requestIp;
  final String userAgent;
  final String acceptedAt;

  factory PolicyAcceptLog.fromJson(Map<String, dynamic> json) {
    return PolicyAcceptLog(
      id: (json['id'] as num).toInt(),
      policyType: (json['policyType'] as num?)?.toInt() ?? 0,
      version: json['version'] as String? ?? '',
      locale: json['locale'] as String? ?? '',
      source: (json['source'] as num?)?.toInt() ?? 0,
      requestIp: json['requestIp'] as String? ?? '',
      userAgent: json['userAgent'] as String? ?? '',
      acceptedAt: json['acceptedAt'] as String? ?? '',
    );
  }
}

class UserDevice {
  const UserDevice({
    required this.id,
    required this.deviceUid,
    required this.platform,
    required this.pushChannel,
    required this.pushTokenSet,
    required this.appVersion,
    required this.status,
    required this.lastActiveAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String deviceUid;
  final int platform;
  final int pushChannel;
  final bool pushTokenSet;
  final String appVersion;
  final int status;
  final String? lastActiveAt;
  final String createdAt;
  final String updatedAt;

  bool get active => status == 1;

  factory UserDevice.fromJson(Map<String, dynamic> json) {
    return UserDevice(
      id: (json['id'] as num).toInt(),
      deviceUid: json['deviceUid'] as String? ?? '',
      platform: (json['platform'] as num?)?.toInt() ?? 0,
      pushChannel: (json['pushChannel'] as num?)?.toInt() ?? 0,
      pushTokenSet: json['pushTokenSet'] as bool? ?? false,
      appVersion: json['appVersion'] as String? ?? '',
      status: (json['status'] as num?)?.toInt() ?? 0,
      lastActiveAt: json['lastActiveAt'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}

class PrivacyRepository {
  PrivacyRepository(this.api);

  final JsonApi api;

  Future<PrivacyOverview> loadOverview() async {
    return PrivacyOverview.fromJson(
      await api.getJson('/api/c/v1/privacy/overview'),
    );
  }

  Future<PrivacyExportTaskPage> loadExportTasks() async {
    final result = await api.getJson(
      '/api/c/v1/privacy/export-tasks',
      query: const {'page': 1, 'pageSize': 10},
    );
    final list = result['list'] as List<dynamic>? ?? const [];
    final items = list
        .cast<Map<String, dynamic>>()
        .map(PrivacyExportTask.fromJson)
        .toList();
    return PrivacyExportTaskPage(
      items: items,
      total: (result['total'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<PrivacyExportTask> createExportTask(List<String> modules) async {
    final result = await api.postJson(
      '/api/c/v1/privacy/export-tasks',
      body: {'modules': modules, 'format': 'zip'},
    );
    return PrivacyExportTask.fromJson(result);
  }

  Future<Uint8List> downloadExport(int taskId) {
    if (api is! BinaryApi) {
      throw StateError('当前 API 客户端不支持文件下载');
    }
    return (api as BinaryApi).getBytes(
      '/api/c/v1/privacy/export-tasks/$taskId/download',
    );
  }

  Future<PrivacyDeleteTask> createDeleteTask({
    required String verifyType,
    required String account,
    String? verifyCode,
    String? password,
    required String reason,
  }) async {
    final result = await api.postJson(
      '/api/c/v1/privacy/delete-tasks',
      body: {
        'verifyType': verifyType,
        'account': account,
        if (verifyCode != null && verifyCode.isNotEmpty)
          'verifyCode': verifyCode,
        if (password != null && password.isNotEmpty) 'password': password,
        'reason': reason,
      },
    );
    return PrivacyDeleteTask.fromJson(result);
  }

  Future<PrivacyDeleteTask> cancelDeleteTask(int taskId) async {
    final result = await api.postJson(
      '/api/c/v1/privacy/delete-tasks/$taskId/cancel',
    );
    return PrivacyDeleteTask.fromJson(result);
  }

  Future<SendCodeResult> sendDeleteCode(String account) async {
    final result = await api.postJson(
      '/api/c/v1/auth/send-code',
      body: {
        'scene': 'delete',
        'type': account.contains('@') ? 'email' : 'phone',
        'account': account,
        'deviceId': 'flutter-app',
      },
    );
    return SendCodeResult.fromJson(result);
  }

  Future<List<PolicyAcceptLog>> loadPolicyLogs() async {
    final result = await api.getJson('/api/c/v1/privacy/policies');
    final list = result['value'] as List<dynamic>? ?? const [];
    return list
        .cast<Map<String, dynamic>>()
        .map(PolicyAcceptLog.fromJson)
        .toList();
  }

  Future<PolicyAcceptLog> acceptPolicy({
    required int policyType,
    required String version,
    required String locale,
  }) async {
    final result = await api.postJson(
      '/api/c/v1/privacy/policies/accept',
      body: {
        'policyType': policyType,
        'version': version,
        'locale': locale,
        'source': 3,
      },
    );
    return PolicyAcceptLog.fromJson(result);
  }

  Future<List<UserDevice>> loadDevices() async {
    final result = await api.getJson('/api/c/v1/devices');
    final list = result['value'] as List<dynamic>? ?? const [];
    return list.cast<Map<String, dynamic>>().map(UserDevice.fromJson).toList();
  }

  Future<UserDevice> registerDevice({
    required String deviceUid,
    required int platform,
    required String appVersion,
    int pushChannel = 0,
    String pushToken = '',
  }) async {
    final result = await api.postJson(
      '/api/c/v1/devices/register',
      body: {
        'deviceUid': deviceUid,
        'platform': platform,
        'pushChannel': pushChannel,
        'pushToken': pushToken,
        'appVersion': appVersion,
      },
    );
    return UserDevice.fromJson(result);
  }

  Future<UserDevice> logoutDevice(int deviceId) async {
    if (api is! JsonDeleteApi) {
      throw StateError('当前 API 客户端不支持设备登出');
    }
    final result = await (api as JsonDeleteApi).deleteJson(
      '/api/c/v1/devices/$deviceId',
    );
    return UserDevice.fromJson(result);
  }
}
