package com.tuowei.dazhongdianping.module.merchant.model.request;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;
import java.time.LocalTime;

public record MerchantSlotSaveRequest(
        @NotNull Long shopId,
        @NotNull @JsonFormat(pattern = "yyyy-MM-dd") LocalDate bizDate,
        @NotNull @JsonFormat(pattern = "HH:mm:ss") LocalTime startTime,
        @NotNull @JsonFormat(pattern = "HH:mm:ss") LocalTime endTime,
        @NotNull @Min(1) @Max(500) Integer capacity,
        @NotNull @Min(1) @Max(2) Integer confirmMode,
        @NotNull @Min(0) @Max(24 * 60) Integer cancelBeforeMinutes,
        Boolean enabled
) {
}
