import 'dart:async';

import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/push_service.dart';
import 'package:dazhongdianping_app/core/third_party_config.dart';
import 'package:dazhongdianping_app/features/user/device_lifecycle.dart';
import 'package:dazhongdianping_app/features/user/privacy_repository.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _device({
  int id = 7,
  int pushChannel = 0,
  bool pushTokenSet = false,
  int status = 1,
}) {
  return {
    'id': id,
    'deviceUid': 'test-device-uid',
    'platform': 2,
    'pushChannel': pushChannel,
    'pushTokenSet': pushTokenSet,
    'appVersion': '1.0.0',
    'status': status,
    'lastActiveAt': '2026-08-03 10:00:00',
    'createdAt': '2026-08-03 09:00:00',
    'updatedAt': '2026-08-03 10:00:00',
  };
}

class DeviceFakeApi implements JsonApi, JsonMutationApi, JsonDeleteApi {
  final List<String> putPaths = [];
  final List<Object?> putBodies = [];
  Object? registerBody;
  bool failPut = false;

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async {
    if (path == '/api/c/v1/devices') {
      return {
        'value': [_device()],
      };
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async {
    registerBody = body;
    return _device(id: 7);
  }

  @override
  Future<Map<String, dynamic>> putJson(String path, {Object? body}) async {
    putPaths.add(path);
    putBodies.add(body);
    if (failPut) {
      throw const ApiException('push token sync failed');
    }
    return _device(pushChannel: 2, pushTokenSet: true);
  }

  @override
  Future<Map<String, dynamic>> deleteJson(String path) async {
    return _device(status: 3);
  }
}

class FakePushTokenService implements PushTokenService {
  FakePushTokenService({this.token = 'initial-token', this.channel = 2});

  final String? token;
  final int channel;
  final StreamController<String> controller = StreamController<String>.broadcast();

  @override
  Future<String?> getPushToken() async => token;

  @override
  Future<int> getPushChannel() async => channel;

  @override
  Stream<String> get onTokenRefresh => controller.stream;
}

ApiDeviceLifecycle _lifecycle(
  DeviceFakeApi api,
  PushTokenService? push, {
  bool pushEnabled = true,
}) {
  return ApiDeviceLifecycle(
    repository: PrivacyRepository(api),
    identityStore: MemoryDeviceIdentityStore(),
    thirdPartyConfig: ThirdPartyConfig(firebaseConfigured: pushEnabled),
    pushTokenService: push,
    platformProvider: () => 2,
  );
}

void main() {
  test('device lifecycle registers with the current push token', () async {
    final api = DeviceFakeApi();
    final lifecycle = _lifecycle(api, FakePushTokenService());

    await lifecycle.registerCurrentDevice();

    expect(api.registerBody, {
      'deviceUid': 'test-device-uid',
      'platform': 2,
      'pushChannel': 2,
      'pushToken': 'initial-token',
      'appVersion': '1.0.0',
    });

    await lifecycle.dispose();
  });

  test('device lifecycle pushes a rotated token back to the server', () async {
    final api = DeviceFakeApi();
    final push = FakePushTokenService();
    final lifecycle = _lifecycle(api, push);

    await lifecycle.registerCurrentDevice();
    push.controller.add('rotated-token');
    await pumpEventQueue();

    expect(api.putPaths, ['/api/c/v1/devices/7/push-token']);
    expect(api.putBodies.single, {
      'pushChannel': 2,
      'pushToken': 'rotated-token',
      'appVersion': '1.0.0',
    });

    await lifecycle.dispose();
  });

  test('device lifecycle registers without push and accepts a later token', () async {
    final api = DeviceFakeApi();
    final push = FakePushTokenService(token: null);
    final lifecycle = _lifecycle(api, push);

    await lifecycle.registerCurrentDevice();
    expect((api.registerBody! as Map)['pushChannel'], 0);
    expect((api.registerBody! as Map)['pushToken'], '');

    push.controller.add('late-token');
    await pumpEventQueue();

    expect(api.putBodies.single, {
      'pushChannel': 2,
      'pushToken': 'late-token',
      'appVersion': '1.0.0',
    });

    await lifecycle.dispose();
  });

  test('device lifecycle keeps listening after a failed sync', () async {
    final api = DeviceFakeApi()..failPut = true;
    final push = FakePushTokenService();
    final lifecycle = _lifecycle(api, push);

    await lifecycle.registerCurrentDevice();
    push.controller.add('first-rotation');
    await pumpEventQueue();

    api.failPut = false;
    push.controller.add('second-rotation');
    await pumpEventQueue();

    expect(api.putPaths.length, 2);
    expect(
      (api.putBodies.last! as Map)['pushToken'],
      'second-rotation',
    );

    await lifecycle.dispose();
  });

  test('device lifecycle ignores empty rotations', () async {
    final api = DeviceFakeApi();
    final push = FakePushTokenService();
    final lifecycle = _lifecycle(api, push);

    await lifecycle.registerCurrentDevice();
    push.controller.add('');
    await pumpEventQueue();

    expect(api.putPaths, isEmpty);

    await lifecycle.dispose();
  });

  test('device lifecycle does not subscribe when push is disabled', () async {
    final api = DeviceFakeApi();
    final push = FakePushTokenService();
    final lifecycle = _lifecycle(api, push, pushEnabled: false);

    await lifecycle.registerCurrentDevice();
    push.controller.add('rotated-token');
    await pumpEventQueue();

    expect((api.registerBody! as Map)['pushToken'], '');
    expect(api.putPaths, isEmpty);

    await lifecycle.dispose();
  });

  test('device lifecycle stops syncing after logout', () async {
    final api = DeviceFakeApi();
    final push = FakePushTokenService();
    final lifecycle = _lifecycle(api, push);

    await lifecycle.registerCurrentDevice();
    await lifecycle.logoutCurrentDevice();
    push.controller.add('rotated-after-logout');
    await pumpEventQueue();

    expect(api.putPaths, isEmpty);

    await lifecycle.dispose();
  });
}
