package com.tuowei.dazhongdianping.config;

import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.regex.PatternSyntaxException;
import org.springframework.beans.factory.InitializingBean;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

/** Ensures strict deployments only accept forwarded addresses from an explicit proxy allowlist. */
@Component
public class TrustedProxyConfigurationValidator implements InitializingBean {

    private static final List<String> SOURCE_ADDRESS_PROBES = List.of(
            "0.0.0.0", "1.1.1.1", "8.8.8.8", "10.0.0.1", "127.0.0.1",
            "192.0.2.1", "203.0.113.1", "255.255.255.255", "2001:4860:4860::8888");

    private final Environment environment;
    private final String runtimeMode;
    private final String forwardingStrategy;
    private final String trustedProxyRegex;

    public TrustedProxyConfigurationValidator(
            Environment environment,
            @Value("${app.runtime-mode:prod}") String runtimeMode,
            @Value("${server.forward-headers-strategy:native}") String forwardingStrategy,
            @Value("${server.tomcat.remoteip.internal-proxies:(?!)}") String trustedProxyRegex) {
        this.environment = environment;
        this.runtimeMode = runtimeMode == null ? "" : runtimeMode.trim().toLowerCase(Locale.ROOT);
        this.forwardingStrategy = forwardingStrategy == null ? "" : forwardingStrategy.trim().toLowerCase(Locale.ROOT);
        this.trustedProxyRegex = trustedProxyRegex == null ? "" : trustedProxyRegex.trim();
    }

    @Override
    public void afterPropertiesSet() {
        if (!isStrictMode()) {
            return;
        }
        if (!"native".equals(forwardingStrategy)) {
            throw new IllegalStateException("pre/prod must use native trusted-proxy address handling");
        }
        if (!StringUtils.hasText(trustedProxyRegex)
                || "(?!)".equals(trustedProxyRegex)
                || trustedProxyRegex.contains("CHANGE_ME")) {
            throw new IllegalStateException(
                    "APP_TRUSTED_PROXY_REGEX must explicitly list the approved ingress/LB peer addresses in pre/prod");
        }
        if (!trustedProxyRegex.startsWith("^") || !trustedProxyRegex.endsWith("$")) {
            throw new IllegalStateException("APP_TRUSTED_PROXY_REGEX must be anchored with ^ and $ in pre/prod");
        }
        try {
            validateExplicitAddressAllowlist(trustedProxyRegex);
            Pattern trustedProxies = Pattern.compile(trustedProxyRegex);
            if (SOURCE_ADDRESS_PROBES.stream().allMatch(
                    address -> trustedProxies.matcher(address).matches())) {
                throw new IllegalStateException("APP_TRUSTED_PROXY_REGEX must not trust every source address");
            }
        } catch (PatternSyntaxException exception) {
            throw new IllegalStateException("APP_TRUSTED_PROXY_REGEX must be a valid Java regular expression", exception);
        }
    }

    /** Restrict the configured regex to a finite list of literal IP addresses. */
    private void validateExplicitAddressAllowlist(String regex) {
        String body = regex.substring(1, regex.length() - 1);
        if (body.startsWith("(?:") || body.endsWith(")")) {
            if (!body.startsWith("(?:") || !body.endsWith(")")) {
                throw invalidAllowlist();
            }
            body = body.substring(3, body.length() - 1);
        }
        if (!StringUtils.hasText(body)) {
            throw invalidAllowlist();
        }

        String[] encodedAddresses = body.split("\\|", -1);
        for (String encodedAddress : encodedAddresses) {
            String address = decodeLiteralAddress(encodedAddress);
            if (!isLiteralIpAddress(address)) {
                throw invalidAllowlist();
            }
        }
    }

    private String decodeLiteralAddress(String encodedAddress) {
        StringBuilder address = new StringBuilder(encodedAddress.length());
        for (int index = 0; index < encodedAddress.length();) {
            char current = encodedAddress.charAt(index);
            if (Character.digit(current, 16) >= 0 || current == ':') {
                address.append(current);
                index++;
            } else if (encodedAddress.startsWith("[.]", index)) {
                address.append('.');
                index += 3;
            } else if (encodedAddress.startsWith("\\.", index)) {
                address.append('.');
                index += 2;
            } else {
                throw invalidAllowlist();
            }
        }
        return address.toString();
    }

    private boolean isLiteralIpAddress(String address) {
        Matcher ipv4 = Pattern.compile("[0-9]{1,3}(?:\\.[0-9]{1,3}){3}").matcher(address);
        if (ipv4.matches()) {
            for (String octet : address.split("\\.")) {
                if ((octet.length() > 1 && octet.startsWith("0")) || Integer.parseInt(octet) > 255) {
                    return false;
                }
            }
            return true;
        }
        if (!address.contains(":") || !address.matches("[0-9A-Fa-f:]+")) {
            return false;
        }
        try {
            return java.net.InetAddress.getByName(address) instanceof java.net.Inet6Address;
        } catch (java.net.UnknownHostException exception) {
            return false;
        }
    }

    private IllegalStateException invalidAllowlist() {
        return new IllegalStateException(
                "APP_TRUSTED_PROXY_REGEX must be an anchored list of exact IPv4/IPv6 addresses "
                        + "separated by |; use [.] or \\. for IPv4 dots");
    }

    private boolean isStrictMode() {
        return "pre".equals(runtimeMode)
                || "prod".equals(runtimeMode)
                || Arrays.stream(environment.getActiveProfiles())
                        .map(profile -> profile.toLowerCase(Locale.ROOT))
                        .anyMatch(profile -> "pre".equals(profile) || "prod".equals(profile));
    }
}
