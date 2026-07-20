package com.tuowei.dazhongdianping.module.rank.model;

import lombok.Data;

@Data
public class RankSnapshotRow {
    private Long id;
    private String name;
    private Integer type;
    private String region;
    private Long cityId;
    private Long categoryId;
    private Long configId;
    private String period;
}
