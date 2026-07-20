package com.tuowei.dazhongdianping.module.browse.model;

import lombok.Data;

@Data
public class CategoryRow {
    private Long id;
    private Long parentId;
    private String name;
    private Integer sortNo;
}
