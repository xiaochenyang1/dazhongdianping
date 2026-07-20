package com.tuowei.dazhongdianping.module.admin.circle;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.admin.circle.model.CircleSaveRequest;
import com.tuowei.dazhongdianping.module.admin.circle.model.CircleStatusRequest;
import com.tuowei.dazhongdianping.module.circle.model.response.CircleResponse;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/v1/circles")
public class AdminCircleController {
    private final AdminCircleService service;
    public AdminCircleController(AdminCircleService service){this.service=service;}
    @GetMapping @AdminPermission("operations:circle:read") public ApiResponse<PageResult<CircleResponse>> list(@RequestParam(required=false) Integer status,@RequestParam(required=false) String keyword,@RequestParam(defaultValue="1") Integer page,@RequestParam(defaultValue="20") Integer pageSize){return ApiResponse.success(service.list(status,keyword,page,pageSize));}
    @PostMapping @AdminPermission("operations:circle:write") public ApiResponse<CircleResponse> create(@Valid @RequestBody CircleSaveRequest request){return ApiResponse.success(service.create(request));}
    @PutMapping("/{id}") @AdminPermission("operations:circle:write") public ApiResponse<CircleResponse> update(@PathVariable Long id,@Valid @RequestBody CircleSaveRequest request){return ApiResponse.success(service.update(id,request));}
    @PutMapping("/{id}/status") @AdminPermission("operations:circle:write") public ApiResponse<CircleResponse> status(@PathVariable Long id,@Valid @RequestBody CircleStatusRequest request){return ApiResponse.success(service.status(id,request.status()));}
}
