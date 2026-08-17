package com.tuowei.dazhongdianping.common.trace;

import static org.assertj.core.api.Assertions.assertThat;

import jakarta.servlet.FilterChain;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class TraceIdFilterTest {

    private final TraceIdFilter filter = new TraceIdFilter();

    @Test
    void shouldPreserveSafeTraceIdAndExposeItToTheChain() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/health");
        request.addHeader(TraceIdFilter.TRACE_ID_HEADER, "client.trace-01");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilter(request, response, (servletRequest, servletResponse) -> {
            assertThat(TraceIdContext.getTraceId()).isEqualTo("client.trace-01");
        });

        assertThat(response.getHeader(TraceIdFilter.TRACE_ID_HEADER)).isEqualTo("client.trace-01");
        assertThat(TraceIdContext.getTraceId()).isNull();
    }

    @Test
    void shouldReplaceUnsafeTraceIdsBeforeWritingResponseOrMdc() throws Exception {
        for (String unsafeTraceId : new String[]{"bad value", "bad\nvalue", "x".repeat(65), "trace/with/slash"}) {
            MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/health");
            request.addHeader(TraceIdFilter.TRACE_ID_HEADER, unsafeTraceId);
            MockHttpServletResponse response = new MockHttpServletResponse();

            filter.doFilter(request, response, (servletRequest, servletResponse) -> {
                String generated = TraceIdContext.getTraceId();
                assertThat(generated).matches("[A-Za-z0-9._-]{1,64}");
                assertThat(generated).isNotEqualTo(unsafeTraceId);
            });

            assertThat(response.getHeader(TraceIdFilter.TRACE_ID_HEADER))
                    .matches("[A-Za-z0-9._-]{1,64}")
                    .isNotEqualTo(unsafeTraceId);
            assertThat(TraceIdContext.getTraceId()).isNull();
        }
    }
}
