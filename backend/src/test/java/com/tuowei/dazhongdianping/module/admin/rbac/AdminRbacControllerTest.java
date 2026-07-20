package com.tuowei.dazhongdianping.module.admin.rbac;

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
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class AdminRbacControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

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
                                  "regions":["EU"]
                                }
                                """.formatted(roleId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.account").value("eu.operator"))
                .andReturn();
        long adminId = dataId(created);

        String operatorToken = login("eu.operator", "Operator#123456");
        mockMvc.perform(get("/api/admin/v1/shops")
                        .header("Authorization", bearer(operatorToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());

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
    void shouldTreatSuperAdminPermissionIdsAsAnUnorderedSet() throws Exception {
        String token = login("admin", "admin123456");

        mockMvc.perform(put("/api/admin/v1/rbac/roles/{roleId}", 1L)
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "code":"super_admin",
                                  "name":"系统管理员",
                                  "description":"维护管理员、角色和全站运营能力",
                                  "permissionIds":[31,30,29,28,27,26,25,24,23,22,21,20,19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1]
                                }
                                """))
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
