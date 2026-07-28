package com.tuowei.dazhongdianping.module.admin.rbac;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.admin.AdminCityScope;
import com.tuowei.dazhongdianping.module.admin.auth.service.AdminAuthService;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Set;
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
class AdminRbacControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private AdminAuthService adminAuthService;
    @Autowired private JdbcTemplate jdbc;

    @Test
    void shouldManageCustomRolesAndProtectBuiltInSuperAdmin() throws Exception {
        String token = login("admin", "admin123456");

        mockMvc.perform(get("/api/admin/v1/rbac/permissions")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.code == 'system:admin:write')]").isNotEmpty());

        long roleId = createRole(token, "eu_shop_reader", "EU 门店只读员", 14L);

        mockMvc.perform(get("/api/admin/v1/rbac/roles")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == " + roleId + ")].permissionIds[0]").value(14));

        mockMvc.perform(post("/api/admin/v1/rbac/roles")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"eu_shop_reader","name":"重复角色","description":"重复","permissionIds":[14]}
                                """))
                .andExpect(status().isConflict());

        mockMvc.perform(put("/api/admin/v1/rbac/roles/{roleId}/status", 1L)
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{" + "\"status\":2" + "}"))
                .andExpect(status().isConflict());

        mockMvc.perform(delete("/api/admin/v1/rbac/roles/{roleId}", roleId)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk());
    }

    @Test
    void shouldCreateAdminAndImmediatelyRevokePermissionsWhenItsRoleIsDisabled() throws Exception {
        String superAdminToken = login("admin", "admin123456");
        long roleId = createRole(superAdminToken, "eu_shop_operator", "EU 门店操作员", 14L);

        MvcResult created = mockMvc.perform(post("/api/admin/v1/rbac/admins")
                        .header("Authorization", bearer(superAdminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account":"eu.operator",
                                  "password":"Operator#123456",
                                  "name":"EU 门店操作员",
                                  "roleIds":[%d],
                                  "regions":["EU"],
                                  "cityScopes":[{"region":"EU","allCities":false,"cityIds":[101]}]
                                }
                                """.formatted(roleId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.account").value("eu.operator"))
                .andExpect(jsonPath("$.data.cityScopes[0].region").value("EU"))
                .andExpect(jsonPath("$.data.cityScopes[0].allCities").value(false))
                .andExpect(jsonPath("$.data.cityScopes[0].cityIds[0]").value(101))
                .andReturn();
        long adminId = dataId(created);

        String operatorToken = login("eu.operator", "Operator#123456");
        mockMvc.perform(get("/api/admin/v1/shops")
                        .header("Authorization", bearer(operatorToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(20001));

        mockMvc.perform(put("/api/admin/v1/rbac/admins/{adminId}", adminId)
                        .header("Authorization", bearer(superAdminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name":"EU 门店操作员",
                                  "roleIds":[%d],
                                  "regions":["EU"],
                                  "cityScopes":[{"region":"EU","allCities":false,"cityIds":[102]}]
                                }
                                """.formatted(roleId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.cityScopes[0].cityIds[0]").value(102));

        AdminCityScope refreshedScope = adminAuthService.authenticate(operatorToken).cityScopes().get("EU");
        assertNotNull(refreshedScope);
        assertFalse(refreshedScope.allCities());
        assertEquals(Set.of(102L), refreshedScope.cityIds());

        mockMvc.perform(get("/api/admin/v1/shops")
                        .header("Authorization", bearer(operatorToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(20002));

        mockMvc.perform(put("/api/admin/v1/rbac/roles/{roleId}/status", roleId)
                        .header("Authorization", bearer(superAdminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{" + "\"status\":2" + "}"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/admin/v1/shops")
                        .header("Authorization", bearer(operatorToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isForbidden());

        mockMvc.perform(put("/api/admin/v1/rbac/admins/{adminId}/status", 1L)
                        .header("Authorization", bearer(superAdminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{" + "\"status\":2" + "}"))
                .andExpect(status().isConflict());

        mockMvc.perform(put("/api/admin/v1/rbac/admins/{adminId}/password", adminId)
                        .header("Authorization", bearer(superAdminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{" + "\"password\":\"Operator#654321\"" + "}"))
                .andExpect(status().isOk());

        login("eu.operator", "Operator#654321");
    }

    @Test
    void shouldListOnlyActiveScopeCities() throws Exception {
        String token = login("admin", "admin123456");
        jdbc.update("UPDATE city SET status=0 WHERE id=102");

        mockMvc.perform(get("/api/admin/v1/rbac/scope-cities")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == 1 && @.region == 'CN' && @.name == '上海')]").isNotEmpty())
                .andExpect(jsonPath("$.data[?(@.id == 101 && @.region == 'EU' && @.name == 'Paris')]").isNotEmpty())
                .andExpect(jsonPath("$.data[?(@.id == 102)]").isEmpty());
    }

    @Test
    void shouldListActiveScopeShopsAndPersistShopWhitelist() throws Exception {
        String token = login("admin", "admin123456");
        mockMvc.perform(get("/api/admin/v1/rbac/scope-shops")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id == 20001 && @.region == 'EU' && @.cityId == 101)]").isNotEmpty())
                .andExpect(jsonPath("$.data[?(@.id == 20002 && @.region == 'EU' && @.cityId == 102)]").isNotEmpty());

        long roleId = createRole(token, "shop_scope_validator", "门店白名单校验员", 14L);
        MvcResult result = mockMvc.perform(post("/api/admin/v1/rbac/admins")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "account", "shop.whitelist",
                                "password", "Operator#123456",
                                "name", "门店白名单管理员",
                                "roleIds", List.of(roleId),
                                "regions", List.of("EU"),
                                "cityScopes", List.of(Map.of(
                                        "region", "EU",
                                        "allCities", false,
                                        "cityIds", List.of(),
                                        "shopIds", List.of(20001L)
                                ))
                        ))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.cityScopes[0].shopIds[0]").value(20001))
                .andReturn();
        long adminId = dataId(result);
        AdminCityScope scope = adminAuthService.authenticate(login("shop.whitelist", "Operator#123456")).cityScopes().get("EU");
        assertNotNull(scope);
        assertEquals(Set.of(20001L), scope.shopIds());
        assertEquals(adminId, jdbc.queryForObject("SELECT admin_id FROM admin_shop_scope WHERE shop_id=20001 AND region='EU'", Long.class));
    }

    @Test
    void shouldRejectInvalidAdminCityScopes() throws Exception {
        String token = login("admin", "admin123456");
        long roleId = createRole(token, "city_scope_validator", "城市范围校验员", 14L);

        assertAdminCreateBadRequest(token, roleId, "scope.ids.missing", List.of("EU"), List.of(
                Map.of("region", "EU", "allCities", true)
        ));
        assertAdminCreateBadRequest(token, roleId, "scope.all.ids", List.of("EU"), List.of(
                Map.of("region", "EU", "allCities", true, "cityIds", List.of(101L))
        ));
        assertAdminCreateBadRequest(token, roleId, "scope.selected.empty", List.of("EU"), List.of(
                Map.of("region", "EU", "allCities", false, "cityIds", List.of())
        ));
        assertAdminCreateBadRequest(token, roleId, "scope.region.mismatch", List.of("EU"), List.of(
                Map.of("region", "CN", "allCities", true, "cityIds", List.of())
        ));
        assertAdminCreateBadRequest(token, roleId, "scope.cross.region", List.of("EU"), List.of(
                Map.of("region", "EU", "allCities", false, "cityIds", List.of(1L))
        ));

        jdbc.update("UPDATE city SET status=0 WHERE id=102");
        assertAdminCreateBadRequest(token, roleId, "scope.inactive.city", List.of("EU"), List.of(
                Map.of("region", "EU", "allCities", false, "cityIds", List.of(102L))
        ));
    }

    @Test
    void shouldTreatSuperAdminPermissionIdsAsAnUnorderedSet() throws Exception {
        String token = login("admin", "admin123456");
        MvcResult permissionsResult = mockMvc.perform(get("/api/admin/v1/rbac/permissions")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andReturn();
        List<Long> permissionIds = new ArrayList<>();
        objectMapper.readTree(permissionsResult.getResponse().getContentAsString())
                .path("data")
                .forEach(permission -> permissionIds.add(permission.path("id").asLong()));
        Collections.reverse(permissionIds);

        mockMvc.perform(put("/api/admin/v1/rbac/roles/{roleId}", 1L)
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "code", "super_admin",
                                "name", "系统管理员",
                                "description", "维护管理员、角色和全站运营能力",
                                "permissionIds", permissionIds
                        ))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.code").value("super_admin"));
    }

    private long createRole(String token, String code, String name, long permissionId) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/rbac/roles")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"code":"%s","name":"%s","description":"测试角色","permissionIds":[%d]}
                                """.formatted(code, name, permissionId)))
                .andExpect(status().isOk())
                .andReturn();
        return dataId(result);
    }

    private void assertAdminCreateBadRequest(
            String token,
            long roleId,
            String account,
            List<String> regions,
            List<Map<String, Object>> cityScopes
    ) throws Exception {
        mockMvc.perform(post("/api/admin/v1/rbac/admins")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "account", account,
                                "password", "Operator#123456",
                                "name", "城市范围测试管理员",
                                "roleIds", List.of(roleId),
                                "regions", regions,
                                "cityScopes", cityScopes
                        ))))
                .andExpect(status().isBadRequest());
    }

    private String login(String account, String password) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"account":"%s","password":"%s"}
                                """.formatted(account, password)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString())
                .at("/data/accessToken")
                .asText();
    }

    private long dataId(MvcResult result) throws Exception {
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        return body.at("/data/id").asLong();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
