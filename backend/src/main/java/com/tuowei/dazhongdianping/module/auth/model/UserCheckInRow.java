package com.tuowei.dazhongdianping.module.auth.model;

import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.Data;

@Data
public class UserCheckInRow {

    private Long id;
    private Long userId;
    private LocalDate checkInDate;
    private Integer streakDays;
    private Integer growthValue;
    private Integer points;
    private LocalDateTime createdAt;
}
