package com.tuowei.dazhongdianping.module.invoice;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.math.BigDecimal;
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
class InvoiceControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbc;

    @Test
    void requestInvoiceFromPaidOrderThenIssueOrReject() throws Exception {
        Registered user = register();
        long paid = insertOrder(user.userId(), 1, "88.00");
        long second = insertOrder(user.userId(), 1, "88.00");
        long unpaid = insertOrder(user.userId(), 0, "88.00");

        mockMvc.perform(post("/api/c/v1/invoices/titles")
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"titleType\":2,\"name\":\"示例公司\",\"email\":\"finance@example.com\",\"isDefault\":true}"))
                .andExpect(status().isBadRequest());

        MvcResult title = mockMvc.perform(post("/api/c/v1/invoices/titles")
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"titleType\":2,\"name\":\"示例公司\",\"taxNo\":\"91310000TEST\",\"email\":\"finance@example.com\",\"isDefault\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.titleType").value(2))
                .andExpect(jsonPath("$.data.isDefault").value(true))
                .andReturn();
        long titleId = objectMapper.readTree(title.getResponse().getContentAsString()).at("/data/id").asLong();

        mockMvc.perform(get("/api/c/v1/invoices/titles")
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id==" + titleId + ")].taxNo").value(org.hamcrest.Matchers.hasItem("91310000TEST")));

        mockMvc.perform(post("/api/c/v1/invoices")
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"orderId\":" + unpaid + ",\"titleId\":" + titleId + "}"))
                .andExpect(status().isBadRequest());

        MvcResult requested = mockMvc.perform(post("/api/c/v1/invoices")
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"orderId\":" + paid + ",\"titleId\":" + titleId + "}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.messageKey").value("invoice.requested"))
                .andExpect(jsonPath("$.data.status").value(1))
                .andExpect(jsonPath("$.data.currency").value("CNY"))
                .andReturn();
        JsonNode first = objectMapper.readTree(requested.getResponse().getContentAsString()).get("data");
        long firstId = first.get("id").asLong();
        assertThat(new BigDecimal(first.get("amount").asText())).isEqualByComparingTo("88.00");
        assertThat(new BigDecimal(first.get("taxAmount").asText())).isEqualByComparingTo("5.28");

        mockMvc.perform(post("/api/c/v1/invoices")
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"orderId\":" + paid + ",\"titleId\":" + titleId + "}"))
                .andExpect(status().isConflict());

        String admin = adminToken();
        mockMvc.perform(put("/api/admin/v1/tax-rates/{id}", 1)
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"餐饮服务增值税\",\"rateBp\":1000,\"status\":1}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.rateBp").value(1000));

        MvcResult secondRequest = mockMvc.perform(post("/api/c/v1/invoices")
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"orderId\":" + second + ",\"titleId\":" + titleId + "}"))
                .andExpect(status().isOk())
                .andReturn();
        JsonNode secondBody = objectMapper.readTree(secondRequest.getResponse().getContentAsString()).get("data");
        long secondId = secondBody.get("id").asLong();
        assertThat(new BigDecimal(secondBody.get("taxAmount").asText())).isEqualByComparingTo("8.80");

        mockMvc.perform(get("/api/c/v1/invoices")
                        .header("Authorization", bearer(user.token())).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(2));

        mockMvc.perform(post("/api/admin/v1/invoices/{id}/issue", firstId)
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"invoiceNo\":\"CN-INV-1001\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(2))
                .andExpect(jsonPath("$.data.invoiceNo").value("CN-INV-1001"));

        mockMvc.perform(post("/api/admin/v1/invoices/{id}/reject", secondId)
                        .header("Authorization", bearer(admin)).header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"reason\":\"抬头信息有误\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(3))
                .andExpect(jsonPath("$.data.rejectReason").value("抬头信息有误"));

        mockMvc.perform(get("/api/admin/v1/invoices")
                        .header("Authorization", bearer(admin)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[?(@.id==" + firstId + ")].status").value(org.hamcrest.Matchers.hasItem(2)));

        mockMvc.perform(get("/api/admin/v1/tax-rates").header("Authorization", bearer(admin)).header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[?(@.id==1)].rateBp").value(org.hamcrest.Matchers.hasItem(1000)));
    }

    private long insertOrder(long userId, int payStatus, String amount) {
        String orderNo = ("INV" + UUID.randomUUID().toString().replace("-", "")).substring(0, 32);
        jdbc.update("INSERT INTO `order`(order_no,user_id,deal_id,shop_id,region,quantity,unit_price,original_amount,discount_amount,amount,currency,pay_method,pay_status,status,paid_at) "
                        + "VALUES(?,?,40001,10001,'CN',1,?,?,0,?,'CNY','mock',?,1,CURRENT_TIMESTAMP)",
                orderNo, userId, new BigDecimal(amount), new BigDecimal(amount), new BigDecimal(amount), payStatus);
        return jdbc.queryForObject("SELECT id FROM `order` WHERE order_no=?", Long.class, orderNo);
    }

    private Registered register() throws Exception {
        String email = "inv-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\"" + email
                                + "\",\"deviceId\":\"invoice-test\"}"))
                .andExpect(status().isOk());
        MvcResult registered = mockMvc.perform(post("/api/c/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"type\":\"email\",\"account\":\"" + email
                                + "\",\"code\":\"123456\",\"password\":\"Passw0rd!\"}"))
                .andExpect(status().isOk()).andReturn();
        String token = objectMapper.readTree(registered.getResponse().getContentAsString()).at("/data/accessToken").asText();
        Long userId = jdbc.queryForObject("SELECT id FROM app_user WHERE email=?", Long.class, email);
        return new Registered(token, userId);
    }

    private String adminToken() throws Exception {
        MvcResult login = mockMvc.perform(post("/api/admin/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(login.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }

    private record Registered(String token, long userId) {
    }
}
