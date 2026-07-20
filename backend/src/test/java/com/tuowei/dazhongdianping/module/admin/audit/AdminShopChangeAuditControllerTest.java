package com.tuowei.dazhongdianping.module.admin.audit;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.math.BigDecimal;
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
class AdminShopChangeAuditControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void shouldPublishNewShopOnlyAfterAuditPasses() throws Exception {
        String merchantToken = merchantToken();
        MvcResult created = mockMvc.perform(post("/api/b/v1/shops/change-drafts")
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.changeType").value(1))
                .andReturn();
        long changeId = json(created).at("/data/id").asLong();

        mockMvc.perform(put("/api/b/v1/shop-changes/{id}", changeId)
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "categoryId": 201,
                                  "cityId": 101,
                                  "areaId": 1011,
                                  "name": "Draft Bistro",
                                  "coverUrl": "https://files.example/draft-bistro-cover.jpg",
                                  "phone": "+33111112222",
                                  "pricePerCapita": 39.00,
                                  "currency": "EUR",
                                  "address": "8 Rue du Test, Paris",
                                  "latitude": 48.8600,
                                  "longitude": 2.3500,
                                  "businessHours": "10:00-22:00",
                                  "summary": "审核通过后才公开的新门店",
                                  "openNow": true,
                                  "tags": ["Bistro", "Chinese"]
                                }
                                """))
                .andExpect(status().isOk());

        mockMvc.perform(put("/api/b/v1/shop-changes/{id}/photos", changeId)
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"photos":[
                                  {"imageUrl":"https://files.example/draft-bistro-cover.jpg","photoType":1,"sort":1},
                                  {"imageUrl":"https://files.example/draft-bistro-room.jpg","photoType":2,"sort":2}
                                ]}
                                """))
                .andExpect(status().isOk());

        mockMvc.perform(put("/api/b/v1/shop-changes/{id}/dishes", changeId)
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"dishes":[
                                  {"name":"招牌牛肉","price":24.00,"recommendReason":"每日现做","sort":1}
                                ]}
                                """))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/b/v1/shop-changes/{id}/submit", changeId)
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());

        mockMvc.perform(get("/api/c/v1/shops")
                        .header("X-Region", "EU")
                        .param("keyword", "Draft Bistro"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(0));

        Long taskId = jdbc.queryForObject(
                "SELECT id FROM audit_task WHERE biz_type=5 AND biz_id=? AND status=0",
                Long.class,
                changeId
        );
        assertNotNull(taskId);

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{id}/pass", taskId)
                        .header("Authorization", bearer(adminToken()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"remark\":\"资料完整\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.bizType").value(5));

        Long shopId = jdbc.queryForObject(
                "SELECT target_shop_id FROM merchant_shop_change WHERE id=?",
                Long.class,
                changeId
        );
        assertNotNull(shopId);
        assertEquals(1, jdbc.queryForObject(
                "SELECT COUNT(1) FROM shop WHERE id=? AND merchant_id=2001 AND name='Draft Bistro' AND region='EU'",
                Integer.class,
                shopId
        ));
        assertEquals(2, jdbc.queryForObject(
                "SELECT COUNT(1) FROM shop_photo WHERE shop_id=?",
                Integer.class,
                shopId
        ));
        assertEquals(1, jdbc.queryForObject(
                "SELECT COUNT(1) FROM dish WHERE shop_id=?",
                Integer.class,
                shopId
        ));

        mockMvc.perform(get("/api/c/v1/shops")
                        .header("X-Region", "EU")
                        .param("keyword", "Draft Bistro"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(shopId));
    }

    @Test
    void shouldReplaceExistingShopSnapshotAndPreserveAggregateFields() throws Exception {
        BigDecimal originalScore = jdbc.queryForObject(
                "SELECT score FROM shop WHERE id=20001", BigDecimal.class);
        Integer originalReviewCount = jdbc.queryForObject(
                "SELECT review_count FROM shop WHERE id=20001", Integer.class);
        Boolean originalHasDeal = jdbc.queryForObject(
                "SELECT has_deal FROM shop WHERE id=20001", Boolean.class);

        long changeId = submitExistingShopChange(
                "Maison Sichuan Renewed",
                "https://files.example/renewed-cover.jpg"
        );

        assertEquals("Maison Sichuan Paris", jdbc.queryForObject(
                "SELECT name FROM shop WHERE id=20001", String.class));
        assertEquals(1, jdbc.queryForObject(
                "SELECT COUNT(1) FROM shop_photo WHERE shop_id=20001", Integer.class));
        assertEquals(2, jdbc.queryForObject(
                "SELECT COUNT(1) FROM dish WHERE shop_id=20001", Integer.class));

        pass(taskId(changeId));

        assertEquals("Maison Sichuan Renewed", jdbc.queryForObject(
                "SELECT name FROM shop WHERE id=20001", String.class));
        assertEquals("https://files.example/renewed-cover.jpg", jdbc.queryForObject(
                "SELECT cover_url FROM shop WHERE id=20001", String.class));
        assertEquals(2, jdbc.queryForObject(
                "SELECT COUNT(1) FROM shop_photo WHERE shop_id=20001", Integer.class));
        assertEquals(1, jdbc.queryForObject(
                "SELECT COUNT(1) FROM dish WHERE shop_id=20001", Integer.class));
        assertEquals(originalScore, jdbc.queryForObject(
                "SELECT score FROM shop WHERE id=20001", BigDecimal.class));
        assertEquals(originalReviewCount, jdbc.queryForObject(
                "SELECT review_count FROM shop WHERE id=20001", Integer.class));
        assertEquals(originalHasDeal, jdbc.queryForObject(
                "SELECT has_deal FROM shop WHERE id=20001", Boolean.class));
    }

    @Test
    void shouldRejectWithoutChangingLiveShopAndAllowResubmission() throws Exception {
        long changeId = submitExistingShopChange(
                "Maison Sichuan Rejected",
                "https://files.example/rejected-cover.jpg"
        );
        long rejectedTaskId = taskId(changeId);

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{id}/reject", rejectedTaskId)
                        .header("Authorization", bearer(adminToken()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reason\":\"门店照片不清晰\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.bizType").value(5));

        assertEquals("Maison Sichuan Paris", jdbc.queryForObject(
                "SELECT name FROM shop WHERE id=20001", String.class));
        assertEquals(3, jdbc.queryForObject(
                "SELECT status FROM merchant_shop_change WHERE id=?", Integer.class, changeId));
        assertEquals("门店照片不清晰", jdbc.queryForObject(
                "SELECT reject_reason FROM merchant_shop_change WHERE id=?", String.class, changeId));

        String merchantToken = merchantToken();
        saveExistingShopFields(merchantToken, changeId,
                "Maison Sichuan Resubmitted", "https://files.example/rejected-cover.jpg");
        mockMvc.perform(post("/api/b/v1/shop-changes/{id}/submit", changeId)
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1));

        assertEquals(1, jdbc.queryForObject(
                "SELECT COUNT(1) FROM audit_task WHERE biz_type=5 AND biz_id=? AND status=0",
                Integer.class,
                changeId
        ));
        assertEquals(1, jdbc.queryForObject(
                "SELECT COUNT(1) FROM audit_task WHERE biz_type=5 AND biz_id=? AND status=2",
                Integer.class,
                changeId
        ));
    }

    @Test
    void shouldRejectApprovalWhenLiveShopVersionHasChanged() throws Exception {
        long changeId = submitExistingShopChange(
                "Maison Sichuan Stale Draft",
                "https://files.example/stale-cover.jpg"
        );
        long taskId = taskId(changeId);
        jdbc.update("UPDATE shop SET updated_at=DATEADD('SECOND', 1, updated_at) WHERE id=20001");

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{id}/pass", taskId)
                        .header("Authorization", bearer(adminToken()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"remark\":\"尝试覆盖旧版本\"}"))
                .andExpect(status().isBadRequest());

        assertEquals("Maison Sichuan Paris", jdbc.queryForObject(
                "SELECT name FROM shop WHERE id=20001", String.class));
        assertEquals(0, jdbc.queryForObject(
                "SELECT status FROM audit_task WHERE id=?", Integer.class, taskId));
        assertEquals(1, jdbc.queryForObject(
                "SELECT status FROM merchant_shop_change WHERE id=?", Integer.class, changeId));
    }

    @Test
    void shouldRejectDuplicateSubmissionAndDuplicateAudit() throws Exception {
        long changeId = submitExistingShopChange(
                "Maison Sichuan Once Only",
                "https://files.example/once-cover.jpg"
        );
        String merchantToken = merchantToken();

        mockMvc.perform(post("/api/b/v1/shop-changes/{id}/submit", changeId)
                        .header("Authorization", bearer(merchantToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isBadRequest());

        long taskId = taskId(changeId);
        pass(taskId);
        mockMvc.perform(post("/api/admin/v1/audit/tasks/{id}/pass", taskId)
                        .header("Authorization", bearer(adminToken()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"remark\":\"重复审核\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldRejectCrossRegionAuditWithoutClaimingTask() throws Exception {
        long changeId = submitExistingShopChange(
                "Maison Sichuan Wrong Region",
                "https://files.example/wrong-region-cover.jpg"
        );
        long taskId = taskId(changeId);

        mockMvc.perform(post("/api/admin/v1/audit/tasks/{id}/pass", taskId)
                        .header("Authorization", bearer(adminToken()))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"remark\":\"错误区域审核\"}"))
                .andExpect(status().isNotFound());

        assertEquals(0, jdbc.queryForObject(
                "SELECT status FROM audit_task WHERE id=?", Integer.class, taskId));
        assertEquals(1, jdbc.queryForObject(
                "SELECT status FROM merchant_shop_change WHERE id=?", Integer.class, changeId));
    }

    private long submitExistingShopChange(String name, String coverUrl) throws Exception {
        String token = merchantToken();
        MvcResult created = mockMvc.perform(post("/api/b/v1/shops/20001/change-drafts")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andReturn();
        long changeId = json(created).at("/data/id").asLong();
        saveExistingShopFields(token, changeId, name, coverUrl);

        mockMvc.perform(put("/api/b/v1/shop-changes/{id}/photos", changeId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"photos":[
                                  {"imageUrl":"%s","photoType":1,"sort":1},
                                  {"imageUrl":"https://files.example/renewed-room.jpg","photoType":2,"sort":2}
                                ]}
                                """.formatted(coverUrl)))
                .andExpect(status().isOk());

        mockMvc.perform(put("/api/b/v1/shop-changes/{id}/dishes", changeId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"dishes":[
                                  {"name":"新版水煮鱼","price":31.00,"recommendReason":"审核快照","sort":1}
                                ]}
                                """))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/b/v1/shop-changes/{id}/submit", changeId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());
        return changeId;
    }

    private void saveExistingShopFields(String token, long changeId, String name, String coverUrl) throws Exception {
        mockMvc.perform(put("/api/b/v1/shop-changes/{id}", changeId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "categoryId":201,"cityId":101,"areaId":1011,
                                  "name":"%s","coverUrl":"%s","phone":"+33142345678",
                                  "pricePerCapita":45.00,"currency":"EUR",
                                  "address":"20 Rue du Temple, Paris","latitude":48.8570,"longitude":2.3560,
                                  "businessHours":"11:00-23:00","summary":"修改门店完整快照",
                                  "openNow":true,"tags":["Chinese","Renewed"]
                                }
                                """.formatted(name, coverUrl)))
                .andExpect(status().isOk());
    }

    private long taskId(long changeId) {
        Long taskId = jdbc.queryForObject(
                "SELECT id FROM audit_task WHERE biz_type=5 AND biz_id=? AND status=0",
                Long.class,
                changeId
        );
        assertNotNull(taskId);
        return taskId;
    }

    private void pass(long taskId) throws Exception {
        mockMvc.perform(post("/api/admin/v1/audit/tasks/{id}/pass", taskId)
                        .header("Authorization", bearer(adminToken()))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"remark\":\"资料完整\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.bizType").value(5));
    }

    private String merchantToken() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/b/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"account":"merchant_eu_sichuan@example.com","password":"merchant123456"}
                                """))
                .andExpect(status().isOk())
                .andReturn();
        return json(result).at("/data/accessToken").asText();
    }

    private String adminToken() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return json(result).at("/data/accessToken").asText();
    }

    private JsonNode json(MvcResult result) throws Exception {
        return objectMapper.readTree(result.getResponse().getContentAsString());
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
