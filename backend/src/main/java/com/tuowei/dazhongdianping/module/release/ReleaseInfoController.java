package com.tuowei.dazhongdianping.module.release;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.release.model.response.ReleaseInfoResponse;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ReleaseInfoController {

    private final ReleaseInfoService releaseInfoService;

    public ReleaseInfoController(ReleaseInfoService releaseInfoService) {
        this.releaseInfoService = releaseInfoService;
    }

    @GetMapping("/api/c/v1/release-info")
    public ResponseEntity<ApiResponse<ReleaseInfoResponse>> inspect() {
        return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .body(ApiResponse.success(releaseInfoService.inspect()));
    }
}
