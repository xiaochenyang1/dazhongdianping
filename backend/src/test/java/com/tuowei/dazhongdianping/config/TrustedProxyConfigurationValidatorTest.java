package com.tuowei.dazhongdianping.config;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;

class TrustedProxyConfigurationValidatorTest {

    @Test
    void shouldAcceptExactIpv4AndIpv6AddressLists() {
        for (String regex : List.of(
                "^10[.]42[.]0[.]12$",
                "^(?:10[.]42[.]0[.]12|10[.]42[.]0[.]13)$",
                "^10\\.42\\.0\\.12$",
                "^(?:2001:db8::12|2001:db8::13)$")) {
            assertDoesNotThrow(() -> validator(regex).afterPropertiesSet(), regex);
        }
    }

    @Test
    void shouldRejectWildcardsRangesAndCidrPatterns() {
        for (String regex : List.of(
                "^.*$",
                "^10[.]42[.]0[.].+$",
                "^10[.]42[.]0[.]12[0-9]$",
                "^10[.]42[.]0[.]12/24$")) {
            IllegalStateException exception = assertThrows(
                    IllegalStateException.class,
                    () -> validator(regex).afterPropertiesSet(),
                    regex);
            assertTrue(exception.getMessage().contains("list of exact IPv4/IPv6 addresses"));
        }
    }

    @Test
    void shouldRejectMalformedIpLiterals() {
        for (String regex : List.of("^10[.]42[.]0[.]256$", "^2001:db8:::12$")) {
            assertThrows(IllegalStateException.class, () -> validator(regex).afterPropertiesSet(), regex);
        }
    }

    private TrustedProxyConfigurationValidator validator(String regex) {
        MockEnvironment environment = new MockEnvironment();
        environment.setActiveProfiles("pre");
        return new TrustedProxyConfigurationValidator(environment, "pre", "native", regex);
    }
}
