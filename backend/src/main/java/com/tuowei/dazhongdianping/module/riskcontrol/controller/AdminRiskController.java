package com.tuowei.dazhongdianping.module.riskcontrol.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.riskcontrol.model.request.RiskEventDisposeRequest;
import com.tuowei.dazhongdianping.module.riskcontrol.model.request.RiskRuleUpdateRequest;
import com.tuowei.dazhongdianping.module.riskcontrol.model.response.RiskEventResponse;
import com.tuowei.dazhongdianping.module.riskcontrol.model.response.RiskRuleResponse;
import com.tuowei.dazhongdianping.module.riskcontrol.service.AdminRiskService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1/risk")
public class AdminRiskController {

    private final AdminRiskService service;

    public AdminRiskController(AdminRiskService service) {
        this.service = service;
    }

    @GetMapping("/events")
    @AdminPermission("risk:event:read")
    public ApiResponse<PageResult<RiskEventResponse>> listEvents(
            @RequestParam(required = false) String scene,
            @RequestParam(required = false) Integer decision,
            @RequestParam(required = false) Integer disposeStatus,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize) {
        return ApiResponse.success(service.listEvents(scene, decision, disposeStatus, page, pageSize));
    }

    @PostMapping("/events/{id}/dispose")
    @AdminPermission("risk:event:write")
    public ApiResponse<RiskEventResponse> disposeEvent(
            @PathVariable Long id,
            @Valid @RequestBody RiskEventDisposeRequest request) {
        return ApiResponse.success("处置成功", "admin.risk_event_disposed", service.disposeEvent(id, request));
    }

    @GetMapping("/rules")
    @AdminPermission("risk:event:read")
    public ApiResponse<List<RiskRuleResponse>> listRules() {
        return ApiResponse.success(service.listRules());
    }

    @PutMapping("/rules/{id}")
    @AdminPermission("risk:event:write")
    public ApiResponse<RiskRuleResponse> updateRule(
            @PathVariable Long id,
            @Valid @RequestBody RiskRuleUpdateRequest request) {
        return ApiResponse.success("保存成功", "admin.risk_rule_saved", service.updateRule(id, request));
    }
}
