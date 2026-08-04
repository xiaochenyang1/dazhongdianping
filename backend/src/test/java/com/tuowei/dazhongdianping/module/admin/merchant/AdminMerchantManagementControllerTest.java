package com.tuowei.dazhongdianping.module.admin.merchant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
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
class AdminMerchantManagementControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbc;

    @Test
    void shouldListAndFilterMerchantsInsideCurrentRegion() throws Exception {
        String token = adminToken();

        mockMvc.perform(get("/api/admin/v1/merchants")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(2))
                .andExpect(jsonPath("$.data.list[0].id").value(1002))
                .andExpect(jsonPath("$.data.list[0].shopCount").value(1))
                .andExpect(jsonPath("$.data.list[0].operatorCount").value(0))
                .andExpect(jsonPath("$.data.list[0].activeOperatorCount").value(0))
                .andExpect(jsonPath("$.data.list[0].auditStatusText").value("已通过"))
                .andExpect(jsonPath("$.data.list[0].statusText").value("正常"));

        mockMvc.perform(get("/api/admin/v1/merchants")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .param("keyword", "渝里")
                        .param("auditStatus", "1")
                        .param("status", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(1001));
    }

    @Test
    void shouldReturnMerchantDetailAndRejectCrossRegionAccess() throws Exception {
        String token = adminToken();

        mockMvc.perform(get("/api/admin/v1/merchants/1001")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.companyName").value("沪上渝里餐饮"))
                .andExpect(jsonPath("$.data.contactName").value("王磊"))
                .andExpect(jsonPath("$.data.account").value("merchant_cn_hotpot@example.com"));

        mockMvc.perform(get("/api/admin/v1/merchants/2001")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("商户不存在"));
    }

    @Test
    void shouldDisableMerchantInvalidateExistingTokenAndAllowRestore() throws Exception {
        String adminToken = adminToken();
        String merchantToken = merchantToken("merchant_cn_hotpot@example.com", "merchant123456");

        mockMvc.perform(put("/api/admin/v1/merchants/1001/status")
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"action\":\"disable\",\"reason\":\"多次违反平台经营规则\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(2))
                .andExpect(jsonPath("$.data.statusText").value("已停用"))
                .andExpect(jsonPath("$.data.disableReason").value("多次违反平台经营规则"));

        mockMvc.perform(get("/api/b/v1/account/me")
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "CN"))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(post("/api/b/v1/auth/login")
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(merchantLoginBody("merchant_cn_hotpot@example.com", "merchant123456")))
                .andExpect(status().isUnauthorized());

        Integer disableLogs = jdbc.queryForObject("""
                SELECT COUNT(*) FROM audit_log
                WHERE action='merchant_disable' AND target='merchant:1001'
                  AND detail='多次违反平台经营规则'
                """, Integer.class);
        assertThat(disableLogs).isEqualTo(1);

        mockMvc.perform(put("/api/admin/v1/merchants/1001/status")
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"action\":\"enable\",\"reason\":\"整改复核通过\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1))
                .andExpect(jsonPath("$.data.statusText").value("正常"))
                .andExpect(jsonPath("$.data.disableReason").value(""));

        merchantToken("merchant_cn_hotpot@example.com", "merchant123456");
    }

    @Test
    void shouldRequireDisableReasonAndExposeAuthorizedMenu() throws Exception {
        String token = adminToken();

        mockMvc.perform(put("/api/admin/v1/merchants/1001/status")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"action\":\"disable\",\"reason\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("停用商户必须填写原因"));

        mockMvc.perform(get("/api/admin/v1/menus")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.code == 'system')].children"
                        + "[?(@.code == 'system.merchants')].path").value("/system/merchants"));
    }

    @Test
    void shouldListFilterAndInspectMerchantOperatorsInsideCurrentRegion() throws Exception {
        String staffAccount = "admin-operator-" + UUID.randomUUID() + "@example.com";
        long operatorId = createStaff(staffAccount);
        String token = adminToken();

        mockMvc.perform(get("/api/admin/v1/merchants/1001/operators")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .param("keyword", staffAccount)
                        .param("status", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(operatorId))
                .andExpect(jsonPath("$.data.list[0].roleNames[0]").value("核销员"))
                .andExpect(jsonPath("$.data.list[0].shopScopeType").value(2))
                .andExpect(jsonPath("$.data.list[0].shopIds[0]").value(10001));

        mockMvc.perform(get("/api/admin/v1/merchants/1001/operators/{operatorId}", operatorId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.account").value(staffAccount))
                .andExpect(jsonPath("$.data.statusText").value("正常"));

        mockMvc.perform(get("/api/admin/v1/merchants/2001/operators")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("商户不存在"));
    }

    @Test
    void shouldDisableMerchantOperatorInvalidateTokenAndAllowRestore() throws Exception {
        String staffAccount = "admin-disable-" + UUID.randomUUID() + "@example.com";
        long operatorId = createStaff(staffAccount);
        String staffToken = merchantToken(staffAccount, "Staff#123456");
        String ownerToken = merchantToken("merchant_cn_hotpot@example.com", "merchant123456");
        String adminToken = adminToken();

        mockMvc.perform(put("/api/admin/v1/merchants/1001/operators/{operatorId}/status", operatorId)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"action\":\"disable\",\"reason\":\"超范围操作券码\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(2))
                .andExpect(jsonPath("$.data.disableReason").value("超范围操作券码"));

        mockMvc.perform(get("/api/b/v1/account/me")
                        .header("Authorization", bearer(staffToken))
                        .header("X-Region", "CN"))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(post("/api/b/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(merchantLoginBody(staffAccount, "Staff#123456")))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(get("/api/b/v1/account/me")
                        .header("Authorization", bearer(ownerToken))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.operator.type").value("owner"));

        Integer disableLogs = jdbc.queryForObject("""
                SELECT COUNT(*) FROM audit_log
                WHERE action='merchant_operator_disable' AND target=? AND detail='超范围操作券码'
                """, Integer.class, "merchant_operator:" + operatorId);
        assertThat(disableLogs).isEqualTo(1);

        mockMvc.perform(put("/api/admin/v1/merchants/1001/operators/{operatorId}/status", operatorId)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"action\":\"enable\",\"reason\":\"复核通过\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1));

        merchantToken(staffAccount, "Staff#123456");
    }

    @Test
    void shouldRequireOperatorDisableReasonAndNeverExposeOwnerAsStaff() throws Exception {
        String staffAccount = "admin-reason-" + UUID.randomUUID() + "@example.com";
        long operatorId = createStaff(staffAccount);
        String token = adminToken();

        mockMvc.perform(put("/api/admin/v1/merchants/1001/operators/{operatorId}/status", operatorId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"action\":\"disable\",\"reason\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("停用商户员工必须填写原因"));

        mockMvc.perform(put("/api/admin/v1/merchants/1001/operators/11001/status")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"action\":\"disable\",\"reason\":\"不应允许\"}"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("商户员工不存在"));
    }

    @Test
    void shouldListAndFilterMerchantOperationHistoryInsideCurrentRegion() throws Exception {
        String staffAccount = "admin-history-" + UUID.randomUUID() + "@example.com";
        long operatorId = createStaff(staffAccount);
        String ownerToken = merchantToken("merchant_cn_hotpot@example.com", "merchant123456");
        mockMvc.perform(put("/api/b/v1/staffs/{id}/status", operatorId)
                        .header("Authorization", bearer(ownerToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":2}"))
                .andExpect(status().isOk());

        String token = adminToken();
        mockMvc.perform(get("/api/admin/v1/merchants/1001/operation-logs")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .param("pageSize", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(2))
                .andExpect(jsonPath("$.data.hasMore").value(true))
                .andExpect(jsonPath("$.data.list[0].action").value("staff_status"))
                .andExpect(jsonPath("$.data.list[0].operatorId").value(11001))
                .andExpect(jsonPath("$.data.list[0].operatorAccount").value("merchant_cn_hotpot@example.com"))
                .andExpect(jsonPath("$.data.list[0].targetType").value("staff"))
                .andExpect(jsonPath("$.data.list[0].targetId").value(operatorId));

        mockMvc.perform(get("/api/admin/v1/merchants/1001/operation-logs")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN")
                        .param("operatorId", "11001")
                        .param("action", "STAFF_CREATE")
                        .param("targetType", "STAFF")
                        .param("keyword", "merchant_cn_hotpot"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].action").value("staff_create"))
                .andExpect(jsonPath("$.data.list[0].targetId").value(operatorId));

        mockMvc.perform(get("/api/admin/v1/merchants/2001/operation-logs")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "CN"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("商户不存在"));
    }

    private String adminToken() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return readToken(result);
    }

    private long createStaff(String account) throws Exception {
        String ownerToken = merchantToken("merchant_cn_hotpot@example.com", "merchant123456");
        MvcResult result = mockMvc.perform(post("/api/b/v1/staffs")
                        .header("Authorization", bearer(ownerToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "%s",
                                  "password": "Staff#123456",
                                  "name": "Test Operator",
                                  "phone": "13800139999",
                                  "email": "%s",
                                  "roleIds": [12],
                                  "shopScopeType": 2,
                                  "shopIds": [10001]
                                }
                                """.formatted(account, account)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/id").asLong();
    }

    private String merchantToken(String account, String password) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/b/v1/auth/login")
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(merchantLoginBody(account, password)))
                .andExpect(status().isOk())
                .andReturn();
        return readToken(result);
    }

    private String readToken(MvcResult result) throws Exception {
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsString());
        return root.path("data").path("accessToken").asText();
    }

    private String merchantLoginBody(String account, String password) {
        return "{\"account\":\"" + account + "\",\"password\":\"" + password + "\"}";
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
