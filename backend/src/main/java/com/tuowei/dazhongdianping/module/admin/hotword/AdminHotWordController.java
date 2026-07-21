package com.tuowei.dazhongdianping.module.admin.hotword;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.admin.hotword.model.request.AdminHotWordSaveRequest;
import com.tuowei.dazhongdianping.module.admin.hotword.model.request.AdminHotWordStatusRequest;
import com.tuowei.dazhongdianping.module.admin.hotword.model.response.AdminHotWordResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1/search/hotwords")
public class AdminHotWordController {

    private final AdminHotWordService service;

    public AdminHotWordController(AdminHotWordService service) {
        this.service = service;
    }

    @GetMapping
    @AdminPermission("operations:hotword:read")
    public ApiResponse<List<AdminHotWordResponse>> list() {
        return ApiResponse.success(service.list());
    }

    @PostMapping
    @AdminPermission("operations:hotword:write")
    public ApiResponse<AdminHotWordResponse> create(@Valid @RequestBody AdminHotWordSaveRequest request,
                                                    HttpServletRequest httpServletRequest) {
        return ApiResponse.success(service.create(request, httpServletRequest.getRemoteAddr()));
    }

    @PutMapping("/{id}")
    @AdminPermission("operations:hotword:write")
    public ApiResponse<AdminHotWordResponse> update(@PathVariable Long id,
                                                    @Valid @RequestBody AdminHotWordSaveRequest request,
                                                    HttpServletRequest httpServletRequest) {
        return ApiResponse.success(service.update(id, request, httpServletRequest.getRemoteAddr()));
    }

    @PutMapping("/{id}/status")
    @AdminPermission("operations:hotword:write")
    public ApiResponse<AdminHotWordResponse> updateStatus(@PathVariable Long id,
                                                          @Valid @RequestBody AdminHotWordStatusRequest request,
                                                          HttpServletRequest httpServletRequest) {
        return ApiResponse.success(service.updateStatus(id, request.enabled(), httpServletRequest.getRemoteAddr()));
    }

    @DeleteMapping("/{id}")
    @AdminPermission("operations:hotword:write")
    public ApiResponse<Void> delete(@PathVariable Long id, HttpServletRequest httpServletRequest) {
        service.delete(id, httpServletRequest.getRemoteAddr());
        return ApiResponse.success("热词已删除", "admin.hotword_deleted", null);
    }
}
