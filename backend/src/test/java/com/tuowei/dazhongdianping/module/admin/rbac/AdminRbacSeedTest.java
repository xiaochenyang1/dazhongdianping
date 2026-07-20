package com.tuowei.dazhongdianping.module.admin.rbac;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
class AdminRbacSeedTest {

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    void shouldSeedDatabaseAdminRolesPermissionsAndRegions() {
        assertEquals("系统管理员", jdbc.queryForObject(
                "SELECT name FROM admin_user WHERE id=1 AND account='admin' AND status=1",
                String.class
        ));

        String passwordHash = jdbc.queryForObject(
                "SELECT password_hash FROM admin_user WHERE id=1",
                String.class
        );
        assertTrue(new BCryptPasswordEncoder().matches("admin123456", passwordHash));

        assertEquals(List.of("CN", "EU"), jdbc.queryForList(
                "SELECT region FROM admin_region_scope WHERE admin_id=1 ORDER BY region",
                String.class
        ));
        assertEquals(5, jdbc.queryForObject("SELECT COUNT(1) FROM admin_role", Integer.class));
        assertEquals(1, jdbc.queryForObject(
                "SELECT COUNT(1) FROM admin_user_role aur "
                        + "JOIN admin_role ar ON ar.id=aur.role_id "
                        + "WHERE aur.admin_id=1 AND ar.code='super_admin'",
                Integer.class
        ));
        assertEquals(0, jdbc.queryForObject(
                "SELECT COUNT(1) FROM admin_permission ap "
                        + "LEFT JOIN admin_role_permission arp ON arp.permission_id=ap.id "
                        + "AND arp.role_id=(SELECT id FROM admin_role WHERE code='super_admin') "
                        + "WHERE ap.status=1 AND arp.permission_id IS NULL",
                Integer.class
        ));
    }
}
