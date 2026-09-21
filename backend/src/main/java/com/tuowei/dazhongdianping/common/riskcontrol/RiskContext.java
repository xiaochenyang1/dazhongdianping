package com.tuowei.dazhongdianping.common.riskcontrol;

/**
 * 风控评估上下文：一次评估请求携带的主体与业务信息。
 * 由挂钩点（点评提交/下单/注册）构造并传入 RiskEvaluationService。
 */
public final class RiskContext {

    private final RiskScene scene;
    private final String region;
    private final Long userId;
    private final String deviceFingerprint;
    private final String ip;
    private final Long bizId;
    /** 场景相关文本，如点评内容，用于相似度类规则。 */
    private final String content;

    private RiskContext(Builder builder) {
        this.scene = builder.scene;
        this.region = builder.region;
        this.userId = builder.userId;
        this.deviceFingerprint = builder.deviceFingerprint;
        this.ip = builder.ip;
        this.bizId = builder.bizId;
        this.content = builder.content;
    }

    public RiskScene scene() {
        return scene;
    }

    public String region() {
        return region;
    }

    public Long userId() {
        return userId;
    }

    public String deviceFingerprint() {
        return deviceFingerprint;
    }

    public String ip() {
        return ip;
    }

    public Long bizId() {
        return bizId;
    }

    public String content() {
        return content;
    }

    public static Builder builder(RiskScene scene, String region) {
        return new Builder(scene, region);
    }

    public static final class Builder {
        private final RiskScene scene;
        private final String region;
        private Long userId;
        private String deviceFingerprint;
        private String ip;
        private Long bizId;
        private String content;

        private Builder(RiskScene scene, String region) {
            this.scene = scene;
            this.region = region;
        }

        public Builder userId(Long userId) {
            this.userId = userId;
            return this;
        }

        public Builder deviceFingerprint(String deviceFingerprint) {
            this.deviceFingerprint = deviceFingerprint;
            return this;
        }

        public Builder ip(String ip) {
            this.ip = ip;
            return this;
        }

        public Builder bizId(Long bizId) {
            this.bizId = bizId;
            return this;
        }

        public Builder content(String content) {
            this.content = content;
            return this;
        }

        public RiskContext build() {
            return new RiskContext(this);
        }
    }
}
