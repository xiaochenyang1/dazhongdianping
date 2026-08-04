package com.tuowei.dazhongdianping.module.points.model.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class PointsProductSaveRequest {

    @NotBlank(message = "name 不能为空")
    @Size(max = 64, message = "name 不能超过 64 字")
    private String name;

    @Size(max = 255, message = "coverImage 不能超过 255 字")
    private String coverImage = "";

    @Size(max = 500, message = "description 不能超过 500 字")
    private String description = "";

    @NotNull(message = "pointsPrice 不能为空")
    @Min(value = 1, message = "pointsPrice 最小为 1")
    private Integer pointsPrice;

    @NotNull(message = "stock 不能为空")
    @Min(value = 0, message = "stock 不能为负")
    private Integer stock;

    @Min(value = 0, message = "exchangeLimitPerUser 不能为负")
    private Integer exchangeLimitPerUser = 0;

    /** 1=兑换即自动发放兑换码，2=需运营人工发放。 */
    @Min(value = 1, message = "fulfillType 仅支持 1/2")
    @Max(value = 2, message = "fulfillType 仅支持 1/2")
    private Integer fulfillType = 1;

    @Min(value = 0, message = "sort 不能为负")
    private Integer sort = 0;
}
