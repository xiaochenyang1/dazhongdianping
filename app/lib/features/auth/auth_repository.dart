import 'package:dazhongdianping_app/core/api_client.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.nickname,
    required this.avatar,
    required this.preferredRegion,
  });
  final int id;
  final String nickname;
  final String avatar;
  final String preferredRegion;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as int,
    nickname: json['nickname'] as String? ?? '',
    avatar: json['avatar'] as String? ?? '',
    preferredRegion: json['preferredRegion'] as String? ?? 'EU',
  );
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });
  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['accessToken'] as String? ?? '',
    refreshToken: json['refreshToken'] as String? ?? '',
    user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
  );
}

class SendCodeResult {
  const SendCodeResult({
    required this.sent,
    required this.expireSeconds,
    required this.nextRetrySeconds,
    required this.mockCode,
  });
  final bool sent;
  final int expireSeconds;
  final int nextRetrySeconds;
  final String mockCode;

  factory SendCodeResult.fromJson(Map<String, dynamic> json) => SendCodeResult(
    sent: json['sent'] as bool? ?? false,
    expireSeconds: json['expireSeconds'] as int? ?? 0,
    nextRetrySeconds: json['nextRetrySeconds'] as int? ?? 0,
    mockCode: json['mockCode'] as String? ?? '',
  );
}

class BanAppealStatus {
  const BanAppealStatus({
    required this.id,
    required this.status,
    required this.statusText,
    required this.reason,
    required this.rejectReason,
    required this.banReason,
    required this.submittedAt,
    required this.auditedAt,
  });

  final int id;
  final int status;
  final String statusText;
  final String reason;
  final String rejectReason;
  final String banReason;
  final String submittedAt;
  final String auditedAt;

  bool get isApproved => status == 1;
  bool get isRejected => status == 2;
  bool get isPending => status == 0;

  factory BanAppealStatus.fromJson(Map<String, dynamic> json) =>
      BanAppealStatus(
        id: json['id'] as int? ?? 0,
        status: json['status'] as int? ?? 0,
        statusText: json['statusText'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        rejectReason: json['rejectReason'] as String? ?? '',
        banReason: json['banReason'] as String? ?? '',
        submittedAt: json['submittedAt'] as String? ?? '',
        auditedAt: json['auditedAt'] as String? ?? '',
      );
}

class AuthRepository {
  AuthRepository(this.api);
  final JsonApi api;

  Future<AuthSession> loginWithPassword({
    required String account,
    required String password,
  }) async {
    final result = await api.postJson(
      '/api/c/v1/auth/login/password',
      body: {'account': account, 'password': password},
    );
    return AuthSession.fromJson(result);
  }

  Future<AuthSession> register({
    required String type,
    required String account,
    required String code,
    required String password,
    required String nickname,
    required String preferredRegion,
  }) async {
    final result = await api.postJson(
      '/api/c/v1/auth/register',
      body: {
        'type': type,
        'account': account,
        'code': code,
        'password': password,
        'nickname': nickname,
        'preferredRegion': preferredRegion,
      },
    );
    return AuthSession.fromJson(result);
  }

  Future<AuthUser> fetchCurrentUser() async {
    return AuthUser.fromJson(await api.getJson('/api/c/v1/user/me'));
  }

  Future<SendCodeResult> sendCode({
    required String account,
    required String type,
    String scene = 'login',
  }) async {
    final result = await api.postJson(
      '/api/c/v1/auth/send-code',
      body: {
        'scene': scene,
        'type': type,
        'account': account,
        'deviceId': 'flutter-app',
      },
    );
    return SendCodeResult.fromJson(result);
  }

  Future<AuthSession> loginWithCode({
    required String account,
    required String type,
    required String code,
    required String preferredRegion,
  }) async {
    final result = await api.postJson(
      '/api/c/v1/auth/login/code',
      body: {
        'type': type,
        'account': account,
        'code': code,
        'preferredRegion': preferredRegion,
      },
    );
    return AuthSession.fromJson(result);
  }

  Future<void> resetPassword({
    required String type,
    required String account,
    required String code,
    required String newPassword,
  }) async {
    await api.postJson(
      '/api/c/v1/auth/password/reset',
      body: {
        'type': type,
        'account': account,
        'code': code,
        'newPassword': newPassword,
      },
    );
  }

  Future<BanAppealStatus> submitBanAppeal({
    required String type,
    required String account,
    required String code,
    required String reason,
  }) async {
    final result = await api.postJson(
      '/api/c/v1/auth/ban-appeals',
      body: {'type': type, 'account': account, 'code': code, 'reason': reason},
    );
    return BanAppealStatus.fromJson(result);
  }

  Future<BanAppealStatus> queryBanAppeal({
    required String type,
    required String account,
    required String code,
  }) async {
    final result = await api.postJson(
      '/api/c/v1/auth/ban-appeals/query',
      body: {'type': type, 'account': account, 'code': code},
    );
    return BanAppealStatus.fromJson(result);
  }

  Future<void> logout() async {
    await api.postJson('/api/c/v1/auth/logout');
  }
}
