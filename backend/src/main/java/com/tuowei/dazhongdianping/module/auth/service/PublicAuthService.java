package com.tuowei.dazhongdianping.module.auth.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.auth.certification.service.UserExpertCertificationService;
import com.tuowei.dazhongdianping.module.auth.mapper.AuthCommandMapper;
import com.tuowei.dazhongdianping.module.auth.model.AppUserRow;
import com.tuowei.dazhongdianping.module.auth.model.UserSessionRow;
import com.tuowei.dazhongdianping.module.auth.model.request.AuthLoginCodeRequest;
import com.tuowei.dazhongdianping.module.auth.model.request.AuthLoginPasswordRequest;
import com.tuowei.dazhongdianping.module.auth.model.request.AuthRefreshRequest;
import com.tuowei.dazhongdianping.module.auth.model.request.AuthResetPasswordRequest;
import com.tuowei.dazhongdianping.module.auth.model.VerificationCodeRow;
import com.tuowei.dazhongdianping.module.auth.model.request.AuthRegisterRequest;
import com.tuowei.dazhongdianping.module.auth.model.request.AuthSendCodeRequest;
import com.tuowei.dazhongdianping.module.auth.model.request.UserBindRequest;
import com.tuowei.dazhongdianping.module.auth.model.request.UserPasswordUpdateRequest;
import com.tuowei.dazhongdianping.module.auth.model.request.UserProfileUpdateRequest;
import com.tuowei.dazhongdianping.module.auth.model.response.AuthCurrentUserResponse;
import com.tuowei.dazhongdianping.module.auth.model.response.AuthSendCodeResponse;
import com.tuowei.dazhongdianping.module.auth.model.response.AuthSessionResponse;
import com.tuowei.dazhongdianping.module.auth.model.response.AuthUserResponse;
import com.tuowei.dazhongdianping.module.auth.model.response.UserPublicProfileResponse;
import com.tuowei.dazhongdianping.module.social.service.SocialService;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDateTime;
import java.util.HexFormat;
import java.util.Locale;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class PublicAuthService {

    private static final int CODE_EXPIRE_SECONDS = 300;
    private static final int NEXT_RETRY_SECONDS = 60;
    private static final String MOCK_CODE = "123456";

    private final AuthCommandMapper authCommandMapper;
    private final UserAccessTokenService userAccessTokenService;
    private final SendCodeRateLimitService sendCodeRateLimitService;
    private final UserPrivacyService userPrivacyService;
    private final SocialService socialService;
    private final UserExpertCertificationService userExpertCertificationService;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();
    private final long refreshTokenExpireSeconds;

    public PublicAuthService(AuthCommandMapper authCommandMapper,
                             SendCodeRateLimitService sendCodeRateLimitService,
                             UserPrivacyService userPrivacyService,
                             SocialService socialService,
                             UserExpertCertificationService userExpertCertificationService,
                             UserAccessTokenService userAccessTokenService,
                             @Value("${app.auth.refresh-token-expire-seconds}") long refreshTokenExpireSeconds) {
        this.authCommandMapper = authCommandMapper;
        this.sendCodeRateLimitService = sendCodeRateLimitService;
        this.userPrivacyService = userPrivacyService;
        this.socialService = socialService;
        this.userExpertCertificationService = userExpertCertificationService;
        this.userAccessTokenService = userAccessTokenService;
        this.refreshTokenExpireSeconds = refreshTokenExpireSeconds;
    }

    @Transactional
    public AuthSendCodeResponse sendCode(AuthSendCodeRequest request, String requestIp) {
        String scene = normalizeScene(request.getScene());
        int targetType = normalizeTargetType(request.getType());
        String account = normalizeAccount(request.getAccount(), targetType);
        String deviceId = StringUtils.hasText(request.getDeviceId()) ? request.getDeviceId().trim() : "";
        sendCodeRateLimitService.checkAndRecord(scene, targetType, account, deviceId, requestIp);

        VerificationCodeRow row = new VerificationCodeRow();
        row.setScene(scene);
        row.setTargetType(targetType);
        row.setTarget(account);
        row.setCodeHash(sha256Hex(MOCK_CODE));
        row.setDeviceId(deviceId);
        row.setRequestIp(StringUtils.hasText(requestIp) ? requestIp.trim() : "");
        row.setStatus(0);
        row.setExpireAt(LocalDateTime.now().plusSeconds(CODE_EXPIRE_SECONDS));
        authCommandMapper.insertVerificationCode(row);

        return new AuthSendCodeResponse(true, CODE_EXPIRE_SECONDS, NEXT_RETRY_SECONDS, MOCK_CODE);
    }

    @Transactional
    public AuthSessionResponse register(AuthRegisterRequest request) {
        int targetType = normalizeTargetType(request.getType());
        String account = normalizeAccount(request.getAccount(), targetType);
        requireVerificationCode("register", targetType, account, request.getCode());
        if (selectUserByAccount(targetType, account) != null) {
            throw new IllegalArgumentException("账号已注册");
        }

        AppUserRow row = new AppUserRow();
        row.setNickname(resolveNickname(request.getNickname(), account));
        row.setAvatar("");
        row.setEmail(targetType == 1 ? account : null);
        row.setPhone(targetType == 2 ? account : null);
        row.setPasswordHash(passwordEncoder.encode(request.getPassword().trim()));
        row.setGender(0);
        row.setSignature("");
        row.setPreferredRegion(normalizePreferredRegion(request.getPreferredRegion()));
        row.setGrowthValue(0);
        row.setLevel(1);
        row.setPoints(0);
        row.setStatus(1);
        row.setLastLoginAt(LocalDateTime.now());
        authCommandMapper.insertUser(row);
        authCommandMapper.updateUserLastLogin(row.getId());
        return issueSession(row);
    }

    public UserSession authenticate(String accessToken) {
        UserAccessTokenService.AuthenticatedAccessToken token = userAccessTokenService.verify(accessToken);
        userPrivacyService.processDueDeleteTasksForUser(token.userId());
        UserSessionRow sessionRow = authCommandMapper.selectUserSessionById(token.sessionId());
        if (sessionRow == null || sessionRow.getStatus() == null || sessionRow.getStatus() != 1) {
            throw new UnauthorizedException("登录已失效，请重新登录");
        }
        AppUserRow userRow = authCommandMapper.selectUserById(token.userId());
        if (userRow == null || userRow.getStatus() == null || userRow.getStatus() != 1) {
            throw new UnauthorizedException("用户状态不可用");
        }
        return new UserSession(userRow.getId(), sessionRow.getId());
    }

    public AuthCurrentUserResponse currentUser() {
        UserSession userSession = UserSessionContext.get();
        if (userSession == null) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        AppUserRow userRow = authCommandMapper.selectUserById(userSession.userId());
        if (userRow == null) {
            throw new UnauthorizedException("用户不存在");
        }
        return toCurrentUserResponse(userRow);
    }

    @Transactional
    public AuthCurrentUserResponse updateCurrentUserProfile(UserProfileUpdateRequest request) {
        AppUserRow currentUser = currentUserRow();
        currentUser.setNickname(normalizeNickname(request.getNickname(), currentUser));
        currentUser.setAvatar(normalizeAvatar(request.getAvatar()));
        currentUser.setGender(normalizeGender(request.getGender()));
        currentUser.setSignature(normalizeSignature(request.getSignature()));

        int affected = authCommandMapper.updateUserProfile(currentUser);
        if (affected == 0) {
            throw new UnauthorizedException("用户资料更新失败");
        }

        return toCurrentUserResponse(currentUser);
    }

    @Transactional
    public AuthCurrentUserResponse bindCurrentUser(UserBindRequest request) {
        AppUserRow currentUser = currentUserRow();
        int targetType = normalizeTargetType(request.getType());
        String account = normalizeAccount(request.getAccount(), targetType);
        requireVerificationCode("bind", targetType, account, request.getCode());
        AppUserRow existing = selectUserByAccount(targetType, account);
        if (existing != null && !existing.getId().equals(currentUser.getId())) {
            throw new IllegalArgumentException(targetType == 1 ? "该邮箱已被其他账号绑定" : "该手机号已被其他账号绑定");
        }

        if ((targetType == 1 && account.equals(currentUser.getEmail()))
                || (targetType == 2 && account.equals(currentUser.getPhone()))) {
            return toCurrentUserResponse(currentUser);
        }

        int affected = targetType == 1
                ? authCommandMapper.updateUserEmail(currentUser.getId(), account)
                : authCommandMapper.updateUserPhone(currentUser.getId(), account);
        if (affected == 0) {
            throw new UnauthorizedException("账号绑定失败");
        }

        if (targetType == 1) {
            currentUser.setEmail(account);
        } else {
            currentUser.setPhone(account);
        }
        return toCurrentUserResponse(currentUser);
    }

    @Transactional
    public void updateCurrentUserPassword(UserPasswordUpdateRequest request) {
        AppUserRow currentUser = currentUserRow();
        String oldPassword = request.getOldPassword() == null ? "" : request.getOldPassword().trim();
        String newPassword = request.getNewPassword().trim();
        if (StringUtils.hasText(currentUser.getPasswordHash())) {
            if (!StringUtils.hasText(oldPassword)) {
                throw new IllegalArgumentException("oldPassword 不能为空");
            }
            if (!passwordEncoder.matches(oldPassword, currentUser.getPasswordHash())) {
                throw new IllegalArgumentException("旧密码不正确");
            }
        }
        if (oldPassword.equals(newPassword) && StringUtils.hasText(oldPassword)) {
            throw new IllegalArgumentException("新密码不能和旧密码一样");
        }
        int affected = authCommandMapper.updateUserPassword(currentUser.getId(), passwordEncoder.encode(newPassword));
        if (affected == 0) {
            throw new UnauthorizedException("密码更新失败");
        }
        authCommandMapper.revokeUserSessionsByUserId(currentUser.getId());
    }

    public UserPublicProfileResponse getPublicUserProfile(Long userId) {
        userPrivacyService.processDueDeleteTasksForUser(userId);
        AppUserRow userRow = authCommandMapper.selectUserById(userId);
        if (userRow == null || userRow.getStatus() == null || userRow.getStatus() != 1) {
            throw new NotFoundException("用户不存在");
        }
        return new UserPublicProfileResponse(
                userRow.getId(),
                normalizeNickname(userRow.getNickname(), userRow),
                normalizeAvatar(userRow.getAvatar()),
                normalizeSignature(userRow.getSignature()),
                userRow.getPreferredRegion(),
                userRow.getLevel(),
                userRow.getPoints(),
                userRow.getGrowthValue(),
                authCommandMapper.countPublicReviewsByUserId(userId, currentRegion().name()),
                socialService.followerCount(userId),
                socialService.followingCount(userId),
                socialService.followedByCurrentUser(userId),
                userExpertCertificationService.approvedBadge(userId, currentRegion().name())
        );
    }

    @Transactional
    public AuthSessionResponse loginWithPassword(AuthLoginPasswordRequest request) {
        AppUserRow userRow = selectUserByLoginAccount(request.getAccount());
        if (userRow == null || !StringUtils.hasText(userRow.getPasswordHash())
                || !passwordEncoder.matches(request.getPassword(), userRow.getPasswordHash())) {
            throw new UnauthorizedException("账号或密码错误");
        }
        if (userRow.getStatus() == null || userRow.getStatus() != 1) {
            throw new UnauthorizedException("用户状态不可用");
        }
        authCommandMapper.updateUserLastLogin(userRow.getId());
        return issueSession(userRow);
    }

    @Transactional
    public AuthSessionResponse loginWithCode(AuthLoginCodeRequest request) {
        int targetType = normalizeTargetType(request.getType());
        String account = normalizeAccount(request.getAccount(), targetType);
        requireVerificationCode("login", targetType, account, request.getCode());
        AppUserRow userRow = selectUserByAccount(targetType, account);
        if (userRow == null) {
            userRow = new AppUserRow();
            userRow.setNickname(resolveNickname("", account));
            userRow.setAvatar("");
            userRow.setEmail(targetType == 1 ? account : null);
            userRow.setPhone(targetType == 2 ? account : null);
            userRow.setPasswordHash(null);
            userRow.setGender(0);
            userRow.setSignature("");
            userRow.setPreferredRegion(normalizePreferredRegion(request.getPreferredRegion()));
            userRow.setGrowthValue(0);
            userRow.setLevel(1);
            userRow.setPoints(0);
            userRow.setStatus(1);
            userRow.setLastLoginAt(LocalDateTime.now());
            authCommandMapper.insertUser(userRow);
        }
        authCommandMapper.updateUserLastLogin(userRow.getId());
        return issueSession(userRow);
    }

    @Transactional
    public AuthSessionResponse refresh(AuthRefreshRequest request) {
        String refreshTokenHash = sha256Hex(request.getRefreshToken().trim());
        UserSessionRow sessionRow = authCommandMapper.selectUserSessionByRefreshTokenHash(refreshTokenHash);
        if (sessionRow == null || sessionRow.getStatus() == null || sessionRow.getStatus() != 1) {
            throw new UnauthorizedException("refreshToken 无效");
        }
        userPrivacyService.processDueDeleteTasksForUser(sessionRow.getUserId());
        if (sessionRow.getRefreshExpireAt() == null || sessionRow.getRefreshExpireAt().isBefore(LocalDateTime.now())) {
            throw new UnauthorizedException("refreshToken 已过期");
        }
        AppUserRow userRow = authCommandMapper.selectUserById(sessionRow.getUserId());
        if (userRow == null || userRow.getStatus() == null || userRow.getStatus() != 1) {
            throw new UnauthorizedException("用户状态不可用");
        }

        String refreshToken = randomToken();
        sessionRow.setRefreshTokenHash(sha256Hex(refreshToken));
        sessionRow.setRefreshExpireAt(LocalDateTime.now().plusSeconds(refreshTokenExpireSeconds));
        authCommandMapper.updateUserSessionRefreshToken(sessionRow);

        return new AuthSessionResponse(
                userAccessTokenService.issue(userRow.getId(), sessionRow.getId()),
                refreshToken,
                toAuthUserResponse(userRow)
        );
    }

    @Transactional
    public void logout() {
        UserSession userSession = UserSessionContext.get();
        if (userSession == null) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        authCommandMapper.revokeUserSession(userSession.sessionId());
    }

    @Transactional
    public void resetPassword(AuthResetPasswordRequest request) {
        int targetType = normalizeTargetType(request.getType());
        String account = normalizeAccount(request.getAccount(), targetType);
        requireVerificationCode("reset", targetType, account, request.getCode());
        AppUserRow userRow = selectUserByAccount(targetType, account);
        if (userRow == null) {
            throw new IllegalArgumentException("账号不存在");
        }
        int affected = authCommandMapper.updateUserPassword(
                userRow.getId(),
                passwordEncoder.encode(request.getNewPassword().trim())
        );
        if (affected == 0) {
            throw new IllegalArgumentException("账号不存在");
        }
        authCommandMapper.revokeUserSessionsByUserId(userRow.getId());
    }

    private String normalizeScene(String scene) {
        String value = scene == null ? "" : scene.trim().toLowerCase(Locale.ROOT);
        return switch (value) {
            case "login", "register", "bind", "reset", "delete" -> value;
            default -> throw new IllegalArgumentException("scene 不支持");
        };
    }

    private int normalizeTargetType(String type) {
        String value = type == null ? "" : type.trim().toLowerCase(Locale.ROOT);
        return switch (value) {
            case "email" -> 1;
            case "phone" -> 2;
            default -> throw new IllegalArgumentException("type 不支持");
        };
    }

    private String normalizeAccount(String account, int targetType) {
        String value = account == null ? "" : account.trim();
        if (!StringUtils.hasText(value)) {
            throw new IllegalArgumentException("account 不能为空");
        }
        if (targetType == 1 && !value.contains("@")) {
            throw new IllegalArgumentException("邮箱格式不合法");
        }
        if (targetType == 2 && value.length() < 6) {
            throw new IllegalArgumentException("手机号格式不合法");
        }
        return value;
    }

    private VerificationCodeRow requireVerificationCode(String scene, int targetType, String target, String code) {
        VerificationCodeRow row = authCommandMapper.selectLatestVerificationCode(scene, targetType, target);
        String codeHash = sha256Hex(code.trim());
        if (row == null
                || row.getStatus() == null
                || row.getStatus() != 0
                || !codeHash.equals(row.getCodeHash())
                || row.getExpireAt() == null
                || !row.getExpireAt().isAfter(LocalDateTime.now())) {
            throw new IllegalArgumentException("验证码无效或已过期");
        }
        int affected = authCommandMapper.markVerificationCodeUsed(row.getId());
        if (affected != 1) {
            throw new IllegalArgumentException("验证码无效或已过期");
        }
        return row;
    }

    private AppUserRow selectUserByAccount(int targetType, String account) {
        AppUserRow userRow = targetType == 1
                ? authCommandMapper.selectUserByEmail(account)
                : authCommandMapper.selectUserByPhone(account);
        if (userRow == null) {
            return null;
        }
        userPrivacyService.processDueDeleteTasksForUser(userRow.getId());
        return targetType == 1
                ? authCommandMapper.selectUserByEmail(account)
                : authCommandMapper.selectUserByPhone(account);
    }

    private AppUserRow selectUserByLoginAccount(String account) {
        String value = account == null ? "" : account.trim();
        return value.contains("@")
                ? selectUserByAccount(1, value)
                : selectUserByAccount(2, value);
    }

    private AppUserRow currentUserRow() {
        UserSession userSession = UserSessionContext.get();
        if (userSession == null) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        AppUserRow userRow = authCommandMapper.selectUserById(userSession.userId());
        if (userRow == null || userRow.getStatus() == null || userRow.getStatus() != 1) {
            throw new UnauthorizedException("用户状态不可用");
        }
        return userRow;
    }

    private AuthSessionResponse issueSession(AppUserRow userRow) {
        String refreshToken = randomToken();
        UserSessionRow sessionRow = new UserSessionRow();
        sessionRow.setUserId(userRow.getId());
        sessionRow.setRefreshTokenHash(sha256Hex(refreshToken));
        sessionRow.setStatus(1);
        sessionRow.setRefreshExpireAt(LocalDateTime.now().plusSeconds(refreshTokenExpireSeconds));
        authCommandMapper.insertUserSession(sessionRow);
        return new AuthSessionResponse(
                userAccessTokenService.issue(userRow.getId(), sessionRow.getId()),
                refreshToken,
                toAuthUserResponse(userRow)
        );
    }

    private String resolveNickname(String nickname, String account) {
        if (StringUtils.hasText(nickname)) {
            return nickname.trim();
        }
        String seed = account.contains("@") ? account.substring(0, account.indexOf('@')) : account;
        String sanitized = seed.length() > 12 ? seed.substring(seed.length() - 12) : seed;
        return "用户" + sanitized;
    }

    private String normalizePreferredRegion(String preferredRegion) {
        if (!StringUtils.hasText(preferredRegion)) {
            return currentRegion().name();
        }
        return Region.fromHeader(preferredRegion).name();
    }

    private String normalizeNickname(String nickname, AppUserRow currentUser) {
        if (!StringUtils.hasText(nickname)) {
            return resolveNickname(currentUser.getNickname(), currentUser.getEmail() != null ? currentUser.getEmail() : currentUser.getPhone());
        }
        return nickname.trim();
    }

    private String normalizeAvatar(String avatar) {
        return StringUtils.hasText(avatar) ? avatar.trim() : "";
    }

    private int normalizeGender(Integer gender) {
        if (gender == null) {
            return 0;
        }
        return switch (gender) {
            case 1, 2 -> gender;
            default -> 0;
        };
    }

    private String normalizeSignature(String signature) {
        return StringUtils.hasText(signature) ? signature.trim() : "";
    }

    private Region currentRegion() {
        return RegionContext.getRegion();
    }

    private String randomToken() {
        return UUID.randomUUID().toString().replace("-", "");
    }

    private AuthUserResponse toAuthUserResponse(AppUserRow userRow) {
        return new AuthUserResponse(
                userRow.getId(),
                userRow.getNickname(),
                userRow.getAvatar(),
                userRow.getPreferredRegion()
        );
    }

    private AuthCurrentUserResponse toCurrentUserResponse(AppUserRow userRow) {
        return new AuthCurrentUserResponse(
                userRow.getId(),
                userRow.getNickname(),
                userRow.getAvatar(),
                userRow.getEmail(),
                userRow.getPhone(),
                StringUtils.hasText(userRow.getPasswordHash()),
                userRow.getGender(),
                userRow.getSignature(),
                userRow.getPreferredRegion(),
                userRow.getLevel(),
                userRow.getPoints(),
                userRow.getGrowthValue(),
                userExpertCertificationService.currentUserStatus(userRow.getId(), currentRegion().name())
        );
    }

    private String sha256Hex(String value) {
        try {
            MessageDigest messageDigest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(messageDigest.digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 不可用", exception);
        }
    }
}
