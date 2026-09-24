package com.tuowei.dazhongdianping.module.openapi;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.charset.StandardCharsets;
import java.util.HexFormat;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
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
class OpenApiControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;

    @Test
    void signedShopQueryUsesAppRegionAndRejectsBadSignature() throws Exception {
        String admin = adminToken();
        MvcResult created = mockMvc.perform(post("/api/admin/v1/openapi/apps")
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"火锅开放应用\",\"ownerMerchantId\":1001}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("admin.openapi_app_created"))
                .andExpect(jsonPath("$.data.status").value(1))
                .andReturn();
        JsonNode data = objectMapper.readTree(created.getResponse().getContentAsString()).at("/data");
        long appId = data.path("id").asLong();
        String keyId = data.path("keyId").asText();
        String secret = data.path("secret").asText();
        assertFalse(keyId.isBlank());
        assertFalse(secret.isBlank());

        MvcResult listed = mockMvc.perform(get("/api/admin/v1/openapi/apps")
                        .header("Authorization", bearer(admin)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andReturn();
        String listBody = listed.getResponse().getContentAsString();
        assertFalse(listBody.contains(secret));
        JsonNode apps = objectMapper.readTree(listBody).path("data");
        boolean found = false;
        for (JsonNode app : apps) {
            if (app.path("id").asLong() == appId) {
                found = true;
                assertEquals(keyId, app.path("keyIds").path(0).asText());
                assertTrue(app.path("secret").isMissingNode());
            }
        }
        assertTrue(found);

        String path = "/api/open/v1/shops";
        String timestamp = String.valueOf(System.currentTimeMillis());
        String signature = sign(secret, keyId, timestamp, "GET", path);
        mockMvc.perform(get(path).param("limit", "10")
                        .header("X-Open-Key", keyId)
                        .header("X-Open-Timestamp", timestamp)
                        .header("X-Open-Signature", signature)
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id==10001)].name").value(org.hamcrest.Matchers.hasItem("渝里火锅徐汇店")))
                .andExpect(jsonPath("$.data[?(@.id==20001)]").doesNotExist());

        String reviewPath = "/api/open/v1/reviews";
        String reviewSignature = sign(secret, keyId, timestamp, "GET", reviewPath);
        mockMvc.perform(get(reviewPath).param("shopId", "10001").param("limit", "10")
                        .header("X-Open-Key", keyId)
                        .header("X-Open-Timestamp", timestamp)
                        .header("X-Open-Signature", reviewSignature)
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id==1)].shopId").value(org.hamcrest.Matchers.hasItem(10001)))
                .andExpect(jsonPath("$.data[?(@.id==3)]").doesNotExist());

        mockMvc.perform(get(path).param("limit", "10")
                        .header("X-Open-Key", keyId)
                        .header("X-Open-Timestamp", timestamp)
                        .header("X-Open-Signature", "deadbeef")
                        .header("X-Region", "CN"))
                .andExpect(status().isUnauthorized());
    }

    private String sign(String secret, String keyId, String timestamp, String method, String path) throws Exception {
        String canonical = keyId + "\n" + timestamp + "\n" + method + "\n" + path;
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        return HexFormat.of().formatHex(mac.doFinal(canonical.getBytes(StandardCharsets.UTF_8)));
    }

    private String adminToken() throws Exception {
        MvcResult login = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(login.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
