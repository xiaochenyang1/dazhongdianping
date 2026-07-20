package com.tuowei.dazhongdianping.module.merchant.mapper;

import com.tuowei.dazhongdianping.module.browse.model.ShopListQuery;
import com.tuowei.dazhongdianping.module.browse.model.ShopListRow;
import com.tuowei.dazhongdianping.module.merchant.model.MerchantAccountRow;
import java.util.List;
import org.apache.ibatis.annotations.Param;

public interface MerchantWorkbenchMapper {

    MerchantAccountRow selectMerchantAccount(@Param("merchantId") Long merchantId,
                                              @Param("account") String account);

    long countMerchantShops(@Param("merchantId") Long merchantId,
                            @Param("region") String region,
                            @Param("shopIds") List<Long> shopIds,
                            @Param("query") ShopListQuery query);

    List<ShopListRow> selectMerchantShops(@Param("merchantId") Long merchantId,
                                          @Param("region") String region,
                                          @Param("shopIds") List<Long> shopIds,
                                          @Param("query") ShopListQuery query);
}
