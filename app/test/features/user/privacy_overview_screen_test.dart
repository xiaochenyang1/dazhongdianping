import 'dart:async';
import 'dart:typed_data';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/features/user/privacy_export_saver.dart';
import 'package:dazhongdianping_app/features/user/privacy_overview_screen.dart';
import 'package:dazhongdianping_app/features/user/privacy_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class PrivacyScreenApi implements JsonApi, BinaryApi, JsonDeleteApi {
  PrivacyScreenApi({
    this.deleteStatus = 1,
    this.failFirstOverview = false,
    this.includeSecondDevice = false,
  });

  String? postedPath;
  Object? postedBody;
  bool exportCreated = false;
  int? deleteStatus;
  final bool failFirstOverview;
  final bool includeSecondDevice;
  int overviewRequests = 0;
  bool deviceLoggedOut = false;
  bool paginateExports = false;
  final List<int> requestedExportPages = <int>[];
  final Map<int, Completer<void>> exportPageGates = {};
  final Map<int, Completer<void>> policyAcceptGates = {};
  final Map<int, int> policyAcceptRequests = {};
  final Map<int, Completer<void>> deviceLogoutGates = {};
  final Map<int, int> deviceLogoutRequests = {};
  Completer<void>? createExportGate;
  int createExportRequests = 0;
  final Map<int, Completer<void>> downloadExportGates = {};
  final Map<int, int> downloadExportRequests = {};
  Completer<void>? cancelDeleteGate;
  int cancelDeleteRequests = 0;
  Completer<void>? submitDeleteGate;
  int submitDeleteRequests = 0;
  Completer<void>? sendDeleteCodeGate;
  int sendDeleteCodeRequests = 0;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (path == '/api/c/v1/privacy/overview') {
      overviewRequests++;
      if (failFirstOverview && overviewRequests == 1) {
        throw StateError('network unavailable');
      }
    }
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
            'status': deviceLoggedOut ? 3 : 1,
            'lastActiveAt': '2026-07-16 10:00:00',
            'createdAt': '2026-07-16 09:00:00',
            'updatedAt': '2026-07-16 10:00:00',
          },
          if (includeSecondDevice)
            {
              'id': 8,
              'deviceUid': 'ios-002',
              'platform': 3,
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
      final page = query?['page'] as int? ?? 1;
      requestedExportPages.add(page);
      await exportPageGates[page]?.future;
      return {
        'list': [_exportTask(page == 1 ? (exportCreated ? 10 : 8) : 7)],
        'total': paginateExports ? 2 : 1,
        'page': page,
        'pageSize': paginateExports ? 1 : 10,
      };
    }
    return {
      'exportRule': {
        'dailyLimit': 3,
        'defaultFormat': 'zip',
        'expireHours': 24,
      },
      'deleteRule': {'coolingOffDays': 7, 'reverifyRequired': true},
      'latestExportTask': _exportTask(),
      'latestDeleteTask': deleteStatus == null
          ? null
          : _deleteTask(deleteStatus!),
    };
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    postedPath = path;
    postedBody = body;
    if (path == '/api/c/v1/privacy/export-tasks') {
      createExportRequests++;
      await createExportGate?.future;
      exportCreated = true;
      return _exportTask(10);
    }
    if (path == '/api/c/v1/privacy/delete-tasks/9/cancel') {
      cancelDeleteRequests++;
      await cancelDeleteGate?.future;
      deleteStatus = 4;
      return _deleteTask(4);
    }
    if (path == '/api/c/v1/privacy/delete-tasks') {
      submitDeleteRequests++;
      await submitDeleteGate?.future;
      deleteStatus = 1;
      return _deleteTask(1);
    }
    if (path == '/api/c/v1/auth/send-code') {
      sendDeleteCodeRequests++;
      await sendDeleteCodeGate?.future;
      return {
        'sent': true,
        'expireSeconds': 300,
        'nextRetrySeconds': 60,
        'mockCode': '123456',
      };
    }
    if (path == '/api/c/v1/privacy/policies/accept') {
      final policyType = (body! as Map<String, dynamic>)['policyType'] as int;
      policyAcceptRequests.update(
        policyType,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      await policyAcceptGates[policyType]?.future;
      return {
        'id': 4,
        'policyType': policyType,
        'version': '2026.07',
        'locale': 'zh-CN',
        'source': 3,
        'requestIp': '127.0.0.1',
        'userAgent': 'Flutter/1.0',
        'acceptedAt': '2026-07-16 11:00:00',
      };
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path) async {
    postedPath = path;
    final deviceId = int.parse(path.split('/').last);
    deviceLogoutRequests.update(
      deviceId,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    await deviceLogoutGates[deviceId]?.future;
    if (deviceId == 7) deviceLoggedOut = true;
    return {
      'id': deviceId,
      'deviceUid': deviceId == 7 ? 'android-001' : 'ios-002',
      'platform': deviceId == 7 ? 2 : 3,
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
    final taskId = int.parse(path.split('/')[6]);
    downloadExportRequests.update(
      taskId,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
    await downloadExportGates[taskId]?.future;
    return Uint8List.fromList([1, 2, 3]);
  }

  Map<String, dynamic> _exportTask([int id = 8]) => {
    'id': id,
    'status': 2,
    'statusText': '可下载',
    'modules': ['account', 'reviews'],
    'format': 'zip',
    'downloadUrl': '/api/c/v1/privacy/export-tasks/8/download',
    'expireAt': '2026-07-16 10:00:00',
    'failReason': '',
    'createdAt': '2026-07-15 10:00:00',
    'updatedAt': '2026-07-15 10:00:01',
  };

  Map<String, dynamic> _deleteTask(int status) => {
    'id': 9,
    'status': status,
    'statusText': status == 1 ? '冷静期中' : '已取消',
    'verifyType': 'password',
    'account': 'user@example.com',
    'reason': '不再使用',
    'coolingOffExpireAt': '2026-07-22 10:00:00',
    'completedAt': null,
    'cancelledAt': status == 4 ? '2026-07-15 11:00:00' : null,
    'createdAt': '2026-07-15 10:00:00',
    'updatedAt': '2026-07-15 10:00:00',
  };
}

Future<void> scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    240,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('privacy center retries an initial overview failure', (
    tester,
  ) async {
    final api = PrivacyScreenApi(failFirstOverview: true);
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyOverviewScreen(
          repository: PrivacyRepository(api),
          accounts: const ['eu@example.com'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('隐私数据加载失败'), findsOneWidget);
    await tester.tap(find.byKey(const Key('privacy-overview-retry')));
    await tester.pumpAndSettle();

    expect(api.overviewRequests, 2);
    expect(find.text('数据导出'), findsWidgets);
  });

  testWidgets('privacy center loads older export tasks', (tester) async {
    final api = PrivacyScreenApi()..paginateExports = true;
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyOverviewScreen(
          repository: PrivacyRepository(api),
          accounts: const ['user@example.com'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await scrollTo(tester, find.byKey(const Key('privacy-exports-load-more')));
    await tester.tap(find.byKey(const Key('privacy-exports-load-more')));
    await tester.pumpAndSettle();

    expect(api.requestedExportPages, [1, 2]);
    await scrollTo(tester, find.text('任务 #7'));
    expect(find.text('任务 #7'), findsOneWidget);
    expect(find.byKey(const Key('privacy-exports-load-more')), findsNothing);
  });

  testWidgets('privacy center renders rules and active tasks', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyOverviewScreen(
          repository: PrivacyRepository(PrivacyScreenApi()),
          accounts: const ['user@example.com'],
          saver: PrivacyExportSaver(
            saveFile: (_, _) async => '/downloads/privacy.zip',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('每天最多 3 次'), findsOneWidget);
    expect(find.textContaining('7 天冷静期'), findsOneWidget);
    expect(find.text('订单数据'), findsOneWidget);
    expect(find.text('预订数据'), findsOneWidget);
    expect(find.text('收藏数据'), findsOneWidget);
    expect(find.text('关注关系'), findsOneWidget);
    expect(find.text('任务 #8'), findsOneWidget);
    expect(find.text('下载 ZIP'), findsOneWidget);
    await scrollTo(tester, find.text('协议留痕'));
    expect(find.text('协议留痕'), findsOneWidget);
    expect(find.textContaining('Flutter/1.0'), findsOneWidget);
    await scrollTo(tester, find.text('设备管理'));
    expect(find.text('设备管理'), findsOneWidget);
    expect(find.textContaining('android-001'), findsOneWidget);
    await scrollTo(tester, find.text('撤销删除申请'));
    expect(find.text('撤销删除申请'), findsOneWidget);
  });

  testWidgets(
    'privacy center records policy acceptance and logs out a device',
    (tester) async {
      final api = PrivacyScreenApi(deleteStatus: null);
      await tester.pumpWidget(
        MaterialApp(
          home: PrivacyOverviewScreen(
            repository: PrivacyRepository(api),
            accounts: const ['user@example.com'],
            saver: PrivacyExportSaver(
              saveFile: (_, _) async => '/downloads/privacy.zip',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('确认隐私政策'));
      await tester.tap(find.text('确认隐私政策'));
      await tester.pumpAndSettle();

      expect(api.postedPath, '/api/c/v1/privacy/policies/accept');
      expect(api.postedBody, {
        'policyType': 1,
        'version': '2026.07',
        'locale': 'zh-CN',
        'source': 3,
      });

      await scrollTo(tester, find.text('停用此设备'));
      await tester.tap(find.text('停用此设备'));
      await tester.pumpAndSettle();
      expect(api.postedPath, '/api/c/v1/devices/7');
      await scrollTo(tester, find.text('已登出'));
      expect(find.text('已登出'), findsOneWidget);
    },
  );

  testWidgets('privacy policy actions guard duplicates independently', (
    tester,
  ) async {
    final api = PrivacyScreenApi(deleteStatus: null)
      ..policyAcceptGates[1] = Completer<void>()
      ..policyAcceptGates[2] = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyOverviewScreen(
          repository: PrivacyRepository(api),
          accounts: const ['user@example.com'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final policy1 = find.byKey(const Key('privacy-accept-policy-1'));
    final policy2 = find.byKey(const Key('privacy-accept-policy-2'));
    await scrollTo(tester, policy1);
    await tester.tap(policy1);
    await tester.tap(policy1, warnIfMissed: false);
    await tester.tap(policy2);
    await tester.pump();

    expect(api.policyAcceptRequests, {1: 1, 2: 1});
    api.policyAcceptGates[1]!.complete();
    api.policyAcceptGates[2]!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('device logout actions guard duplicates independently', (
    tester,
  ) async {
    final api = PrivacyScreenApi(deleteStatus: null, includeSecondDevice: true)
      ..deviceLogoutGates[7] = Completer<void>()
      ..deviceLogoutGates[8] = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyOverviewScreen(
          repository: PrivacyRepository(api),
          accounts: const ['user@example.com'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final device7 = find.byKey(const Key('privacy-logout-device-7'));
    final device8 = find.byKey(
      const Key('privacy-logout-device-8'),
      skipOffstage: false,
    );
    await scrollTo(tester, device7);
    await tester.tap(device7);
    await tester.tap(device7, warnIfMissed: false);
    await tester.ensureVisible(device8);
    await tester.tap(device8);
    await tester.pump();

    expect(api.deviceLogoutRequests, {7: 1, 8: 1});
    api.deviceLogoutGates[7]!.complete();
    api.deviceLogoutGates[8]!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('privacy center downloads and saves a ready export', (
    tester,
  ) async {
    int? savedTaskId;
    Uint8List? savedBytes;
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyOverviewScreen(
          repository: PrivacyRepository(PrivacyScreenApi()),
          accounts: const ['user@example.com'],
          saver: PrivacyExportSaver(
            saveFile: (name, bytes) async {
              savedTaskId = int.parse(name.split('-').last);
              savedBytes = bytes;
              return '/downloads/$name.zip';
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('下载 ZIP'));
    await tester.tap(find.text('下载 ZIP'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(savedTaskId, 8);
    expect(savedBytes, [1, 2, 3]);
    expect(find.textContaining('已保存'), findsOneWidget);
  });

  testWidgets('privacy center guards duplicate export downloads', (
    tester,
  ) async {
    final api = PrivacyScreenApi()..downloadExportGates[8] = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyOverviewScreen(
          repository: PrivacyRepository(api),
          accounts: const ['user@example.com'],
          saver: PrivacyExportSaver(
            saveFile: (_, _) async => '/tmp/export.zip',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final download = find.byKey(const Key('privacy-download-export-8'));
    await scrollTo(tester, download);
    await tester.tap(download);
    await tester.tap(download);

    expect(api.downloadExportRequests, {8: 1});
    api.downloadExportGates[8]!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('privacy center creates an export for selected modules', (
    tester,
  ) async {
    final api = PrivacyScreenApi();
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyOverviewScreen(
          repository: PrivacyRepository(api),
          accounts: const ['user@example.com'],
          saver: PrivacyExportSaver(
            saveFile: (_, _) async => '/downloads/privacy.zip',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('创建导出任务'));
    await tester.pumpAndSettle();

    expect(api.postedPath, '/api/c/v1/privacy/export-tasks');
    expect(api.postedBody, {
      'modules': [
        'account',
        'reviews',
        'posts',
        'orders',
        'reservations',
        'favorites',
        'follows',
        'messages',
        'circles',
        'topics',
      ],
      'format': 'zip',
    });
    expect(find.text('帖子数据'), findsOneWidget);
    expect(find.text('关注关系'), findsOneWidget);
    expect(find.text('圈子关系'), findsOneWidget);
    expect(find.text('话题关注'), findsOneWidget);
    expect(find.text('帖子、关注关系、私信、圈子和话题关注均支持真实导出。'), findsOneWidget);
    expect(find.text('任务 #10'), findsOneWidget);
  });

  testWidgets('privacy center guards duplicate export creation', (
    tester,
  ) async {
    final api = PrivacyScreenApi()..createExportGate = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyOverviewScreen(
          repository: PrivacyRepository(api),
          accounts: const ['user@example.com'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final create = find.byKey(const Key('privacy-create-export'));
    await tester.tap(create);
    await tester.tap(create);

    expect(api.createExportRequests, 1);
    api.createExportGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('privacy reload discards an in-flight export page', (
    tester,
  ) async {
    final api = PrivacyScreenApi()..paginateExports = true;
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyOverviewScreen(
          repository: PrivacyRepository(api),
          accounts: const ['user@example.com'],
        ),
      ),
    );
    await tester.pumpAndSettle();
    api.exportPageGates[2] = Completer<void>();

    final create = find.byKey(const Key('privacy-create-export'));
    await scrollTo(tester, create);
    final createAction = tester.widget<FilledButton>(create).onPressed!;
    final loadMore = find.byKey(const Key('privacy-exports-load-more'));
    await scrollTo(tester, loadMore);
    await tester.tap(loadMore);
    createAction();
    await tester.pumpAndSettle();

    expect(find.text('任务 #10'), findsOneWidget);
    api.exportPageGates[2]!.complete();
    await tester.pumpAndSettle();

    expect(find.text('任务 #10'), findsOneWidget);
    expect(find.text('任务 #7'), findsNothing);
  });

  testWidgets('privacy center cancels an active delete task', (tester) async {
    final api = PrivacyScreenApi();
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyOverviewScreen(
          repository: PrivacyRepository(api),
          accounts: const ['user@example.com'],
          saver: PrivacyExportSaver(
            saveFile: (_, _) async => '/downloads/privacy.zip',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('撤销删除申请'));
    await tester.tap(find.text('撤销删除申请'));
    await tester.pumpAndSettle();

    expect(api.postedPath, '/api/c/v1/privacy/delete-tasks/9/cancel');
    await scrollTo(tester, find.textContaining('已取消'));
    expect(find.textContaining('已取消'), findsOneWidget);
    expect(find.text('撤销删除申请'), findsNothing);
  });

  testWidgets('privacy center guards duplicate delete cancellation', (
    tester,
  ) async {
    final api = PrivacyScreenApi()..cancelDeleteGate = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyOverviewScreen(
          repository: PrivacyRepository(api),
          accounts: const ['user@example.com'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cancel = find.byKey(const Key('privacy-cancel-delete-9'));
    await scrollTo(tester, cancel);
    await tester.tap(cancel);
    await tester.tap(cancel);

    expect(api.cancelDeleteRequests, 1);
    api.cancelDeleteGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('privacy center submits a password-verified delete task', (
    tester,
  ) async {
    final api = PrivacyScreenApi(deleteStatus: null);
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyOverviewScreen(
          repository: PrivacyRepository(api),
          accounts: const ['user@example.com'],
          saver: PrivacyExportSaver(
            saveFile: (_, _) async => '/downloads/privacy.zip',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('密码校验'));
    await tester.tap(find.text('密码校验'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('privacy-delete-password')),
      'secret',
    );
    await tester.enterText(
      find.byKey(const Key('privacy-delete-reason')),
      '不再使用',
    );
    await scrollTo(tester, find.byKey(const Key('privacy-delete-submit')));
    await tester.tap(find.byKey(const Key('privacy-delete-submit')));
    await tester.pumpAndSettle();

    expect(api.postedPath, '/api/c/v1/privacy/delete-tasks');
    expect(api.postedBody, {
      'verifyType': 'password',
      'account': 'user@example.com',
      'password': 'secret',
      'reason': '不再使用',
    });
  });

  testWidgets('privacy center guards duplicate delete submission', (
    tester,
  ) async {
    final api = PrivacyScreenApi(deleteStatus: null)
      ..submitDeleteGate = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyOverviewScreen(
          repository: PrivacyRepository(api),
          accounts: const ['user@example.com'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('密码校验'));
    await tester.tap(find.text('密码校验'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('privacy-delete-password')),
      'secret',
    );
    await tester.enterText(
      find.byKey(const Key('privacy-delete-reason')),
      '不再使用',
    );
    final submit = find.byKey(const Key('privacy-delete-submit'));
    await scrollTo(tester, submit);
    await tester.tap(submit);
    await tester.tap(submit);

    expect(api.submitDeleteRequests, 1);
    api.submitDeleteGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('privacy center sends a deletion verification code', (
    tester,
  ) async {
    final api = PrivacyScreenApi(deleteStatus: null);
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyOverviewScreen(
          repository: PrivacyRepository(api),
          accounts: const ['user@example.com'],
          saver: PrivacyExportSaver(
            saveFile: (_, _) async => '/downloads/privacy.zip',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('发送注销验证码'));
    await tester.tap(find.text('发送注销验证码'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(api.postedPath, '/api/c/v1/auth/send-code');
    expect(api.postedBody, {
      'scene': 'delete',
      'type': 'email',
      'account': 'user@example.com',
      'deviceId': 'flutter-app',
    });
    expect(find.textContaining('123456'), findsOneWidget);
  });

  testWidgets('privacy center guards duplicate deletion codes', (tester) async {
    final api = PrivacyScreenApi(deleteStatus: null)
      ..sendDeleteCodeGate = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyOverviewScreen(
          repository: PrivacyRepository(api),
          accounts: const ['user@example.com'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final send = find.byKey(const Key('privacy-send-delete-code'));
    await scrollTo(tester, send);
    await tester.tap(send);
    await tester.tap(send);

    expect(api.sendDeleteCodeRequests, 1);
    api.sendDeleteCodeGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('privacy center fits a mobile viewport', (tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyOverviewScreen(
          repository: PrivacyRepository(PrivacyScreenApi(deleteStatus: null)),
          accounts: const ['user@example.com'],
          saver: PrivacyExportSaver(
            saveFile: (_, _) async => '/downloads/privacy.zip',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await scrollTo(tester, find.byKey(const Key('privacy-delete-submit')));

    expect(find.byKey(const Key('privacy-delete-submit')), findsOneWidget);
    final exception = tester.takeException();
    if (exception is FlutterError) {
      fail(exception.toStringDeep());
    }
    expect(exception, isNull);
  });
}
