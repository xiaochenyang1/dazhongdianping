import 'package:dazhongdianping_app/core/api_client.dart';
import 'package:dazhongdianping_app/core/session_store.dart';
import 'package:dazhongdianping_app/features/auth/auth_controller.dart';
import 'package:dazhongdianping_app/features/auth/auth_repository.dart';
import 'package:dazhongdianping_app/features/user/device_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDeviceLifecycle implements DeviceLifecycle {
  int registrations = 0;
  int logouts = 0;

  @override
  Future<void> registerCurrentDevice() async {
    registrations++;
  }

  @override
  Future<void> logoutCurrentDevice() async {
    logouts++;
  }
}

class ControllerAuthApi implements JsonApi {
  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?>? query,
  }) async => {
    'id': 2,
    'nickname': 'Restored User',
    'avatar': '',
    'preferredRegion': 'EU',
  };

  @override
  Future<Map<String, dynamic>> postJson(String path, {Object? body}) async => {
    'accessToken': 'access-2',
    'refreshToken': 'refresh-2',
    'user': {
      'id': 2,
      'nickname': 'Controller User',
      'avatar': '',
      'preferredRegion': 'EU',
    },
  };
}

void main() {
  test('controller saves login session and clears it on logout', () async {
    final store = MemorySessionStore();
    final devices = FakeDeviceLifecycle();
    final controller = AuthController(
      repository: AuthRepository(ControllerAuthApi()),
      store: store,
      deviceLifecycle: devices,
    );

    await controller.loginWithPassword('demo@example.com', 'Demo123456');
    expect(controller.currentUser?.nickname, 'Controller User');
    expect(await store.readAccessToken(), 'access-2');
    expect(devices.registrations, 1);

    await controller.logout();
    expect(controller.currentUser, isNull);
    expect(await store.readAccessToken(), isNull);
    expect(devices.logouts, 1);
  });

  test('controller restores current user when access token exists', () async {
    final store = MemorySessionStore();
    await store.save(
      accessToken: 'stored-access',
      refreshToken: 'stored-refresh',
    );
    final devices = FakeDeviceLifecycle();
    final controller = AuthController(
      repository: AuthRepository(ControllerAuthApi()),
      store: store,
      deviceLifecycle: devices,
    );

    await controller.initialize();

    expect(controller.currentUser?.nickname, 'Restored User');
    expect(devices.registrations, 1);
  });

  test('controller saves registration session', () async {
    final store = MemorySessionStore();
    final controller = AuthController(
      repository: AuthRepository(ControllerAuthApi()),
      store: store,
    );

    await controller.register(
      type: 'email',
      account: 'new@example.com',
      code: '123456',
      password: 'Demo123456',
      nickname: 'New User',
      preferredRegion: 'EU',
    );

    expect(controller.currentUser?.nickname, 'Controller User');
    expect(await store.readAccessToken(), 'access-2');
  });

  test('controller replaces the current user summary', () {
    final controller = AuthController(
      repository: AuthRepository(ControllerAuthApi()),
      store: MemorySessionStore(),
    );
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.replaceCurrentUser(
      const AuthUser(
        id: 2,
        nickname: 'Updated User',
        avatar: 'avatar.png',
        preferredRegion: 'EU',
      ),
    );

    expect(controller.currentUser?.nickname, 'Updated User');
    expect(notifications, 1);
  });
}
