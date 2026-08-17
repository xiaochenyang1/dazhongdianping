package com.tuowei.dazhongdianping.common.verification;

import java.util.List;
import org.springframework.stereotype.Service;

/**
 * 参照 {@code PushDispatchService} 模式:Bean 恒实例化,注入所有 {@link VerificationCodeProvider}。
 * 按目标类型(email/phone)选择首个已配置并支持该类型的 provider。
 * 真实 provider 用 {@code @Order(Ordered.HIGHEST_PRECEDENCE)} 保证优先于控制台开发通道。
 */
@Service
public class VerificationCodeDispatchService {

    private final List<VerificationCodeProvider> providers;

    public VerificationCodeDispatchService(List<VerificationCodeProvider> providers) {
        this.providers = providers == null ? List.of() : providers;
    }

    /**
     * @return 首个已配置的 provider;均未配置返回 null(调用方据此走 mock 或 503 fail-closed)
     */
    public VerificationCodeProvider resolveConfiguredProvider(String target, int targetType) {
        for (VerificationCodeProvider provider : providers) {
            if (provider.isConfigured() && provider.supports(target, targetType)) {
                return provider;
            }
        }
        return null;
    }
}
