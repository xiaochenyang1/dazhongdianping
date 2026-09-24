package com.tuowei.dazhongdianping.module.moderation.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.moderation.model.AutomodHitQuery;
import com.tuowei.dazhongdianping.module.moderation.service.ContentModerationService;
import jakarta.validation.Valid;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1/automod/hits")
public class AdminAutomodController {

    private final ContentModerationService service;

    public AdminAutomodController(ContentModerationService service) {
        this.service = service;
    }

    @GetMapping
    @AdminPermission("audit:automod:read")
    public ApiResponse<PageResult<Map<String, Object>>> hits(@Valid AutomodHitQuery query) {
        return ApiResponse.success(service.listHits(query));
    }
}
