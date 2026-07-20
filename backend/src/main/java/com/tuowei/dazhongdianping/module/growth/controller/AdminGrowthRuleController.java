package com.tuowei.dazhongdianping.module.growth.controller;
import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.auth.model.GrowthRuleRow;
import com.tuowei.dazhongdianping.module.growth.model.request.GrowthRuleSaveRequest;
import com.tuowei.dazhongdianping.module.growth.model.request.LevelConfigSaveRequest;
import com.tuowei.dazhongdianping.module.growth.model.LevelConfigRow;
import com.tuowei.dazhongdianping.module.growth.model.response.GrowthConfigResponse;
import com.tuowei.dazhongdianping.module.growth.service.GrowthConfigService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;
@RestController @RequestMapping("/api/admin/v1/growth/rules") public class AdminGrowthRuleController {
 private final GrowthConfigService service; public AdminGrowthRuleController(GrowthConfigService service){this.service=service;}
 @GetMapping @AdminPermission("operations:growth:read") public ApiResponse<GrowthConfigResponse> list(){return ApiResponse.success(service.list());}
 @PostMapping @AdminPermission("operations:growth:write") public ApiResponse<GrowthRuleRow> create(@Valid @RequestBody GrowthRuleSaveRequest request){return ApiResponse.success(service.create(request));}
 @PutMapping("/{id}") @AdminPermission("operations:growth:write") public ApiResponse<GrowthRuleRow> update(@PathVariable Long id,@Valid @RequestBody GrowthRuleSaveRequest request){return ApiResponse.success(service.update(id,request));}
 @PutMapping("/levels/{level}") @AdminPermission("operations:growth:write") public ApiResponse<LevelConfigRow> updateLevel(@PathVariable Integer level,@Valid @RequestBody LevelConfigSaveRequest request){return ApiResponse.success(service.updateLevel(level,request));}
}
