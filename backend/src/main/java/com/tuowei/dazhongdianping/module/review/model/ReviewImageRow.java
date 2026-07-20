package com.tuowei.dazhongdianping.module.review.model;

import lombok.Data;

@Data
public class ReviewImageRow {

    private Long id;
    private Long reviewId;
    private String url;
    private Integer mediaType;
    private Integer sortNo;
}
