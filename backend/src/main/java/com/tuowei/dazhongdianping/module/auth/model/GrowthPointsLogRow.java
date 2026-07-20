package com.tuowei.dazhongdianping.module.auth.model;

import java.time.LocalDateTime;
import lombok.Data;

@Data
public class GrowthPointsLogRow {

    private Long id;
    private Long userId;
    private Integer type;
    private String action;
    private Long bizId;
    private Integer changeAmount;
    private Integer balanceAfter;
    private String remark;
    private LocalDateTime createdAt;
}
