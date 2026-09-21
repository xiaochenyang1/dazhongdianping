package com.tuowei.dazhongdianping.common.riskcontrol;

/**
 * 风控拦截异常：当评估动作为 BLOCK 时由挂钩点抛出，交 GlobalExceptionHandler 转 403。
 * 携带独立 messageKey 供前端本地化提示（各端只需展示"操作被风控拦截"类文案）。
 */
public class RiskBlockedException extends RuntimeException {

    private final String messageKey;

    public RiskBlockedException(String message, String messageKey) {
        super(message);
        this.messageKey = messageKey;
    }

    public String getMessageKey() {
        return messageKey;
    }
}
