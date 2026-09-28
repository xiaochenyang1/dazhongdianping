package com.tuowei.dazhongdianping.module.openapi.model;

import java.math.BigDecimal;

/** 开放接口对外暴露的公开点评摘要。 */
public class OpenReviewRow {
    private Long id;
    private Long shopId;
    private BigDecimal score;
    private String content;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getShopId() { return shopId; }
    public void setShopId(Long shopId) { this.shopId = shopId; }
    public BigDecimal getScore() { return score; }
    public void setScore(BigDecimal score) { this.score = score; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
}
