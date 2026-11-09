package com.tuowei.dazhongdianping.module.release;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.module.release.model.response.ReleaseInfoResponse;
import java.util.Properties;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.boot.info.BuildProperties;

class ReleaseInfoServiceTest {

    @Test
    void shouldExposeNormalizedBuildAndRuntimeIdentity() {
        Properties entries = new Properties();
        entries.setProperty("releaseVersion", " eu-pre-rc-31 ");
        entries.setProperty("commitSha", "a".repeat(40));
        entries.setProperty("environment", " PRE ");
        entries.setProperty("region", " eu ");
        entries.setProperty("migrationVersion", "31");
        entries.setProperty("time", "2026-11-09T12:00:00Z");
        BuildProperties buildProperties = new BuildProperties(entries);
        ReleaseInfoService service = new ReleaseInfoService(provider(buildProperties), " PRE ");

        ReleaseInfoResponse response = service.inspect();

        assertThat(response.version()).isEqualTo("eu-pre-rc-31");
        assertThat(response.commitSha()).isEqualTo("a".repeat(40));
        assertThat(response.buildEnvironment()).isEqualTo("pre");
        assertThat(response.buildRegion()).isEqualTo("EU");
        assertThat(response.migrationVersion()).isEqualTo(31);
        assertThat(response.runtimeMode()).isEqualTo("pre");
        assertThat(response.builtAtUtc()).isEqualTo("2026-11-09T12:00:00Z");
    }

    @Test
    void shouldUseSafeDevelopmentDefaultsWithoutBuildInfo() {
        ReleaseInfoResponse response = new ReleaseInfoService(provider(null), " ").inspect();

        assertThat(response.version()).isEqualTo("development");
        assertThat(response.commitSha()).isEqualTo("unknown");
        assertThat(response.buildEnvironment()).isEqualTo("local");
        assertThat(response.buildRegion()).isEqualTo("EU");
        assertThat(response.migrationVersion()).isZero();
        assertThat(response.runtimeMode()).isEqualTo("prod");
        assertThat(response.builtAtUtc()).isEmpty();
    }

    @SuppressWarnings("unchecked")
    private <T> ObjectProvider<T> provider(T value) {
        ObjectProvider<T> provider = mock(ObjectProvider.class);
        when(provider.getIfAvailable()).thenReturn(value);
        return provider;
    }
}
