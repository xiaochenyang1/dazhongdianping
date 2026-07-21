package com.tuowei.dazhongdianping.module.admin.geodata;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
class AdminGeoDataSeedTest {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void shouldSeedActiveGeoDataAndGeoPermissions() {
        assertEquals(1, jdbcTemplate.queryForObject(
                "SELECT status FROM category WHERE id=100", Integer.class));
        assertEquals(1, jdbcTemplate.queryForObject(
                "SELECT status FROM city WHERE id=101", Integer.class));
        assertEquals(1, jdbcTemplate.queryForObject(
                "SELECT status FROM area WHERE id=1011", Integer.class));

        jdbcTemplate.update(
                "INSERT INTO city(code, region, name, sort_no) VALUES(?,?,?,?)",
                "PLAN", "EU", "Plan City", 99);
        Long cityId = jdbcTemplate.queryForObject(
                "SELECT id FROM city WHERE region='EU' AND code='PLAN'", Long.class);
        assertNotNull(cityId);
        assertEquals(1, jdbcTemplate.queryForObject(
                "SELECT status FROM city WHERE id=?", Integer.class, cityId));

        assertEquals(1, jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM admin_permission "
                        + "WHERE code='data:geo:read' AND status=1",
                Integer.class));
        assertEquals(1, jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM admin_role_permission arp "
                        + "JOIN admin_role ar ON ar.id=arp.role_id "
                        + "JOIN admin_permission ap ON ap.id=arp.permission_id "
                        + "WHERE ar.code='data_operator' AND ap.code='data:geo:write'",
                Integer.class));
    }

    @Test
    void shouldGrantOrderReadPermissionToDataOperator() {
        assertEquals(1, jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM admin_role_permission arp "
                        + "JOIN admin_role ar ON ar.id=arp.role_id "
                        + "JOIN admin_permission ap ON ap.id=arp.permission_id "
                        + "WHERE ar.code='data_operator' AND ap.code='data:order:read'",
                Integer.class));
    }

    @Test
    void shouldRejectDuplicateGeoDataWithinTheSameScope() {
        assertThrows(DuplicateKeyException.class, () -> jdbcTemplate.update(
                "INSERT INTO category(parent_id, region, name, sort_no) VALUES(?,?,?,?)",
                200L, "EU", "Chinese", 99));
        assertThrows(DuplicateKeyException.class, () -> jdbcTemplate.update(
                "INSERT INTO city(code, region, name, sort_no) VALUES(?,?,?,?)",
                "PAR", "EU", "Another Paris", 99));
        assertThrows(DuplicateKeyException.class, () -> jdbcTemplate.update(
                "INSERT INTO area(city_id, region, name, sort_no) VALUES(?,?,?,?)",
                101L, "EU", "Le Marais", 99));
    }

    @Test
    void shouldRejectCategoryNameCaseVariantsAtTheDatabaseBoundary() {
        assertThrows(DuplicateKeyException.class, () -> jdbcTemplate.update(
                "INSERT INTO category(parent_id, region, name, sort_no) VALUES(?,?,?,?)",
                0L, "EU", "dining", 99));
    }

    @Test
    void shouldRejectCityNameCaseVariantsAtTheDatabaseBoundary() {
        assertThrows(DuplicateKeyException.class, () -> jdbcTemplate.update(
                "INSERT INTO city(code, region, name, sort_no) VALUES(?,?,?,?)",
                "PARIS-LOWER", "EU", "paris", 99));
    }

    @Test
    void shouldRejectAreaNameCaseVariantsAtTheDatabaseBoundary() {
        assertThrows(DuplicateKeyException.class, () -> jdbcTemplate.update(
                "INSERT INTO area(city_id, region, name, sort_no) VALUES(?,?,?,?)",
                101L, "EU", "le marais", 99));
    }
}
