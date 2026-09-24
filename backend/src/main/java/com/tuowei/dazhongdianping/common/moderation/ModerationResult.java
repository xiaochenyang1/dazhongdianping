package com.tuowei.dazhongdianping.common.moderation;

/** 一次机审提供者的判定。PASS 不落库。 */
public record ModerationResult(ModerationDecision decision, String reason, String provider) {

    public static ModerationResult pass(String provider) {
        return new ModerationResult(ModerationDecision.PASS, "", provider);
    }
}
