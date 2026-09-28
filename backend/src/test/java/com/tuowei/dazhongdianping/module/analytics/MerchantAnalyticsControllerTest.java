package com.tuowei.dazhongdianping.module.analytics;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.math.BigDecimal;
import java.sql.Date;
import java.sql.Timestamp;
import java.time.LocalDate;
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
class MerchantAnalyticsControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbc;

    @Test
    void trendFillsEmptyDaysAndExportIsCsv() throws Exception {
        String merchant = loginMerchant();
        LocalDate today = LocalDate.now();
        jdbc.update("INSERT INTO shop_view_daily(shop_id,biz_date,view_count) VALUES(?,?,?)",
                10001, Date.valueOf(today), 5);
        String orderNo = ("AN" + UUID.randomUUID().toString().replace("-", "")).substring(0, 32);
        jdbc.update("INSERT INTO `order`(order_no,user_id,deal_id,shop_id,region,quantity,unit_price,amount,currency,pay_status,status,paid_at) "
                        + "VALUES(?,9001,40001,10001,'CN',1,88.00,88.00,'CNY',1,1,?)",
                orderNo, Timestamp.valueOf(today.atTime(12, 0)));

        MvcResult trend = mockMvc.perform(get("/api/b/v1/analytics/trend")
                        .param("shopId", "10001").param("days", "7")
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.days").value(7))
                .andExpect(jsonPath("$.data.list.length()").value(7))
                .andReturn();
        JsonNode list = objectMapper.readTree(trend.getResponse().getContentAsString()).at("/data/list");
        JsonNode todayRow = null;
        int zeros = 0;
        for (JsonNode row : list) {
            if (today.toString().equals(row.get("date").asText())) {
                todayRow = row;
            } else if (row.get("views").asInt() == 0 && row.get("orders").asInt() == 0) {
                zeros++;
            }
        }
        assertThat(todayRow).isNotNull();
        assertThat(todayRow.get("views").asLong()).isEqualTo(5);
        assertThat(todayRow.get("orders").asLong()).isEqualTo(1);
        assertThat(new BigDecimal(todayRow.get("amount").asText())).isEqualByComparingTo("88.00");
        assertThat(zeros).isEqualTo(6);

        MvcResult exported = mockMvc.perform(get("/api/b/v1/analytics/export")
                        .param("shopId", "10001").param("days", "7")
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andReturn();
        String csv = objectMapper.readTree(exported.getResponse().getContentAsString()).get("data").asText();
        assertThat(csv).startsWith("shopId,date,views,orders,amount");
        assertThat(csv).contains("10001," + today + ",5,1,88.00");

        mockMvc.perform(get("/api/b/v1/analytics/trend")
                        .param("shopId", "10001").param("days", "31")
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN"))
                .andExpect(status().isBadRequest());
        mockMvc.perform(get("/api/b/v1/analytics/trend")
                        .param("shopId", "20001").param("days", "7")
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN"))
                .andExpect(status().isNotFound());
    }

    @Test
    void adReportSumsClickLogAndCampaignSpend() throws Exception {
        String merchant = loginMerchant();
        mockMvc.perform(post("/api/c/v1/ads/{id}/click", 8001).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.charged").value(true));

        MvcResult report = mockMvc.perform(get("/api/b/v1/ads/report")
                        .param("shopId", "10001")
                        .header("Authorization", bearer(merchant)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode campaigns = objectMapper.readTree(report.getResponse().getContentAsString()).at("/data/campaigns");
        JsonNode campaign = null;
        for (JsonNode row : campaigns) {
            if (row.get("id").asLong() == 8001L) {
                campaign = row;
            }
        }
        assertThat(campaign).isNotNull();
        assertThat(campaign.get("clickCount").asLong()).isEqualTo(1);
        assertThat(new BigDecimal(campaign.get("clickCost").asText())).isEqualByComparingTo("2.50");
        assertThat(new BigDecimal(campaign.get("totalSpent").asText())).isEqualByComparingTo("2.50");
    }

    private String loginMerchant() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/b/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"merchant_cn_hotpot@example.com\",\"password\":\"merchant123456\"}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
