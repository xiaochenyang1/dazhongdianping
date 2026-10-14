package com.tuowei.dazhongdianping.module.launch;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class LaunchController {
    private final LaunchPolicy policy;

    public LaunchController(LaunchPolicy policy) {
        this.policy = policy;
    }

    @GetMapping("/api/c/v1/launch-config")
    public ResponseEntity<ApiResponse<LaunchPolicy.Capabilities>> capabilities() {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).varyBy("X-Region")
                .body(ApiResponse.success(policy.capabilities(RegionContext.getRegion())));
    }
}
