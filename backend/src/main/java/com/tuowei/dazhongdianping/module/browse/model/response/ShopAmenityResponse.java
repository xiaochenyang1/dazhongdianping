package com.tuowei.dazhongdianping.module.browse.model.response;

public record ShopAmenityResponse(
        boolean chineseService,
        boolean chineseMenu,
        boolean acceptAlipay,
        boolean acceptWechat
) {
}
