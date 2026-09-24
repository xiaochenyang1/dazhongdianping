package com.tuowei.dazhongdianping.module.guide.model;

/** 攻略章节行。 */
public class GuideSectionRow {
    private Long id;
    private Long articleId;
    private Integer sortNo;
    private String heading;
    private String body;
    private Long shopId;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Long getArticleId() { return articleId; }
    public void setArticleId(Long articleId) { this.articleId = articleId; }
    public Integer getSortNo() { return sortNo; }
    public void setSortNo(Integer sortNo) { this.sortNo = sortNo; }
    public String getHeading() { return heading; }
    public void setHeading(String heading) { this.heading = heading; }
    public String getBody() { return body; }
    public void setBody(String body) { this.body = body; }
    public Long getShopId() { return shopId; }
    public void setShopId(Long shopId) { this.shopId = shopId; }
}
