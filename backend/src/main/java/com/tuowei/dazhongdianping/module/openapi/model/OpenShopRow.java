package com.tuowei.dazhongdianping.module.openapi.model;

import java.math.BigDecimal;

/** 开放接口对外暴露的门店摘要。 */
public class OpenShopRow {
    private Long id;
    private String name;
    private String address;
    private BigDecimal score;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public BigDecimal getScore() { return score; }
    public void setScore(BigDecimal score) { this.score = score; }
}
