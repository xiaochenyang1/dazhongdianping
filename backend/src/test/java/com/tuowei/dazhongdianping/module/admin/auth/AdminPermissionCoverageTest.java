package com.tuowei.dazhongdianping.module.admin.auth;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.lang.annotation.Annotation;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.mvc.method.RequestMappingInfo;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping;

@SpringBootTest
class AdminPermissionCoverageTest {

    private static final Set<String> ALLOWLIST = Set.of(
            "/api/admin/v1/auth/login",
            "/api/admin/v1/auth/logout",
            "/api/admin/v1/auth/me",
            "/api/admin/v1/menus"
    );

    @Autowired
    @Qualifier("requestMappingHandlerMapping")
    private RequestMappingHandlerMapping handlerMapping;

    @Test
    void shouldRequirePermissionMetadataOnEveryAdminBusinessEndpoint() throws Exception {
        Class<?> annotationType = Class.forName(
                "com.tuowei.dazhongdianping.module.admin.auth.AdminPermission"
        );
        assertTrue(Annotation.class.isAssignableFrom(annotationType));

        handlerMapping.getHandlerMethods().forEach((mapping, handler) ->
                assertCovered(mapping, handler, annotationType.asSubclass(Annotation.class))
        );
    }

    private void assertCovered(RequestMappingInfo mapping,
                               HandlerMethod handler,
                               Class<? extends Annotation> annotationType) {
        var patterns = mapping.getPathPatternsCondition();
        if (patterns == null) {
            return;
        }
        for (String path : patterns.getPatternValues()) {
            if (!path.startsWith("/api/admin/v1") || ALLOWLIST.contains(path)) {
                continue;
            }
            Annotation annotation = handler.getMethodAnnotation(annotationType);
            if (annotation == null) {
                annotation = handler.getBeanType().getAnnotation(annotationType);
            }
            assertNotNull(annotation, () -> handler + " 缺少 AdminPermission: " + path);
        }
    }
}
