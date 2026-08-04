package com.tuowei.dazhongdianping.module.admin.merchant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.UUID;
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
class AdminMerchantApplicationControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void shouldListAndApproveMerchantApplication() throws Exception {
        Registration registration = registerAndApply();
        String adminToken = adminToken();

        mockMvc.perform(get("/api/admin/v1/merchant-applications")
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "EU")
                        .param("status", "0"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].merchantId").value(registration.merchantId()))
                .andExpect(jsonPath("$.data.list[0].status").value(0));

        mockMvc.perform(post("/api/admin/v1/merchant-applications/{merchantId}/audit", registration.merchantId())
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":1,\"reason\":\"资料齐全\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1));

        mockMvc.perform(get("/api/b/v1/account/me")
                        .header("Authorization", bearer(registration.merchantToken()))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.merchant.id").value(registration.merchantId()));
    }

    @Test
    void shouldRequireReasonWhenRejectingApplication() throws Exception {
        Registration registration = registerAndApply();

        mockMvc.perform(post("/api/admin/v1/merchant-applications/{merchantId}/audit", registration.merchantId())
                        .header("Authorization", bearer(adminToken()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":2,\"reason\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("驳回时必须填写原因"));
    }

    @Test
    void shouldHideUnassignedApplicationsFromCityScopedAuditors() throws Exception {
        Registration registration = registerAndApply();
        String scopedToken = cityScopedAdminToken();

        mockMvc.perform(get("/api/admin/v1/merchant-applications")
                        .header("Authorization", bearer(scopedToken))
                        .header("X-Region", "EU")
                        .param("status", "0"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(0))
                .andExpect(jsonPath("$.data.list").isEmpty());

        mockMvc.perform(post("/api/admin/v1/merchant-applications/{merchantId}/audit", registration.merchantId())
                        .header("Authorization", bearer(scopedToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":1,\"reason\":\"不应越权\"}"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("商户资质申请不存在"));
        Integer applicationStatus = jdbc.queryForObject(
                "SELECT status FROM merchant_application WHERE merchant_id=?",
                Integer.class,
                registration.merchantId()
        );
        assertThat(applicationStatus).isZero();

        mockMvc.perform(post("/api/admin/v1/merchant-applications/{merchantId}/audit", registration.merchantId())
                        .header("Authorization", bearer(adminToken()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":1,\"reason\":\"区域全量复核通过\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1));
    }

    private Registration registerAndApply() throws Exception {
        String account = "audit-merchant-" + UUID.randomUUID() + "@example.com";
        MvcResult registered = mockMvc.perform(post("/api/b/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "%s",
                                  "password": "Merchant#123456",
                                  "companyName": "Audit Foods SARL",
                                  "contactName": "Claire",
                                  "contactPhone": "+33111111111",
                                  "region": "EU"
                                }
                                """.formatted(account)))
                .andExpect(status().isOk())
                .andReturn();
        var data = objectMapper.readTree(registered.getResponse().getContentAsString()).path("data");
        long merchantId = data.path("merchantId").asLong();
        String merchantToken = data.path("accessToken").asText();
        mockMvc.perform(post("/api/b/v1/settle/apply")
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "licenseUrl": "https://files.example/license.png",
                                  "legalPerson": "Claire",
                                  "shopPhotoUrls": ["https://files.example/shop.png"]
                                }
                                """))
                .andExpect(status().isOk());
        return new Registration(merchantId, merchantToken);
    }

    private String adminToken() throws Exception {
        return adminToken("admin");
    }

    private String cityScopedAdminToken() throws Exception {
        String suffix = UUID.randomUUID().toString().replace("-", "").substring(0, 12);
        String account = "app-scope-" + suffix + "@test.local";
        String roleCode = "app_scope_" + suffix;
        String passwordHash = jdbc.queryForObject(
                "SELECT password_hash FROM admin_user WHERE id=1", String.class);
        jdbc.update(
                "INSERT INTO admin_user(account,password_hash,name,status) VALUES(?,?,?,1)",
                account, passwordHash, "资质范围测试管理员");
        Long adminId = jdbc.queryForObject("SELECT id FROM admin_user WHERE account=?", Long.class, account);
        jdbc.update(
                "INSERT INTO admin_role(code,name,description,status,built_in) VALUES(?,?,?,1,FALSE)",
                roleCode, "资质范围测试角色", "商户资质城市范围集成测试");
        Long roleId = jdbc.queryForObject("SELECT id FROM admin_role WHERE code=?", Long.class, roleCode);
        jdbc.update("INSERT INTO admin_user_role(admin_id,role_id) VALUES(?,?)", adminId, roleId);
        jdbc.update("""
                INSERT INTO admin_role_permission(role_id,permission_id)
                SELECT ?,id FROM admin_permission
                WHERE code IN ('audit:merchant_application:read','audit:merchant_application:write')
                """, roleId);
        jdbc.update(
                "INSERT INTO admin_region_scope(admin_id,region,all_cities) VALUES(?,'EU',FALSE)", adminId);
        jdbc.update(
                "INSERT INTO admin_city_scope(admin_id,region,city_id) VALUES(?,'EU',101)", adminId);
        return adminToken(account);
    }

    private String adminToken(String account) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"" + account + "\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }

    private record Registration(long merchantId, String merchantToken) {
    }
}
