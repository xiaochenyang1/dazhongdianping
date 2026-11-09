package com.tuowei.dazhongdianping.module.release;

import com.tuowei.dazhongdianping.module.release.model.response.ReleaseInfoResponse;
import java.time.Instant;
import java.util.Locale;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.info.BuildProperties;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
public class ReleaseInfoService {

    private final ObjectProvider<BuildProperties> buildPropertiesProvider;
    private final String runtimeMode;

    public ReleaseInfoService(
            ObjectProvider<BuildProperties> buildPropertiesProvider,
            @Value("${app.runtime-mode:prod}") String runtimeMode) {
        this.buildPropertiesProvider = buildPropertiesProvider;
        this.runtimeMode = normalize(runtimeMode, "prod").toLowerCase(Locale.ROOT);
    }

    public ReleaseInfoResponse inspect() {
        BuildProperties build = buildPropertiesProvider.getIfAvailable();
        return new ReleaseInfoResponse(
                property(build, "releaseVersion", "development"),
                property(build, "commitSha", "unknown"),
                property(build, "environment", "local").toLowerCase(Locale.ROOT),
                property(build, "region", "EU").toUpperCase(Locale.ROOT),
                integerProperty(build, "migrationVersion"),
                runtimeMode,
                buildTime(build)
        );
    }

    private String property(BuildProperties build, String name, String fallback) {
        return normalize(build == null ? null : build.get(name), fallback);
    }

    private int integerProperty(BuildProperties build, String name) {
        String value = property(build, name, "0");
        try {
            return Math.max(0, Integer.parseInt(value));
        } catch (NumberFormatException ignored) {
            return 0;
        }
    }

    private String buildTime(BuildProperties build) {
        Instant time = build == null ? null : build.getTime();
        return time == null ? "" : time.toString();
    }

    private String normalize(String value, String fallback) {
        return StringUtils.hasText(value) ? value.trim() : fallback;
    }
}
