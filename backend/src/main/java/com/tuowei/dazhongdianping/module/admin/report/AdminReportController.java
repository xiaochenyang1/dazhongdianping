package com.tuowei.dazhongdianping.module.admin.report;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.admin.report.model.request.AdminReportResolveRequest;
import com.tuowei.dazhongdianping.module.admin.report.model.response.AdminReportResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1/audit/reports")
public class AdminReportController {

    private final AdminReportService service;

    public AdminReportController(AdminReportService service) {
        this.service = service;
    }

    @GetMapping
    @AdminPermission("audit:report:read")
    public ApiResponse<PageResult<AdminReportResponse>> list(
            @RequestParam(required = false) String reportType,
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "20") Integer pageSize
    ) {
        return ApiResponse.success(service.list(reportType, status, keyword, page, pageSize));
    }

    @PostMapping("/{reportType}/{id}/resolve")
    @AdminPermission("audit:report:write")
    public ApiResponse<AdminReportResponse> resolve(
            @PathVariable String reportType,
            @PathVariable Long id,
            @Valid @RequestBody AdminReportResolveRequest request,
            HttpServletRequest httpServletRequest
    ) {
        return ApiResponse.success(service.resolve(reportType, id, request, httpServletRequest.getRemoteAddr()));
    }
}
