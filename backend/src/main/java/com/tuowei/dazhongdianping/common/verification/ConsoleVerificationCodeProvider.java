package com.tuowei.dazhongdianping.common.verification;

import com.tuowei.dazhongdianping.config.VerificationCodeProperties;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

/**
 * 控制台 dev provider:把验证码打到日志,供本地无真实 SMS/SMTP 时联调。
 *
 * <p>仅在 {@code dev-console-enabled=true} 且 mock 关闭时激活:mock 开时让位给 mock 路径
 * (mock 路径回传固定码、不真正"发送");strict 模式(pre/prod)下由
 * {@code ApplicationSafetyValidator} 拦截 {@code dev-console-enabled=true} 防止日志泄露真实码。
 */
@Component
public class ConsoleVerificationCodeProvider implements VerificationCodeProvider {

    private static final Logger LOGGER = LoggerFactory.getLogger(ConsoleVerificationCodeProvider.class);

    private final VerificationCodeProperties properties;

    public ConsoleVerificationCodeProvider(VerificationCodeProperties properties) {
        this.properties = properties;
    }

    @Override
    public String name() {
        return "CONSOLE";
    }

    @Override
    public boolean isConfigured() {
        return properties.isDevConsoleEnabled() && !properties.isMockEnabled();
    }

    @Override
    public void send(String target, int targetType, String code, String scene) {
        if (!isConfigured()) {
            throw new VerificationCodeSendException("控制台验证码通道未启用");
        }
        LOGGER.info(
                "[verification-code] scene={} targetType={} target={} code={}",
                scene, targetType, mask(target), code
        );
    }

    /**
     * 仅日志安全用的脱敏:保留首尾各 2 字符,中间替换为 ***。真实发送渠道不应记录码本身。
     */
    static String mask(String target) {
        if (!StringUtils.hasText(target)) {
            return "";
        }
        if (target.length() <= 4) {
            return "***";
        }
        return target.substring(0, 2) + "***" + target.substring(target.length() - 2);
    }
}
