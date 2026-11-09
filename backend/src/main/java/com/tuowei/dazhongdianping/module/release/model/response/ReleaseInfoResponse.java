package com.tuowei.dazhongdianping.module.release.model.response;

public record ReleaseInfoResponse(
        String version,
        String commitSha,
        String buildEnvironment,
        String buildRegion,
        int migrationVersion,
        String runtimeMode,
        String builtAtUtc
) {
}
