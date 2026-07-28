package com.tuowei.dazhongdianping.module.admin.auth.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.tuowei.dazhongdianping.common.admin.AdminCityScope;
import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest(properties = {
        "app.admin.access-token-expire-seconds=0",
        "spring.datasource.url=jdbc:h2:mem:admin-auth-service;MODE=MYSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE"
})
class AdminAuthServiceTest {

    @Autowired
    private AdminAuthService adminAuthService;

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    void shouldLoadSeededAllCityScopes() {
        AdminSession session = adminAuthService.login("admin", "admin123456").session();

        assertEquals(Set.of("CN", "EU"), session.regions());
        assertEquals(Set.of("CN", "EU"), session.cityScopes().keySet());
        assertTrue(session.cityScopes().get("CN").allCities());
        assertTrue(session.cityScopes().get("CN").cityIds().isEmpty());
        assertTrue(session.cityScopes().get("EU").allCities());
        assertTrue(session.cityScopes().get("EU").cityIds().isEmpty());
    }

    @Test
    void shouldKeepSelectedScopeEmptyWhenNoValidCityRowsExist() {
        jdbc.update("UPDATE admin_region_scope SET all_cities=FALSE WHERE admin_id=1 AND region='EU'");
        jdbc.update("DELETE FROM admin_city_scope WHERE admin_id=1 AND region='EU'");

        AdminSession session = adminAuthService.login("admin", "admin123456").session();
        AdminCityScope euScope = session.cityScopes().get("EU");

        assertNotNull(euScope);
        assertFalse(euScope.allCities());
        assertTrue(euScope.cityIds().isEmpty());
    }

    @Test
    void shouldExpireAndRemoveSessionUsingConfiguredTtl() {
        AdminAuthService.AdminLoginResult result = adminAuthService.login("admin", "admin123456");

        UnauthorizedException expired = assertThrows(
                UnauthorizedException.class,
                () -> adminAuthService.authenticate(result.accessToken())
        );
        assertEquals("管理员登录已过期，请重新登录", expired.getMessage());

        UnauthorizedException removed = assertThrows(
                UnauthorizedException.class,
                () -> adminAuthService.authenticate(result.accessToken())
        );
        assertEquals("登录已失效，请重新登录", removed.getMessage());
    }

    @Test
    void shouldRevokeLoggedInToken() {
        AdminAuthService.AdminLoginResult result = adminAuthService.login("admin", "admin123456");

        adminAuthService.logout(result.accessToken());

        UnauthorizedException revoked = assertThrows(
                UnauthorizedException.class,
                () -> adminAuthService.authenticate(result.accessToken())
        );
        assertEquals("登录已失效，请重新登录", revoked.getMessage());
    }
}
