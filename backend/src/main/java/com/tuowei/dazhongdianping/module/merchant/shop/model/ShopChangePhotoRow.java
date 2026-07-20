package com.tuowei.dazhongdianping.module.merchant.shop.model;

import lombok.Data;

@Data
public class ShopChangePhotoRow {
    private Long id;
    private Long changeId;
    private String imageUrl;
    private Integer photoType;
    private Integer sort;
}
