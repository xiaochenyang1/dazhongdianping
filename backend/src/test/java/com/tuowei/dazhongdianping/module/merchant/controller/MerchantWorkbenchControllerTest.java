package com.tuowei.dazhongdianping.module.merchant.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.module.auth.service.UserAccessTokenService;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.test.web.servlet.MockMvc;

@Transactional
@SpringBootTest(properties = {
        "app.merchant.access-token-expire-seconds=1",
        "spring.datasource.url=jdbc:h2:mem:dazhongdianping-merchant-test;MODE=MYSQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE"
})
@AutoConfigureMockMvc
class MerchantWorkbenchControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserAccessTokenService userAccessTokenService;

    @Autowired
    private JdbcTemplate jdbc;

    @Test
    void shouldExposeMerchantApiPrefixHealthEndpoint() throws Exception {
        mockMvc.perform(get("/api/b/v1/health"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.service").value("merchant-workbench"))
                .andExpect(jsonPath("$.data.status").value("ok"));
    }

    @Test
    void shouldLoginWithConfiguredMerchantAccount() throws Exception {
        mockMvc.perform(post("/api/b/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "merchant_eu_sichuan@example.com",
                                  "password": "merchant123456"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.data.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.data.merchantId").value(2001))
                .andExpect(jsonPath("$.data.account").value("merchant_eu_sichuan@example.com"));
    }

    @Test
    @Transactional(propagation = Propagation.NOT_SUPPORTED)
    void shouldAuthenticateDatabaseMerchantAccountsAndRejectDisabledOperator() throws Exception {
        try {
            mockMvc.perform(post("/api/b/v1/auth/login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {
                                      "account": "merchant_eu_cafe@example.com",
                                      "password": "merchant123456"
                                    }
                                    """))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.merchantId").value(2002))
                    .andExpect(jsonPath("$.data.account").value("merchant_eu_cafe@example.com"));

            jdbc.update("UPDATE merchant_operator SET status=2 WHERE account='merchant_eu_cafe@example.com'");

            mockMvc.perform(post("/api/b/v1/auth/login")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("""
                                    {
                                      "account": "merchant_eu_cafe@example.com",
                                      "password": "merchant123456"
                                    }
                                    """))
                    .andExpect(status().isUnauthorized())
                    .andExpect(jsonPath("$.code").value(401));
        } finally {
            jdbc.update("UPDATE merchant_operator SET status=1 WHERE account='merchant_eu_cafe@example.com'");
        }
    }

    @Test
    void shouldRejectInvalidMerchantCredentials() throws Exception {
        mockMvc.perform(post("/api/b/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "merchant_eu_sichuan@example.com",
                                  "password": "wrong-password"
                                }
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));
    }

    @ParameterizedTest
    @ValueSource(strings = {
            "/api/b/v1/account/me",
            "/api/b/v1/roles",
            "/api/b/v1/shops"
    })
    void shouldRequireMerchantTokenForWorkbenchEndpoints(String path) throws Exception {
        mockMvc.perform(get(path).header("X-Region", "EU"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));
    }

    @Test
    void shouldRejectAdminTokenOnMerchantEndpoint() throws Exception {
        String adminToken = loginAdmin();

        mockMvc.perform(get("/api/b/v1/account/me")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(adminToken)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));
    }

    @Test
    void shouldRejectUserTokenOnMerchantEndpoint() throws Exception {
        String userToken = userAccessTokenService.issue(99L, 99L);

        mockMvc.perform(get("/api/b/v1/account/me")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(userToken)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));
    }

    @Test
    void shouldRejectExpiredMerchantToken() throws Exception {
        String merchantToken = loginMerchant();
        Thread.sleep(1200L);

        mockMvc.perform(get("/api/b/v1/roles")
                        .header("Authorization", bearer(merchantToken)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));
    }

    @Test
    void shouldExposeMerchantAccountSummary() throws Exception {
        mockMvc.perform(get("/api/b/v1/account/me")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(loginMerchant())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.merchant.id").value(2001))
                .andExpect(jsonPath("$.data.merchant.companyName").value("Maison Sichuan SARL"))
                .andExpect(jsonPath("$.data.merchant.region").value("EU"))
                .andExpect(jsonPath("$.data.operator.type").value("owner"))
                .andExpect(jsonPath("$.data.permissions[0]").value("shop:view"));
    }

    @Test
    void shouldExposeMerchantWorkbenchRoles() throws Exception {
        mockMvc.perform(get("/api/b/v1/roles")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(loginMerchant())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.list[0].code").value("owner"))
                .andExpect(jsonPath("$.data.list[1].code").value("store_manager"))
                .andExpect(jsonPath("$.data.list[2].permissions[0]").value("coupon:verify"));
    }

    @Test
    void shouldExposeMerchantShopListByRegion() throws Exception {
        mockMvc.perform(get("/api/b/v1/shops")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(loginMerchant())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.list[0].id").value(20001))
                .andExpect(jsonPath("$.data.list[0].name").value("Maison Sichuan Paris"))
                .andExpect(jsonPath("$.data.list.length()").value(1))
                .andExpect(jsonPath("$.data.total").value(1));
    }

    @Test
    void shouldRejectMerchantWorkbenchOutsideCurrentMerchantRegion() throws Exception {
        String token = loginMerchant();

        mockMvc.perform(get("/api/b/v1/account/me")
                        .header("X-Region", "CN")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401))
                .andExpect(jsonPath("$.message").value("当前区域无权访问该商户工作台"));

        mockMvc.perform(get("/api/b/v1/roles")
                        .header("X-Region", "CN")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401))
                .andExpect(jsonPath("$.message").value("当前区域无权访问该商户工作台"));

        mockMvc.perform(get("/api/b/v1/shops")
                        .header("X-Region", "CN")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401))
                .andExpect(jsonPath("$.message").value("当前区域无权访问该商户工作台"));
    }

    private String loginMerchant() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/b/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "merchant_eu_sichuan@example.com",
                                  "password": "merchant123456"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();
        return readAccessToken(result);
    }

    private String loginAdmin() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "admin",
                                  "password": "admin123456"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();
        return readAccessToken(result);
    }

    private String readAccessToken(MvcResult result) throws Exception {
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsByteArray());
        return root.path("data").path("accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
