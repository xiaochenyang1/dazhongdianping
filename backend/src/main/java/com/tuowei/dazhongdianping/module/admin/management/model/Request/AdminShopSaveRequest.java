package com.tuowei.dazhongdianping.module.admin.management.model.request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.util.List;
import lombok.Data;

@Data
public class AdminShopSaveRequest {

    private Long merchantId = 0L;

    @NotBlank(message = "region 不能为空")
    private String region;

    @NotNull(message = "categoryId 不能为空")
    private Long categoryId;

    @NotNull(message = "cityId 不能为空")
    private Long cityId;

    @NotNull(message = "areaId 不能为空")
    private Long areaId;

    @NotBlank(message = "name 不能为空")
    private String name;

    @NotBlank(message = "coverUrl 不能为空")
    private String coverUrl;

    private String phone = "";

    @NotNull(message = "pricePerCapita 不能为空")
    @DecimalMin(value = "0", message = "pricePerCapita 不能小于 0")
    private BigDecimal pricePerCapita;

    private String currency = "CNY";

    @NotBlank(message = "address 不能为空")
    private String address;

    @DecimalMin(value = "-90", message = "latitude 不能小于 -90")
    @DecimalMax(value = "90", message = "latitude 不能大于 90")
    private BigDecimal latitude;

    @DecimalMin(value = "-180", message = "longitude 不能小于 -180")
    @DecimalMax(value = "180", message = "longitude 不能大于 180")
    private BigDecimal longitude;

    @NotBlank(message = "businessHours 不能为空")
    private String businessHours;

    @NotBlank(message = "summary 不能为空")
    private String summary;

    @DecimalMin(value = "0", message = "score 不能小于 0")
    private BigDecimal score = BigDecimal.ZERO;

    @DecimalMin(value = "0", message = "tasteScore 不能小于 0")
    private BigDecimal tasteScore = BigDecimal.ZERO;

    @DecimalMin(value = "0", message = "envScore 不能小于 0")
    private BigDecimal envScore = BigDecimal.ZERO;

    @DecimalMin(value = "0", message = "serviceScore 不能小于 0")
    private BigDecimal serviceScore = BigDecimal.ZERO;

    private Boolean hasDeal = Boolean.FALSE;
    private Boolean openNow = Boolean.TRUE;
    private Integer status = 1;
    private List<String> tags = List.of();
}
