package com.tuowei.dazhongdianping.module.merchant.controller;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
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
class MerchantDashboardControllerTest {

    @Autowired
    MockMvc mockMvc;

    @Autowired
    ObjectMapper objectMapper;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void shouldAggregateRealViewsOrdersCouponsReservationsAndRating() throws Exception {
        String today = LocalDate.now().toString();
        mockMvc.perform(get("/api/c/v1/shops/20001").header("X-Region", "EU"))
                .andExpect(status().isOk());
        mockMvc.perform(get("/api/c/v1/shops/20001").header("X-Region", "EU"))
                .andExpect(status().isOk());

        String orderNo = "DASH" + UUID.randomUUID().toString().replace("-", "").substring(0, 20);
        jdbc.update("INSERT INTO `order`(order_no,user_id,deal_id,shop_id,region,quantity,unit_price,amount,currency,pay_status,status,paid_at) "
                + "VALUES(?,9001,41001,20001,'EU',1,32.00,32.00,'EUR',1,1,CURRENT_TIMESTAMP)", orderNo);
        Long orderId = jdbc.queryForObject("SELECT id FROM `order` WHERE order_no=?", Long.class, orderNo);
        jdbc.update("INSERT INTO coupon(order_id,user_id,deal_id,shop_id,code,status,verify_at,verify_by,expire_at) "
                + "VALUES(?,9001,41001,20001,?,2,CURRENT_TIMESTAMP,12001,'2026-12-31')",
                orderId, "DASH" + UUID.randomUUID().toString().replace("-", "").substring(0, 12));
        jdbc.update("INSERT INTO reservation(reservation_no,user_id,shop_id,slot_id,region,reserve_time,people_count,contact_name,contact_phone,remark,status) "
                + "VALUES(?,9001,20001,0,'EU',CURRENT_TIMESTAMP,2,'Lina','+33123456789','',0)",
                "DASHRS" + UUID.randomUUID().toString().replace("-", "").substring(0, 16));

        mockMvc.perform(get("/api/b/v1/dashboard")
                        .header("Authorization", bearer(merchantToken()))
                        .header("X-Region", "EU")
                        .param("shopId", "20001")
                        .param("dateFrom", today)
                        .param("dateTo", today))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.views").value(2))
                .andExpect(jsonPath("$.data.paidOrders").value(1))
                .andExpect(jsonPath("$.data.paidAmount").value(32.0))
                .andExpect(jsonPath("$.data.verifiedCoupons").value(1))
                .andExpect(jsonPath("$.data.reservations.total").value(1))
                .andExpect(jsonPath("$.data.reservations.pending").value(1))
                .andExpect(jsonPath("$.data.rating.score").value(4.6))
                .andExpect(jsonPath("$.data.trend[0].views").value(2));
    }

    private String merchantToken() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/b/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"merchant_eu_sichuan@example.com\",\"password\":\"merchant123456\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }
}
