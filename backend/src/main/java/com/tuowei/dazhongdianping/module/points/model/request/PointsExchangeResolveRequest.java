package com.tuowei.dazhongdianping.module.points.model.request;

import jakarta.validation.constraints.Size;
import lombok.Data;

/** 运营对「待发放」兑换单的处理请求：发放时可指定线下券码，取消时说明原因。 */
@Data
public class PointsExchangeResolveRequest {

    @Size(max = 32, message = "redeemCode 不能超过 32 字")
    private String redeemCode;

    @Size(max = 255, message = "remark 不能超过 255 字")
    private String remark;
}
