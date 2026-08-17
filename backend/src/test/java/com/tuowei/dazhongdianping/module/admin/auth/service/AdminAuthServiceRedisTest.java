package com.tuowei.dazhongdianping.module.admin.auth.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.config.InfrastructureProperties;
import com.tuowei.dazhongdianping.module.admin.rbac.mapper.AdminRbacMapper;
import com.tuowei.dazhongdianping.module.admin.rbac.model.AdminUserRow;
import com.tuowei.dazhongdianping.module.admin.rbac.service.AdminAuditLogService;
import java.time.Duration;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

class AdminAuthServiceRedisTest {

    private AdminRbacMapper mapper;
    private AdminAuditLogService auditLogService;
    private InfrastructureProperties infrastructureProperties;
    private StringRedisTemplate redisTemplate;
    private ValueOperations<String, String> valueOperations;

    @BeforeEach
    void setUp() {
        mapper = mock(AdminRbacMapper.class);
        auditLogService = mock(AdminAuditLogService.class);
        infrastructureProperties = new InfrastructureProperties();
        infrastructureProperties.getStateStore().setProvider(InfrastructureProperties.StateStoreProvider.REDIS);
        infrastructureProperties.getStateStore().setKeyPrefix("dzdp:test");
        redisTemplate = mock(StringRedisTemplate.class);
        valueOperations = mock(ValueOperations.class);
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
    }

    @Test
    void shouldStoreSessionInRedisWhenRedisConfigured() {
        String passwordHash = new BCryptPasswordEncoder().encode("secret123");
        AdminUserRow user = seededUser(42L, "admin", passwordHash);
        when(mapper.selectUserByAccount("admin")).thenReturn(user);
        stubEmptyRbac(42L);

        AdminAuthService service = newAdminAuthService();

        AdminAuthService.AdminLoginResult result = service.login("admin", "secret123");

        ArgumentCaptor<String> keyCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<String> valueCaptor = ArgumentCaptor.forClass(String.class);
        ArgumentCaptor<Duration> ttlCaptor = ArgumentCaptor.forClass(Duration.class);
        verify(valueOperations, times(1)).set(keyCaptor.capture(), valueCaptor.capture(), ttlCaptor.capture());

        assertEquals("dzdp:test:admin:session:" + result.accessToken(), keyCaptor.getValue());
        assertEquals(Duration.ofSeconds(3600L), ttlCaptor.getValue());

        when(valueOperations.get("dzdp:test:admin:session:" + result.accessToken()))
                .thenReturn(valueCaptor.getValue());
        when(mapper.selectUserById(42L)).thenReturn(user);

        AdminSession session = service.authenticate(result.accessToken());
        assertEquals(42L, session.adminId());
    }

    @Test
    void shouldDeleteSessionFromRedisOnLogout() {
        AdminAuthService service = newAdminAuthService();

        service.logout("token-to-remove");

        verify(redisTemplate, times(1)).delete("dzdp:test:admin:session:token-to-remove");
        verify(valueOperations, never()).set(anyString(), anyString(), any(Duration.class));
    }

    @Test
    void shouldRejectAuthenticateWhenRedisHasNoSession() {
        when(valueOperations.get(anyString())).thenReturn(null);
        AdminAuthService service = newAdminAuthService();

        UnauthorizedException missing = assertThrows(
                UnauthorizedException.class,
                () -> service.authenticate("missing-token")
        );
        assertEquals("登录已失效，请重新登录", missing.getMessage());
        verify(mapper, never()).selectUserById(any());
    }

    @Test
    void shouldDropCorruptedRedisSessionAndReject() {
        when(valueOperations.get(eq("dzdp:test:admin:session:corrupt"))).thenReturn("not-json");
        AdminAuthService service = newAdminAuthService();

        UnauthorizedException corrupted = assertThrows(
                UnauthorizedException.class,
                () -> service.authenticate("corrupt")
        );
        assertEquals("登录已失效，请重新登录", corrupted.getMessage());
        verify(redisTemplate, times(1)).delete("dzdp:test:admin:session:corrupt");
    }

    private AdminAuthService newAdminAuthService() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());
        return new AdminAuthService(this.mapper, auditLogService, 3600L, mapper, infrastructureProperties,
                redisTemplateProvider());
    }

    private AdminUserRow seededUser(long id, String account, String passwordHash) {
        AdminUserRow user = new AdminUserRow();
        user.setId(id);
        user.setAccount(account);
        user.setName("管理员");
        user.setPasswordHash(passwordHash);
        user.setStatus(1);
        return user;
    }

    private void stubEmptyRbac(long adminId) {
        when(mapper.selectActivePermissionsByAdminId(adminId)).thenReturn(List.of());
        when(mapper.selectActiveCityScopesByAdminId(adminId)).thenReturn(List.of());
        when(mapper.selectActiveShopScopesByAdminId(adminId)).thenReturn(List.of());
        when(mapper.selectRegionScopesByAdminId(adminId)).thenReturn(List.of());
    }

    private ObjectProvider<StringRedisTemplate> redisTemplateProvider() {
        return new ObjectProvider<>() {
            @Override
            public StringRedisTemplate getObject(Object... args) {
                return redisTemplate;
            }

            @Override
            public StringRedisTemplate getIfAvailable() {
                return redisTemplate;
            }

            @Override
            public StringRedisTemplate getIfUnique() {
                return redisTemplate;
            }

            @Override
            public StringRedisTemplate getObject() {
                return redisTemplate;
            }
        };
    }
}
