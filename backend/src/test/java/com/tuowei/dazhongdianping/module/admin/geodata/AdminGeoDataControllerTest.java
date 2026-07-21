package com.tuowei.dazhongdianping.module.admin.geodata;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class AdminGeoDataControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void shouldRequireAuthenticationAndEnforceReadWritePermissions() throws Exception {
        mockMvc.perform(get("/api/admin/v1/categories").header("X-Region", "EU"))
                .andExpect(status().isUnauthorized());

        String readerToken = createReadOnlyAdminAndLogin();
        mockMvc.perform(get("/api/admin/v1/categories")
                        .header("Authorization", bearer(readerToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(4));
        mockMvc.perform(post("/api/admin/v1/categories")
                        .header("Authorization", bearer(readerToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"parentId\":0,\"name\":\"Forbidden\",\"sortNo\":1}"))
                .andExpect(status().isForbidden());

        MvcResult menuResult = mockMvc.perform(get("/api/admin/v1/menus")
                        .header("Authorization", bearer(readerToken)))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode roots = objectMapper.readTree(menuResult.getResponse().getContentAsString()).path("data");
        boolean hasGeoMenu = false;
        for (JsonNode root : roots) {
            for (JsonNode child : root.path("children")) {
                hasGeoMenu |= "/data/meta".equals(child.path("path").asText());
            }
        }
        assertTrue(hasGeoMenu, "data:geo:read 应显示基础数据菜单");
    }

    @Test
    void shouldCreateUpdateListAndDeleteCategories() throws Exception {
        String token = loginToken("admin");
        MvcResult root = createCategory(token, 0L, "  Plan Root  ", 8)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Plan Root"))
                .andExpect(jsonPath("$.data.parentId").value(0))
                .andExpect(jsonPath("$.data.status").value(1))
                .andReturn();
        long rootId = findId(root);

        long childId = findId(createCategory(token, rootId, "Plan Child", 7).andReturn());
        mockMvc.perform(put("/api/admin/v1/categories/{id}", childId)
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"parentId\":" + rootId + ",\"name\":\" Plan Updated \",\"sortNo\":3}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Plan Updated"))
                .andExpect(jsonPath("$.data.sortNo").value(3));

        mockMvc.perform(put("/api/admin/v1/categories/{id}/status", rootId)
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"status\":0}"))
                .andExpect(status().isConflict());
        updateStatus(token, "categories", childId, 0).andExpect(status().isOk());
        updateStatus(token, "categories", rootId, 0)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(0));

        mockMvc.perform(delete("/api/admin/v1/categories/{id}", rootId)
                        .header("Authorization", bearer(token)).header("X-Region", "EU"))
                .andExpect(status().isConflict());
        deleteGeo(token, "categories", childId).andExpect(status().isOk());
        deleteGeo(token, "categories", rootId).andExpect(status().isOk());
    }

    @Test
    void shouldRejectCreatingChildUnderDisabledCategory() throws Exception {
        String token = loginToken("admin");
        long parentId = findId(createCategory(token, 0L, "Disabled Create Parent", 8)
                .andExpect(status().isOk()).andReturn());
        updateStatus(token, "categories", parentId, 0).andExpect(status().isOk());

        createCategory(token, parentId, "Blocked Child", 1)
                .andExpect(status().isConflict());
        assertEquals(0, jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM category WHERE region='EU' AND parent_id=? AND name='Blocked Child'",
                Integer.class,
                parentId));
    }

    @Test
    void shouldRejectMovingCategoryUnderDisabledParent() throws Exception {
        String token = loginToken("admin");
        long sourceParentId = findId(createCategory(token, 0L, "Enabled Move Parent", 8)
                .andExpect(status().isOk()).andReturn());
        long targetParentId = findId(createCategory(token, 0L, "Disabled Move Parent", 9)
                .andExpect(status().isOk()).andReturn());
        long childId = findId(createCategory(token, sourceParentId, "Movable Child", 1)
                .andExpect(status().isOk()).andReturn());
        updateStatus(token, "categories", targetParentId, 0).andExpect(status().isOk());

        mockMvc.perform(put("/api/admin/v1/categories/{id}", childId)
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"parentId\":" + targetParentId
                                + ",\"name\":\"Movable Child\",\"sortNo\":1}"))
                .andExpect(status().isConflict());
        assertEquals(sourceParentId, jdbcTemplate.queryForObject(
                "SELECT parent_id FROM category WHERE id=?", Long.class, childId));
    }

    @Test
    void shouldRejectEnablingChildWhileParentIsDisabled() throws Exception {
        String token = loginToken("admin");
        long parentId = findId(createCategory(token, 0L, "Disabled Enable Parent", 8)
                .andExpect(status().isOk()).andReturn());
        long childId = findId(createCategory(token, parentId, "Disabled Enable Child", 1)
                .andExpect(status().isOk()).andReturn());
        updateStatus(token, "categories", childId, 0).andExpect(status().isOk());
        updateStatus(token, "categories", parentId, 0).andExpect(status().isOk());

        updateStatus(token, "categories", childId, 1)
                .andExpect(status().isConflict());
        assertEquals(0, jdbcTemplate.queryForObject(
                "SELECT status FROM category WHERE id=?", Integer.class, childId));
    }

    @Test
    void shouldRejectCategoryConflictsCyclesCrossRegionAndReferences() throws Exception {
        String token = loginToken("admin");
        createCategory(token, 0L, "Dining", 99).andExpect(status().isConflict());

        mockMvc.perform(put("/api/admin/v1/categories/{id}", 200L)
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"parentId\":200,\"name\":\"Dining\",\"sortNo\":1}"))
                .andExpect(status().isConflict());
        mockMvc.perform(put("/api/admin/v1/categories/{id}", 200L)
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"parentId\":201,\"name\":\"Dining\",\"sortNo\":1}"))
                .andExpect(status().isConflict());
        mockMvc.perform(put("/api/admin/v1/categories/{id}", 100L)
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"parentId\":0,\"name\":\"Wrong Region\",\"sortNo\":1}"))
                .andExpect(status().isNotFound());

        deleteGeo(token, "categories", 200L).andExpect(status().isConflict());
        deleteGeo(token, "categories", 202L).andExpect(status().isConflict());
    }

    @Test
    void shouldCrudCitiesAndAreasAndProtectTheirReferences() throws Exception {
        String token = loginToken("admin");
        long cityId = findId(mockMvc.perform(post("/api/admin/v1/cities")
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"code\":\" plan \",\"name\":\" Plan City \",\"sortNo\":8}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.code").value("PLAN"))
                .andExpect(jsonPath("$.data.name").value("Plan City"))
                .andReturn());

        long areaId = findId(mockMvc.perform(post("/api/admin/v1/areas")
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"cityId\":" + cityId + ",\"name\":\" Plan Area \",\"sortNo\":6}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.cityId").value(cityId))
                .andExpect(jsonPath("$.data.name").value("Plan Area"))
                .andReturn());

        mockMvc.perform(put("/api/admin/v1/cities/{id}", cityId)
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"code\":\" pln \",\"name\":\" Plan Ville \",\"sortNo\":2}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.code").value("PLN"))
                .andExpect(jsonPath("$.data.sortNo").value(2));
        mockMvc.perform(put("/api/admin/v1/areas/{id}", areaId)
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"cityId\":" + cityId + ",\"name\":\" Plan Quarter \",\"sortNo\":1}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Plan Quarter"));

        deleteGeo(token, "cities", cityId).andExpect(status().isConflict());
        updateStatus(token, "cities", cityId, 0).andExpect(status().isOk());
        updateStatus(token, "areas", areaId, 1)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("城市不存在、不启用或不属于当前区域"));
        updateStatus(token, "areas", areaId, 0).andExpect(status().isOk());
        updateStatus(token, "areas", areaId, 1)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("城市不存在、不启用或不属于当前区域"));
        assertEquals(0, jdbcTemplate.queryForObject(
                "SELECT status FROM area WHERE id=?", Integer.class, areaId));
        mockMvc.perform(get("/api/admin/v1/areas")
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .param("cityId", String.valueOf(cityId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].id").value(areaId));
        mockMvc.perform(post("/api/admin/v1/areas")
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"cityId\":" + cityId + ",\"name\":\"Blocked\",\"sortNo\":9}"))
                .andExpect(status().isConflict());
        updateStatus(token, "cities", cityId, 1).andExpect(status().isOk());
        updateStatus(token, "areas", areaId, 1).andExpect(status().isOk());

        deleteGeo(token, "areas", areaId).andExpect(status().isOk());
        deleteGeo(token, "cities", cityId).andExpect(status().isOk());

        deleteGeo(token, "cities", 101L).andExpect(status().isConflict());
        deleteGeo(token, "areas", 1011L).andExpect(status().isConflict());
    }

    @Test
    void shouldRejectDuplicateAndInvalidCityAreaScopes() throws Exception {
        String token = loginToken("admin");
        mockMvc.perform(post("/api/admin/v1/cities")
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"code\":\"par\",\"name\":\"Other City\",\"sortNo\":1}"))
                .andExpect(status().isConflict());
        mockMvc.perform(post("/api/admin/v1/cities")
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"code\":\"OTHER\",\"name\":\"Paris\",\"sortNo\":1}"))
                .andExpect(status().isConflict());
        mockMvc.perform(post("/api/admin/v1/areas")
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"cityId\":101,\"name\":\"Le Marais\",\"sortNo\":1}"))
                .andExpect(status().isConflict());
        mockMvc.perform(post("/api/admin/v1/areas")
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"cityId\":1,\"name\":\"Wrong Region\",\"sortNo\":1}"))
                .andExpect(status().isConflict());
        mockMvc.perform(put("/api/admin/v1/areas/{id}", 11L)
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"cityId\":101,\"name\":\"Wrong Area\",\"sortNo\":1}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void shouldRejectMovingReferencedAreaToAnotherCity() throws Exception {
        String token = loginToken("admin");
        long targetCityId = findId(mockMvc.perform(post("/api/admin/v1/cities")
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"code\":\"MOVE\",\"name\":\"Move Target\",\"sortNo\":9}"))
                .andExpect(status().isOk())
                .andReturn());

        mockMvc.perform(put("/api/admin/v1/areas/{id}", 1011L)
                        .header("Authorization", bearer(token)).header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"cityId\":" + targetCityId
                                + ",\"name\":\"Referenced Move\",\"sortNo\":1}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("商圈仍被业务数据引用，不能迁移到其他城市"));
        assertEquals(101L, jdbcTemplate.queryForObject(
                "SELECT city_id FROM area WHERE id=1011", Long.class));
    }

    private org.springframework.test.web.servlet.ResultActions createCategory(
            String token, long parentId, String name, int sortNo) throws Exception {
        return mockMvc.perform(post("/api/admin/v1/categories")
                .header("Authorization", bearer(token)).header("X-Region", "EU")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"parentId\":" + parentId + ",\"name\":\"" + name + "\",\"sortNo\":" + sortNo + "}"));
    }

    private org.springframework.test.web.servlet.ResultActions updateStatus(
            String token, String resource, long id, int statusValue) throws Exception {
        return mockMvc.perform(put("/api/admin/v1/{resource}/{id}/status", resource, id)
                .header("Authorization", bearer(token)).header("X-Region", "EU")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":" + statusValue + "}"));
    }

    private org.springframework.test.web.servlet.ResultActions deleteGeo(
            String token, String resource, long id) throws Exception {
        return mockMvc.perform(delete("/api/admin/v1/{resource}/{id}", resource, id)
                .header("Authorization", bearer(token)).header("X-Region", "EU"));
    }

    private long findId(MvcResult result) throws Exception {
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/id").asLong();
    }

    private String createReadOnlyAdminAndLogin() throws Exception {
        jdbcTemplate.update("""
                INSERT INTO admin_role(code, name, description, status, built_in)
                VALUES('geo_reader_test', '基础数据只读测试', '', 1, FALSE)
                """);
        Long roleId = jdbcTemplate.queryForObject(
                "SELECT id FROM admin_role WHERE code='geo_reader_test'", Long.class);
        jdbcTemplate.update("""
                INSERT INTO admin_user(account, password_hash, name, status)
                SELECT 'geo-reader-test', password_hash, '基础数据只读测试', 1
                FROM admin_user WHERE id=1
                """);
        Long adminId = jdbcTemplate.queryForObject(
                "SELECT id FROM admin_user WHERE account='geo-reader-test'", Long.class);
        jdbcTemplate.update("INSERT INTO admin_user_role(admin_id, role_id) VALUES(?,?)", adminId, roleId);
        jdbcTemplate.update("""
                INSERT INTO admin_role_permission(role_id, permission_id)
                SELECT ?, id FROM admin_permission WHERE code='data:geo:read'
                """, roleId);
        jdbcTemplate.update("INSERT INTO admin_region_scope(admin_id, region) VALUES(?, 'EU')", adminId);
        return loginToken("geo-reader-test");
    }

    private String loginToken(String account) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"" + account + "\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString())
                .at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
