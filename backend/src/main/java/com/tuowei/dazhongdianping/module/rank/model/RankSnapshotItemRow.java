package com.tuowei.dazhongdianping.module.rank.model;

import java.math.BigDecimal;
import lombok.Data;

@Data
public class RankSnapshotItemRow {
    private Long rankId;
    private Long shopId;
    private Integer position;
    private BigDecimal score;
    private String reason;
}
