import 'package:dazhongdianping_app/core/session_store.dart';
import 'package:dazhongdianping_app/features/auth/auth_repository.dart';
import 'package:dazhongdianping_app/features/user/device_lifecycle.dart';
import 'package:flutter/foundation.dart';

class AuthController extends ChangeNotifier {
  AuthController({
    required this.repository,
    required this.store,
    this.deviceLifecycle,
  });
  final AuthRepository repository;
  final SessionStore store;
  final DeviceLifecycle? deviceLifecycle;

  AuthUser? currentUser;
  bool busy = false;
  String? errorMessage;

  Future<void> initialize() async {
    final token = await store.readAccessToken();
    if (token == null || token.isEmpty) return;
    try {
      currentUser = await repository.fetchCurrentUser();
      await _registerDeviceBestEffort();
    } catch (_) {
      await store.clear();
      currentUser = null;
    }
    notifyListeners();
  }

  Future<void> loginWithPassword(String account, String password) async {
    await _login(
      () => repository.loginWithPassword(account: account, password: password),
    );
  }

  Future<void> register({
    required String type,
    required String account,
    required String code,
    required String password,
    required String nickname,
    required String preferredRegion,
  }) async {
    await _login(
      () => repository.register(
        type: type,
        account: account,
        code: code,
        password: password,
        nickname: nickname,
        preferredRegion: preferredRegion,
      ),
    );
  }

  Future<void> resetPassword({
    required String type,
    required String account,
    required String code,
    required String newPassword,
  }) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await repository.resetPassword(
        type: type,
        account: account,
        code: code,
        newPassword: newPassword,
      );
    } catch (error) {
      errorMessage = '$error';
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> loginWithCode({
    required String account,
    required String type,
    required String code,
    required String preferredRegion,
  }) async {
    await _login(
      () => repository.loginWithCode(
        account: account,
        type: type,
        code: code,
        preferredRegion: preferredRegion,
      ),
    );
  }

  Future<SendCodeResult> sendCode({
    required String account,
    required String type,
    String scene = 'login',
  }) {
    return repository.sendCode(account: account, type: type, scene: scene);
  }

  Future<void> _login(Future<AuthSession> Function() action) async {
    busy = true;
    errorMessage = null;
    notifyListeners();
    try {
      final session = await action();
      await store.save(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      currentUser = session.user;
      await _registerDeviceBestEffort();
    } catch (error) {
      errorMessage = '$error';
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void replaceCurrentUser(AuthUser user) {
    currentUser = user;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await deviceLifecycle?.logoutCurrentDevice();
    } catch (_) {
      // 设备解绑失败不阻塞本地退出，服务端会话仍会继续注销。
    }
    try {
      await repository.logout();
    } catch (_) {
      // 本地清理优先，服务端会话若已经失效不阻塞退出。
    }
    await store.clear();
    currentUser = null;
    notifyListeners();
  }

  Future<void> _registerDeviceBestEffort() async {
    try {
      await deviceLifecycle?.registerCurrentDevice();
    } catch (_) {
      // 推送或设备登记不可用时不阻塞认证主流程。
    }
  }
}
