import 'dart:typed_data';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/user/privacy_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class PrivacyFakeApi implements JsonApi, BinaryApi, JsonDeleteApi {
  String? path;
  Map<String, Object?>? query;
  Object? body;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    this.path = path;
    this.query = query;
    if (path == '/api/c/v1/privacy/policies') {
      return {
        'value': [
          {
            'id': 3,
            'policyType': 1,
            'version': '2026.07',
            'locale': 'zh-CN',
            'source': 3,
            'requestIp': '127.0.0.1',
            'userAgent': 'Flutter/1.0',
            'acceptedAt': '2026-07-16 10:00:00',
          },
        ],
      };
    }
    if (path == '/api/c/v1/devices') {
      return {
        'value': [
          {
            'id': 7,
            'deviceUid': 'android-001',
            'platform': 2,
            'pushChannel': 0,
            'pushTokenSet': false,
            'appVersion': '1.0.0',
            'status': 1,
            'lastActiveAt': '2026-07-16 10:00:00',
            'createdAt': '2026-07-16 09:00:00',
            'updatedAt': '2026-07-16 10:00:00',
          },
        ],
      };
    }
    if (path == '/api/c/v1/privacy/export-tasks') {
      return {
        'list': [
          {
            'id': 8,
            'status': 2,
            'statusText': '可下载',
            'modules': ['account'],
            'format': 'zip',
            'downloadUrl': '/api/c/v1/privacy/export-tasks/8/download',
            'expireAt': '2026-07-16 10:00:00',
            'failReason': '',
            'createdAt': '2026-07-15 10:00:00',
            'updatedAt': '2026-07-15 10:00:01',
          },
        ],
        'total': 1,
      };
    }
    return {
      'exportRule': {
        'dailyLimit': 3,
        'defaultFormat': 'zip',
        'expireHours': 24,
      },
      'deleteRule': {'coolingOffDays': 7, 'reverifyRequired': true},
      'latestExportTask': {
        'id': 8,
        'status': 2,
        'statusText': '可下载',
        'modules': ['account', 'reviews'],
        'format': 'zip',
        'downloadUrl': '/api/c/v1/privacy/export-tasks/8/download',
        'expireAt': '2026-07-16 10:00:00',
        'failReason': '',
        'createdAt': '2026-07-15 10:00:00',
        'updatedAt': '2026-07-15 10:00:01',
      },
      'latestDeleteTask': {
        'id': 9,
        'status': 1,
        'statusText': '冷静期中',
        'verifyType': 'password',
        'account': 'user@example.com',
        'reason': '不再使用',
        'coolingOffExpireAt': '2026-07-22 10:00:00',
        'completedAt': null,
        'cancelledAt': null,
        'createdAt': '2026-07-15 10:00:00',
        'updatedAt': '2026-07-15 10:00:00',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    this.path = path;
    this.body = body;
    if (path == '/api/c/v1/privacy/export-tasks') {
      return {
        'id': 10,
        'status': 2,
        'statusText': '可下载',
        'modules': ['account', 'reviews'],
        'format': 'zip',
        'downloadUrl': '/api/c/v1/privacy/export-tasks/10/download',
        'expireAt': '2026-07-16 10:00:00',
        'failReason': '',
        'createdAt': '2026-07-15 10:00:00',
        'updatedAt': '2026-07-15 10:00:01',
      };
    }
    if (path == '/api/c/v1/privacy/delete-tasks') {
      return {
        'id': 11,
        'status': 1,
        'statusText': '冷静期中',
        'verifyType': 'password',
        'account': 'user@example.com',
        'reason': '不再使用',
        'coolingOffExpireAt': '2026-07-22 10:00:00',
        'completedAt': null,
        'cancelledAt': null,
        'createdAt': '2026-07-15 10:00:00',
        'updatedAt': '2026-07-15 10:00:00',
      };
    }
    if (path == '/api/c/v1/privacy/delete-tasks/9/cancel') {
      return {
        'id': 9,
        'status': 4,
        'statusText': '已取消',
        'verifyType': 'password',
        'account': 'user@example.com',
        'reason': '不再使用',
        'coolingOffExpireAt': '2026-07-22 10:00:00',
        'completedAt': null,
        'cancelledAt': '2026-07-15 11:00:00',
        'createdAt': '2026-07-15 10:00:00',
        'updatedAt': '2026-07-15 11:00:00',
      };
    }
    if (path == '/api/c/v1/auth/send-code') {
      return {
        'sent': true,
        'expireSeconds': 300,
        'nextRetrySeconds': 60,
        'mockCode': '123456',
      };
    }
    if (path == '/api/c/v1/privacy/policies/accept') {
      return {
        'id': 4,
        'policyType': 2,
        'version': '2026.07',
        'locale': 'zh-CN',
        'source': 3,
        'requestIp': '127.0.0.1',
        'userAgent': 'Flutter/1.0',
        'acceptedAt': '2026-07-16 11:00:00',
      };
    }
    if (path == '/api/c/v1/devices/register') {
      return {
        'id': 7,
        'deviceUid': 'android-001',
        'platform': 2,
        'pushChannel': 0,
        'pushTokenSet': false,
        'appVersion': '1.0.0',
        'status': 1,
        'lastActiveAt': '2026-07-16 10:00:00',
        'createdAt': '2026-07-16 09:00:00',
        'updatedAt': '2026-07-16 10:00:00',
      };
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path) async {
    this.path = path;
    return {
      'id': 7,
      'deviceUid': 'android-001',
      'platform': 2,
      'pushChannel': 0,
      'pushTokenSet': false,
      'appVersion': '1.0.0',
      'status': 3,
      'lastActiveAt': '2026-07-16 12:00:00',
      'createdAt': '2026-07-16 09:00:00',
      'updatedAt': '2026-07-16 12:00:00',
    };
  }

  @override
  Future<Uint8List> getBytes(String path) async {
    this.path = path;
    return Uint8List.fromList([1, 2, 3]);
  }
}

void main() {
  test('privacy repository maps overview rules and latest tasks', () async {
    final repository = PrivacyRepository(PrivacyFakeApi());

    final overview = await repository.loadOverview();

    expect(overview.exportRule.dailyLimit, 3);
    expect(overview.exportRule.expireHours, 24);
    expect(overview.deleteRule.coolingOffDays, 7);
    expect(overview.latestExportTask?.readyToDownload, isTrue);
    expect(overview.latestDeleteTask?.canCancel, isTrue);
  });

  test('privacy repository loads export task history', () async {
    final api = PrivacyFakeApi();
    final repository = PrivacyRepository(api);

    final page = await repository.loadExportTasks();

    expect(api.path, '/api/c/v1/privacy/export-tasks');
    expect(api.query, {'page': 1, 'pageSize': 10});
    expect(page.total, 1);
    expect(page.items.single.modules, ['account']);
  });

  test('privacy repository creates an export task', () async {
    final api = PrivacyFakeApi();
    final repository = PrivacyRepository(api);

    final task = await repository.createExportTask(['account', 'reviews']);

    expect(api.path, '/api/c/v1/privacy/export-tasks');
    expect(api.body, {
      'modules': ['account', 'reviews'],
      'format': 'zip',
    });
    expect(task.id, 10);
    expect(task.readyToDownload, isTrue);
  });

  test(
    'privacy repository downloads an authenticated export archive',
    () async {
      final api = PrivacyFakeApi();
      final repository = PrivacyRepository(api);

      final bytes = await repository.downloadExport(8);

      expect(api.path, '/api/c/v1/privacy/export-tasks/8/download');
      expect(bytes, [1, 2, 3]);
    },
  );

  test('privacy repository creates a password-verified delete task', () async {
    final api = PrivacyFakeApi();
    final repository = PrivacyRepository(api);

    final task = await repository.createDeleteTask(
      verifyType: 'password',
      account: 'user@example.com',
      password: 'secret',
      reason: '不再使用',
    );

    expect(api.path, '/api/c/v1/privacy/delete-tasks');
    expect(api.body, {
      'verifyType': 'password',
      'account': 'user@example.com',
      'password': 'secret',
      'reason': '不再使用',
    });
    expect(task.id, 11);
    expect(task.canCancel, isTrue);
  });

  test(
    'privacy repository cancels a delete task in its cooling-off period',
    () async {
      final api = PrivacyFakeApi();
      final repository = PrivacyRepository(api);

      final task = await repository.cancelDeleteTask(9);

      expect(api.path, '/api/c/v1/privacy/delete-tasks/9/cancel');
      expect(task.statusText, '已取消');
      expect(task.canCancel, isFalse);
    },
  );

  test(
    'privacy repository sends an account deletion verification code',
    () async {
      final api = PrivacyFakeApi();
      final repository = PrivacyRepository(api);

      final result = await repository.sendDeleteCode('user@example.com');

      expect(api.path, '/api/c/v1/auth/send-code');
      expect(api.body, {
        'scene': 'delete',
        'type': 'email',
        'account': 'user@example.com',
        'deviceId': 'flutter-app',
      });
      expect(result.mockCode, '123456');
    },
  );

  test('privacy repository records and lists policy acceptance', () async {
    final api = PrivacyFakeApi();
    final repository = PrivacyRepository(api);

    final logs = await repository.loadPolicyLogs();
    final accepted = await repository.acceptPolicy(
      policyType: 2,
      version: '2026.07',
      locale: 'zh-CN',
    );

    expect(logs.single.policyType, 1);
    expect(logs.single.userAgent, 'Flutter/1.0');
    expect(api.path, '/api/c/v1/privacy/policies/accept');
    expect(api.body, {
      'policyType': 2,
      'version': '2026.07',
      'locale': 'zh-CN',
      'source': 3,
    });
    expect(accepted.policyType, 2);
  });

  test('privacy repository registers lists and logs out a device', () async {
    final api = PrivacyFakeApi();
    final repository = PrivacyRepository(api);

    final devices = await repository.loadDevices();
    final registered = await repository.registerDevice(
      deviceUid: 'android-001',
      platform: 2,
      appVersion: '1.0.0',
    );
    final loggedOut = await repository.logoutDevice(7);

    expect(devices.single.deviceUid, 'android-001');
    expect(registered.active, isTrue);
    expect(api.path, '/api/c/v1/devices/7');
    expect(loggedOut.status, 3);
  });
}
