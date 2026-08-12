package com.tuowei.dazhongdianping.common.verification;

import java.util.List;
import org.springframework.stereotype.Service;

/**
 * 参照 {@code PushDispatchService} 模式:Bean 恒实例化,注入所有 {@link VerificationCodeProvider}。
 * 验证码无按目标路由的需求,故不按 channel 分桶,首个 configured provider 胜出。
 * 未来加真实 provider 时用 {@code @Order(Ordered.HIGHEST_PRECEDENCE)} 保证真实渠道优先。
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
    public VerificationCodeProvider resolveConfiguredProvider() {
        for (VerificationCodeProvider provider : providers) {
            if (provider.isConfigured()) {
                return provider;
            }
        }
        return null;
    }
}
