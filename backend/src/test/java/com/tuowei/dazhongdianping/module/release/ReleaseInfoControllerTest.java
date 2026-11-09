package com.tuowei.dazhongdianping.module.release;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.tuowei.dazhongdianping.module.release.model.response.ReleaseInfoResponse;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class ReleaseInfoControllerTest {

    @Test
    void shouldReturnOnlyNonSecretReleaseIdentityWithoutCaching() throws Exception {
        ReleaseInfoService service = mock(ReleaseInfoService.class);
        when(service.inspect()).thenReturn(new ReleaseInfoResponse(
                "eu-pre-rc-31", "b".repeat(40), "pre", "EU", 31, "pre", "2026-11-09T12:00:00Z"));
        MockMvc mvc = MockMvcBuilders.standaloneSetup(new ReleaseInfoController(service)).build();

        mvc.perform(get("/api/c/v1/release-info"))
                .andExpect(status().isOk())
                .andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(jsonPath("$.data.version").value("eu-pre-rc-31"))
                .andExpect(jsonPath("$.data.commitSha").value("b".repeat(40)))
                .andExpect(jsonPath("$.data.buildEnvironment").value("pre"))
                .andExpect(jsonPath("$.data.buildRegion").value("EU"))
                .andExpect(jsonPath("$.data.migrationVersion").value(31))
                .andExpect(jsonPath("$.data.runtimeMode").value("pre"));
    }
}
