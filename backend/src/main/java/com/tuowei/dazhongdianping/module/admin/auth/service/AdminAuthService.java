package com.tuowei.dazhongdianping.module.admin.auth.service;

import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import java.time.Instant;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import com.tuowei.dazhongdianping.module.admin.rbac.mapper.AdminRbacMapper;
import com.tuowei.dazhongdianping.module.admin.rbac.model.AdminPermissionRow;
import com.tuowei.dazhongdianping.module.admin.rbac.model.AdminUserRow;
import com.tuowei.dazhongdianping.module.admin.rbac.service.AdminAuditLogService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AdminAuthService {

    private final Map<String, StoredAdminSession> sessionStore = new ConcurrentHashMap<>();

    private final AdminRbacMapper mapper;
    private final AdminAuditLogService auditLogService;
    private final long accessTokenExpireSeconds;
    private final PasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    public AdminAuthService(AdminRbacMapper mapper,
                            AdminAuditLogService auditLogService,
                            @Value("${app.admin.access-token-expire-seconds}") long accessTokenExpireSeconds) {
        this.mapper = mapper;
        this.auditLogService = auditLogService;
        this.accessTokenExpireSeconds = accessTokenExpireSeconds;
    }

    public AdminLoginResult login(String account, String password) {
        return login(account, password, "");
    }

    public AdminLoginResult login(String account, String password, String ip) {
        String normalizedAccount = account == null ? "" : account.trim();
        AdminUserRow user = mapper.selectUserByAccount(normalizedAccount);
        if (user == null || !passwordEncoder.matches(password, user.getPasswordHash())) {
            auditLogService.record(0L, "admin.login_failed", "admin", maskAccount(normalizedAccount), ip);
            throw new UnauthorizedException("管理员账号或密码错误");
        }
        if (!Integer.valueOf(1).equals(user.getStatus())) {
            auditLogService.record(user.getId(), "admin.login_failed", "admin:" + user.getId(), "账号已停用", ip);
            throw new UnauthorizedException("管理员账号已停用");
        }
        String token = UUID.randomUUID().toString().replace("-", "");
        AdminSession session = loadSession(user);
        sessionStore.put(token, new StoredAdminSession(
                user.getId(),
                Instant.now().plusSeconds(accessTokenExpireSeconds)
        ));
        mapper.updateLastLoginAt(user.getId());
        auditLogService.record(user.getId(), "admin.login_success", "admin:" + user.getId(), "", ip);
        return new AdminLoginResult(token, session);
    }

    public AdminSession authenticate(String token) {
        StoredAdminSession storedSession = sessionStore.get(token);
        if (storedSession == null) {
            throw new UnauthorizedException("登录已失效，请重新登录");
        }
        if (!storedSession.expiresAt().isAfter(Instant.now())) {
            sessionStore.remove(token, storedSession);
            throw new UnauthorizedException("管理员登录已过期，请重新登录");
        }
        AdminUserRow user = mapper.selectUserById(storedSession.adminId());
        if (user == null) {
            sessionStore.remove(token, storedSession);
            throw new UnauthorizedException("登录已失效，请重新登录");
        }
        if (!Integer.valueOf(1).equals(user.getStatus())) {
            sessionStore.remove(token, storedSession);
            throw new UnauthorizedException("管理员账号已停用");
        }
        return loadSession(user);
    }

    public void logout(String token) {
        sessionStore.remove(token);
    }

    public record AdminLoginResult(
            String accessToken,
            AdminSession session
    ) {
    }

    private AdminSession loadSession(AdminUserRow user) {
        Set<String> permissions = new LinkedHashSet<>();
        for (AdminPermissionRow permission : mapper.selectActivePermissionsByAdminId(user.getId())) {
            permissions.add(permission.getCode());
        }
        return new AdminSession(
                user.getId(),
                user.getAccount(),
                user.getName(),
                Set.copyOf(permissions),
                Set.copyOf(new LinkedHashSet<>(mapper.selectRegionsByAdminId(user.getId())))
        );
    }

    private String maskAccount(String account) {
        if (account == null || account.isBlank()) {
            return "";
        }
        if (account.length() <= 2) {
            return "**";
        }
        return account.substring(0, 2) + "***";
    }

    private record StoredAdminSession(
            Long adminId,
            Instant expiresAt
    ) {
    }
}
