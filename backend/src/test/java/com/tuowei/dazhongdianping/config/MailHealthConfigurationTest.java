package com.tuowei.dazhongdianping.config;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.boot.actuate.autoconfigure.mail.MailHealthContributorAutoConfiguration;
import org.springframework.boot.actuate.health.HealthContributor;
import org.springframework.boot.autoconfigure.AutoConfigurations;
import org.springframework.boot.autoconfigure.mail.MailSenderAutoConfiguration;
import org.springframework.boot.env.YamlPropertySourceLoader;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.core.env.PropertySource;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.mail.javamail.JavaMailSenderImpl;

class MailHealthConfigurationTest {

    private final ApplicationContextRunner contextRunner = new ApplicationContextRunner()
            .withInitializer(MailHealthConfigurationTest::loadMainApplicationProperties)
            .withConfiguration(AutoConfigurations.of(
                    MailSenderAutoConfiguration.class,
                    MailHealthContributorAutoConfiguration.class
            ));

    @Test
    void shouldNotCreateMailHealthContributorWhenVerificationMailIsDisabled() {
        contextRunner.run(context -> {
            assertThat(context.getEnvironment().getProperty("management.health.mail.enabled", Boolean.class))
                    .isFalse();
            assertThat(context).hasSingleBean(JavaMailSenderImpl.class);
            assertThat(context).doesNotHaveBean("mailHealthContributor");
        });
    }

    @Test
    void shouldCreateMailHealthContributorWhenVerificationMailIsEnabled() {
        contextRunner
                .withPropertyValues(
                        "APP_AUTH_VERIFICATION_MAIL_ENABLED=true",
                        "APP_MAIL_HOST=smtp.example.test"
                )
                .run(context -> {
                    assertThat(context.getEnvironment()
                            .getProperty("management.health.mail.enabled", Boolean.class)).isTrue();
                    assertThat(context).hasSingleBean(JavaMailSenderImpl.class);
                    assertThat(context).hasSingleBean(HealthContributor.class);
                    assertThat(context).hasBean("mailHealthContributor");
                });
    }

    @Test
    void shouldAllowMailHealthCheckToBeDisabledIndependently() {
        contextRunner
                .withPropertyValues(
                        "APP_AUTH_VERIFICATION_MAIL_ENABLED=true",
                        "APP_MAIL_HEALTH_ENABLED=false",
                        "APP_MAIL_HOST=smtp.example.test"
                )
                .run(context -> {
                    assertThat(context.getEnvironment()
                            .getProperty("management.health.mail.enabled", Boolean.class)).isFalse();
                    assertThat(context).doesNotHaveBean("mailHealthContributor");
                });
    }

    private static void loadMainApplicationProperties(
            org.springframework.context.ConfigurableApplicationContext context) {
        YamlPropertySourceLoader loader = new YamlPropertySourceLoader();
        try {
            for (Resource resource : new PathMatchingResourcePatternResolver()
                    .getResources("classpath*:application.yml")) {
                List<PropertySource<?>> propertySources = loader.load(resource.getDescription(), resource);
                if (isMainApplicationConfiguration(propertySources)) {
                    propertySources.forEach(propertySource -> context.getEnvironment()
                            .getPropertySources().addLast(propertySource));
                    return;
                }
            }
        } catch (IOException exception) {
            throw new UncheckedIOException("Unable to load application.yml", exception);
        }
        throw new IllegalStateException("Main application.yml was not found on the test classpath");
    }

    private static boolean isMainApplicationConfiguration(List<PropertySource<?>> propertySources) {
        return propertySources.stream().anyMatch(propertySource ->
                propertySource.containsProperty("spring.mail.host")
                        && propertySource.containsProperty("app.auth.verification-code.mail.enabled")
                        && propertySource.containsProperty("management.health.mail.enabled"));
    }
}
