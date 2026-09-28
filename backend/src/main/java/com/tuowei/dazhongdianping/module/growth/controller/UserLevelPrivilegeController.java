package com.tuowei.dazhongdianping.module.growth.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.growth.service.UserLevelPrivilegeService;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/c/v1/user/level-privileges")
public class UserLevelPrivilegeController {

    private final UserLevelPrivilegeService service;

    public UserLevelPrivilegeController(UserLevelPrivilegeService service) {
        this.service = service;
    }

    @GetMapping
    public ApiResponse<Map<String, Object>> current() {
        return ApiResponse.success(service.current());
    }
}
