package com.tuowei.dazhongdianping.module.admin.auth.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
        "app.admin.access-token-expire-seconds=0",
        "spring.datasource.url=jdbc:h2:mem:admin-auth-service;MODE=MYSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE"
})
class AdminAuthServiceTest {

    @Autowired
    private AdminAuthService adminAuthService;

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
