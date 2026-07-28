package com.tuowei.dazhongdianping.module.admin.auth.service;

import com.tuowei.dazhongdianping.common.admin.AdminCityScope;
import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import com.tuowei.dazhongdianping.module.admin.rbac.mapper.AdminRbacMapper;
import com.tuowei.dazhongdianping.module.admin.rbac.model.AdminCityScopeRow;
import com.tuowei.dazhongdianping.module.admin.rbac.model.AdminPermissionRow;
import com.tuowei.dazhongdianping.module.admin.rbac.model.AdminRegionScopeRow;
import com.tuowei.dazhongdianping.module.admin.rbac.model.AdminShopScopeRow;
import com.tuowei.dazhongdianping.module.admin.rbac.model.AdminUserRow;
import com.tuowei.dazhongdianping.module.admin.rbac.service.AdminAuditLogService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Isolation;
import org.springframework.transaction.annotation.Transactional;

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

    @Transactional(isolation = Isolation.REPEATABLE_READ, noRollbackFor = UnauthorizedException.class)
    public AdminLoginResult login(String account, String password) {
        return login(account, password, "");
    }

    @Transactional(isolation = Isolation.REPEATABLE_READ, noRollbackFor = UnauthorizedException.class)
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

    @Transactional(isolation = Isolation.REPEATABLE_READ, readOnly = true)
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
        Map<String, AdminCityScope> cityScopes = loadCityScopes(user.getId());
        return new AdminSession(
                user.getId(),
                user.getAccount(),
                user.getName(),
                Set.copyOf(permissions),
                Set.copyOf(cityScopes.keySet()),
                cityScopes
        );
    }

    private Map<String, AdminCityScope> loadCityScopes(Long adminId) {
        Map<String, Set<Long>> selectedCityIds = new LinkedHashMap<>();
        for (AdminCityScopeRow row : mapper.selectActiveCityScopesByAdminId(adminId)) {
            selectedCityIds.computeIfAbsent(row.getRegion(), ignored -> new LinkedHashSet<>())
                    .add(row.getCityId());
        }
        Map<String, Set<Long>> selectedShopIds = new LinkedHashMap<>();
        for (AdminShopScopeRow row : mapper.selectActiveShopScopesByAdminId(adminId)) {
            selectedShopIds.computeIfAbsent(row.getRegion(), ignored -> new LinkedHashSet<>())
                    .add(row.getShopId());
        }

        Map<String, AdminCityScope> scopes = new LinkedHashMap<>();
        for (AdminRegionScopeRow row : mapper.selectRegionScopesByAdminId(adminId)) {
            boolean allCities = Boolean.TRUE.equals(row.getAllCities());
            Set<Long> cityIds = allCities
                    ? Set.of()
                    : selectedCityIds.getOrDefault(row.getRegion(), Set.of());
            Set<Long> shopIds = allCities
                    ? Set.of()
                    : selectedShopIds.getOrDefault(row.getRegion(), Set.of());
            scopes.put(row.getRegion(), new AdminCityScope(allCities, cityIds, shopIds));
        }
        return Map.copyOf(scopes);
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
