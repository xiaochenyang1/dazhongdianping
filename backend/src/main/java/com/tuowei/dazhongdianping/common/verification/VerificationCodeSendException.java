package com.tuowei.dazhongdianping.common.verification;

/**
 * 验证码发送失败时抛出。unchecked,使 {@code @Transactional} 回滚语义清晰,调用方 catch 后转 503。
 */
public class VerificationCodeSendException extends RuntimeException {

    public VerificationCodeSendException(String message) {
        super(message);
    }

    public VerificationCodeSendException(String message, Throwable cause) {
        super(message, cause);
    }
}
