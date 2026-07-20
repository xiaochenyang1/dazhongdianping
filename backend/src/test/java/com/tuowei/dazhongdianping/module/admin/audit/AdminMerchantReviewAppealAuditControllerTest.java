package com.tuowei.dazhongdianping.module.admin.audit;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
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
class AdminMerchantReviewAppealAuditControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void shouldApproveMerchantReviewAppealAndHidePublicReview() throws Exception {
        String merchantToken = merchantToken();
        long appealId = submitAppeal(merchantToken, "点评内容包含与实际消费无关的人身攻击，请平台复核。");
        long taskId = pendingAppealTask(appealId);

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", taskId)
                        .header("Authorization", bearer(adminToken()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"remark\":\"申诉成立\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.bizType").value(6))
                .andExpect(jsonPath("$.data.status").value(1));

        mockMvc.perform(get("/api/c/v1/reviews/3")
                        .header("X-Region", "EU"))
                .andExpect(status().isNotFound());

        assertEquals(2, jdbc.queryForObject(
                "SELECT status FROM merchant_review_appeal WHERE id=?",
                Integer.class,
                appealId
        ));
        assertEquals(2, jdbc.queryForObject(
                "SELECT audit_status FROM review WHERE id=3",
                Integer.class
        ));
        assertEquals(0, jdbc.queryForObject(
                "SELECT review_count FROM shop WHERE id=20001",
                Integer.class
        ));
    }

    @Test
    void shouldRejectMerchantReviewAppealAndAllowResubmit() throws Exception {
        String merchantToken = merchantToken();
        long appealId = submitAppeal(merchantToken, "点评内容包含与实际消费无关的人身攻击，请平台复核。");
        long taskId = pendingAppealTask(appealId);

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/reject", taskId)
                        .header("Authorization", bearer(adminToken()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reason\":\"证据不足\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.bizType").value(6))
                .andExpect(jsonPath("$.data.status").value(2));

        mockMvc.perform(get("/api/c/v1/reviews/3")
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());

        assertEquals(3, jdbc.queryForObject(
                "SELECT status FROM merchant_review_appeal WHERE id=?",
                Integer.class,
                appealId
        ));

        mockMvc.perform(put("/api/b/v1/review-appeals/{appealId}", appealId)
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "reason": "补充门店小票和监控记录，请重新复核这条点评。",
                                  "evidenceUrls": ["https://files.example/receipt.jpg"]
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(0));

        mockMvc.perform(post("/api/b/v1/review-appeals/{appealId}/submit", appealId)
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1));

        assertEquals(1, jdbc.queryForObject(
                "SELECT COUNT(1) FROM audit_task WHERE biz_type=6 AND biz_id=? AND status=0",
                Integer.class,
                appealId
        ));
    }

    @Test
    void shouldInvalidatePendingMerchantAppealWhenReviewIsEdited() throws Exception {
        String userToken = registerUser();
        long reviewId = createEuReview(userToken, "申诉前的公开点评正文，先让后台审核通过。");
        passReviewAudit(reviewId);
        String merchantToken = merchantToken();
        long appealId = submitAppeal(merchantToken, reviewId, "旧正文包含与实际消费无关的人身攻击，请平台复核。");
        long taskId = pendingAppealTask(appealId);

        mockMvc.perform(put("/api/c/v1/reviews/{reviewId}", reviewId)
                        .header("Authorization", bearer(userToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(euReviewPayload("用户已经改了正文，旧申诉不能继续审核。")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.auditStatus").value(0));

        assertEquals(4, jdbc.queryForObject(
                "SELECT status FROM merchant_review_appeal WHERE id=?",
                Integer.class,
                appealId
        ));
        assertEquals(2, jdbc.queryForObject(
                "SELECT status FROM audit_task WHERE id=?",
                Integer.class,
                taskId
        ));
    }

    @Test
    void shouldInvalidatePendingMerchantAppealWhenReviewIsDeleted() throws Exception {
        String userToken = registerUser();
        long reviewId = createEuReview(userToken, "删除前的公开点评正文，也不能让旧申诉继续审核。");
        passReviewAudit(reviewId);
        String merchantToken = merchantToken();
        long appealId = submitAppeal(merchantToken, reviewId, "这条点评准备删除，旧申诉必须跟着失效。");
        long taskId = pendingAppealTask(appealId);

        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete("/api/c/v1/reviews/{reviewId}", reviewId)
                        .header("Authorization", bearer(userToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());

        assertEquals(4, jdbc.queryForObject(
                "SELECT status FROM merchant_review_appeal WHERE id=?",
                Integer.class,
                appealId
        ));
        assertEquals(2, jdbc.queryForObject(
                "SELECT status FROM audit_task WHERE id=?",
                Integer.class,
                taskId
        ));
    }

    private long submitAppeal(String merchantToken, String reason) throws Exception {
        return submitAppeal(merchantToken, 3L, reason);
    }

    private long submitAppeal(String merchantToken, long reviewId, String reason) throws Exception {
        MvcResult draft = mockMvc.perform(post("/api/b/v1/reviews/{reviewId}/appeal-drafts", reviewId)
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andReturn();
        long appealId = objectMapper.readTree(draft.getResponse().getContentAsString()).at("/data/id").asLong();
        mockMvc.perform(put("/api/b/v1/review-appeals/{appealId}", appealId)
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "reason": "%s",
                                  "evidenceUrls": ["https://files.example/order-proof.jpg"]
                                }
                                """.formatted(reason)))
                .andExpect(status().isOk());
        mockMvc.perform(post("/api/b/v1/review-appeals/{appealId}/submit", appealId)
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());
        return appealId;
    }

    private String registerUser() throws Exception {
        String account = "appeal-user-" + UUID.randomUUID() + "@example.com";
        String deviceId = "device-" + UUID.randomUUID();
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .with(request -> {
                            request.setRemoteAddr("10.77." + Math.floorMod(account.hashCode(), 200) + ".9");
                            return request;
                        })
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "scene": "register",
                                  "type": "email",
                                  "account": "%s",
                                  "deviceId": "%s"
                                }
                                """.formatted(account, deviceId)))
                .andExpect(status().isOk());
        MvcResult result = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "%s",
                                  "code": "123456",
                                  "password": "Passw0rd!",
                                  "nickname": "申诉协作用例",
                                  "preferredRegion": "EU"
                                }
                                """.formatted(account)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private long createEuReview(String userToken, String content) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/c/v1/reviews")
                        .header("Authorization", bearer(userToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(euReviewPayload(content)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/id").asLong();
    }

    private void passReviewAudit(long reviewId) throws Exception {
        Long taskId = jdbc.queryForObject(
                "SELECT id FROM audit_task WHERE biz_type=3 AND biz_id=? AND status=0",
                Long.class,
                reviewId
        );
        mockMvc.perform(post("/api/admin/v1/audit/tasks/{taskId}/pass", taskId)
                        .header("Authorization", bearer(adminToken()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"remark\":\"内容可公开\"}"))
                .andExpect(status().isOk());
    }

    private String euReviewPayload(String content) {
        return """
                {
                  "shopId": 20001,
                  "content": "%s",
                  "scoreOverall": 4,
                  "scoreTaste": 4,
                  "scoreEnv": 4,
                  "scoreService": 4,
                  "cost": 36.00,
                  "currency": "EUR",
                  "tags": ["Chinese", "Spicy"],
                  "images": ["https://files.example/review-proof.jpg"]
                }
                """.formatted(content);
    }

    private long pendingAppealTask(long appealId) {
        return jdbc.queryForObject(
                "SELECT id FROM audit_task WHERE biz_type=6 AND biz_id=? AND status=0",
                Long.class,
                appealId
        );
    }

    private String merchantToken() throws Exception {
        return loginMerchant("merchant_eu_sichuan@example.com", "merchant123456");
    }

    private String loginMerchant(String account, String password) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/b/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"" + account + "\",\"password\":\"" + password + "\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String adminToken() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
