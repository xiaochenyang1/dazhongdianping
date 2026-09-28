package com.tuowei.dazhongdianping.module.qa.model;

import java.time.LocalDateTime;

/** 商户问答-问题行。 */
public class ShopQuestionRow {
    private Long id;
    private String region;
    private Long shopId;
    private Long userId;
    private String content;
    private Integer answerCount;
    private LocalDateTime createdAt;
    private String userNickname;
    private String latestAnswer;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }
    public Long getShopId() { return shopId; }
    public void setShopId(Long shopId) { this.shopId = shopId; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
    public Integer getAnswerCount() { return answerCount; }
    public void setAnswerCount(Integer answerCount) { this.answerCount = answerCount; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public String getUserNickname() { return userNickname; }
    public void setUserNickname(String userNickname) { this.userNickname = userNickname; }
    public String getLatestAnswer() { return latestAnswer; }
    public void setLatestAnswer(String latestAnswer) { this.latestAnswer = latestAnswer; }
}
