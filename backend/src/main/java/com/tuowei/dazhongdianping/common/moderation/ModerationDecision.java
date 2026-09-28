package com.tuowei.dazhongdianping.common.moderation;

/** 机审结论。数值与 automod_hit.decision 一致。 */
public enum ModerationDecision {
    PASS(1),
    REVIEW(2),
    BLOCK(3);

    private final int code;

    ModerationDecision(int code) {
        this.code = code;
    }

    public int code() {
        return code;
    }
}
