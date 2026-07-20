package com.tuowei.dazhongdianping.module.merchant.mapper;

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
class MerchantIdentityMapperTest {

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    void shouldSeedMerchantOwnersRolesAndAllShopScope() {
        List<String> accounts = jdbc.queryForList(
                "SELECT account FROM merchant_operator WHERE operator_type=1 ORDER BY merchant_id",
                String.class
        );
        assertEquals(List.of(
                "merchant_cn_hotpot@example.com",
                "merchant_cn_cafe@example.com",
                "merchant_eu_sichuan@example.com",
                "merchant_eu_cafe@example.com"
        ), accounts);

        String passwordHash = jdbc.queryForObject(
                "SELECT password_hash FROM merchant_operator WHERE account='merchant_eu_sichuan@example.com'",
                String.class
        );
        assertTrue(passwordHash.startsWith("$2a$"));
        assertTrue(new BCryptPasswordEncoder().matches("merchant123456", passwordHash));

        assertEquals(List.of("coupon_operator", "owner", "service_operator", "store_manager"),
                jdbc.queryForList("SELECT code FROM merchant_role ORDER BY code", String.class));
        assertEquals(4, jdbc.queryForObject(
                "SELECT COUNT(1) FROM merchant_operator mo "
                        + "JOIN merchant_operator_role mor ON mor.operator_id=mo.id "
                        + "JOIN merchant_role mr ON mr.id=mor.role_id "
                        + "WHERE mo.operator_type=1 AND mo.shop_scope_type=1 AND mr.code='owner'",
                Integer.class
        ));
    }
}
