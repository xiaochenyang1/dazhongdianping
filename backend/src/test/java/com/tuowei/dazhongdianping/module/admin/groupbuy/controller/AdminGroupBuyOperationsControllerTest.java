package com.tuowei.dazhongdianping.module.admin.groupbuy.controller;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.groupbuy.model.request.AdminGroupBuyRefundDispositionRequest;
import com.tuowei.dazhongdianping.module.admin.groupbuy.model.response.AdminGroupBuyFailedRefundResponse;
import com.tuowei.dazhongdianping.module.admin.groupbuy.model.response.AdminGroupBuyRefundDispositionResponse;
import com.tuowei.dazhongdianping.module.admin.groupbuy.service.AdminGroupBuyOperationsService;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class AdminGroupBuyOperationsControllerTest {

    private AdminGroupBuyOperationsService service;
    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        service = mock(AdminGroupBuyOperationsService.class);
        mockMvc = MockMvcBuilders.standaloneSetup(new AdminGroupBuyOperationsController(service)).build();
    }

    @Test
    void listsTerminalRefundFailuresWithPagination() throws Exception {
        when(service.failedRefunds(2, 10)).thenReturn(new PageResult<>(
                List.of(refund()), 11, 2, 10, false));

        mockMvc.perform(get("/api/admin/v1/groupbuy/operations/refunds/failed")
                        .param("page", "2")
                        .param("pageSize", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(11))
                .andExpect(jsonPath("$.data.list[0].refundId").value(9501))
                .andExpect(jsonPath("$.data.list[0].channelFailureReason").value("provider_declined"));
    }

    @Test
    void acceptsManualDispositionContract() throws Exception {
        AdminGroupBuyRefundDispositionRequest request = new AdminGroupBuyRefundDispositionRequest(
                "provider_refunded", "provider-case-9501", "Verified in provider console");
        when(service.disposeRefund(org.mockito.ArgumentMatchers.eq(9501L),
                org.mockito.ArgumentMatchers.eq(request), anyString()))
                .thenReturn(new AdminGroupBuyRefundDispositionResponse(true, true, "provider_refunded", refund()));

        mockMvc.perform(post("/api/admin/v1/groupbuy/operations/refunds/9501/disposition")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "outcome": "provider_refunded",
                                  "providerReference": "provider-case-9501",
                                  "note": "Verified in provider console"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.processed").value(true))
                .andExpect(jsonPath("$.data.alertResolved").value(true))
                .andExpect(jsonPath("$.data.outcome").value("provider_refunded"));

        verify(service).disposeRefund(org.mockito.ArgumentMatchers.eq(9501L),
                org.mockito.ArgumentMatchers.eq(request), anyString());
    }

    private AdminGroupBuyFailedRefundResponse refund() {
        return new AdminGroupBuyFailedRefundResponse(
                9501, 9301, "OD-GROUP-9301", 81, "Two-person group buy", "Paris Bistro",
                new BigDecimal("12.80"), "EUR", "stripe", "re_failed_9501", "failed",
                "provider_declined", 4, 1L, "provider_not_refunded | ref=case-1 | no funds moved",
                LocalDateTime.of(2026, 11, 8, 15, 0), LocalDateTime.of(2026, 11, 8, 15, 0));
    }
}
