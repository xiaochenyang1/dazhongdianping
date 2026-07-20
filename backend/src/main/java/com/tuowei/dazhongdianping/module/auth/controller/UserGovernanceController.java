package com.tuowei.dazhongdianping.module.auth.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.auth.model.request.PolicyAcceptRequest;
import com.tuowei.dazhongdianping.module.auth.model.request.UserDevicePushTokenUpdateRequest;
import com.tuowei.dazhongdianping.module.auth.model.request.UserDeviceRegisterRequest;
import com.tuowei.dazhongdianping.module.auth.model.response.PolicyAcceptLogResponse;
import com.tuowei.dazhongdianping.module.auth.model.response.UserDeviceResponse;
import com.tuowei.dazhongdianping.module.auth.service.UserGovernanceService;
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
@RequestMapping("/api/c/v1")
public class UserGovernanceController {
    private final UserGovernanceService userGovernanceService;

    public UserGovernanceController(UserGovernanceService userGovernanceService) {
        this.userGovernanceService = userGovernanceService;
    }

    @PostMapping("/privacy/policies/accept")
    public ApiResponse<PolicyAcceptLogResponse> acceptPolicy(@Valid @RequestBody PolicyAcceptRequest request,
                                                             HttpServletRequest httpRequest) {
        return ApiResponse.success(userGovernanceService.acceptPolicy(
                request,
                httpRequest.getRemoteAddr(),
                httpRequest.getHeader("User-Agent")
        ));
    }

    @GetMapping("/privacy/policies")
    public ApiResponse<List<PolicyAcceptLogResponse>> listPolicies() {
        return ApiResponse.success(userGovernanceService.listPolicyAcceptLogs());
    }

    @PostMapping("/devices/register")
    public ApiResponse<UserDeviceResponse> registerDevice(@Valid @RequestBody UserDeviceRegisterRequest request) {
        return ApiResponse.success(userGovernanceService.registerDevice(request));
    }

    @GetMapping("/devices")
    public ApiResponse<List<UserDeviceResponse>> listDevices() {
        return ApiResponse.success(userGovernanceService.listDevices());
    }

    @PutMapping("/devices/{deviceId}/push-token")
    public ApiResponse<UserDeviceResponse> updatePushToken(@PathVariable Long deviceId,
                                                            @Valid @RequestBody UserDevicePushTokenUpdateRequest request) {
        return ApiResponse.success(userGovernanceService.updatePushToken(deviceId, request));
    }

    @DeleteMapping("/devices/{deviceId}")
    public ApiResponse<UserDeviceResponse> logoutDevice(@PathVariable Long deviceId) {
        return ApiResponse.success(userGovernanceService.logoutDevice(deviceId));
    }
}
