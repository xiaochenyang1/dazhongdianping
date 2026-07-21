package com.tuowei.dazhongdianping.module.merchant.shop.mapper;

import com.tuowei.dazhongdianping.module.merchant.shop.model.ShopChangeDishRow;
import com.tuowei.dazhongdianping.module.merchant.shop.model.ShopChangePhotoRow;
import com.tuowei.dazhongdianping.module.merchant.shop.model.ShopChangeRow;
import com.tuowei.dazhongdianping.module.merchant.shop.model.request.ShopChangeDishRequest;
import com.tuowei.dazhongdianping.module.merchant.shop.model.request.ShopChangePhotoRequest;
import java.time.LocalDateTime;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface MerchantShopChangeMapper {

    ShopChangeRow selectActiveChange(@Param("merchantId") Long merchantId,
                                     @Param("region") String region,
                                     @Param("shopId") Long shopId);

    ShopChangeRow selectLiveShopSnapshot(@Param("shopId") Long shopId,
                                         @Param("merchantId") Long merchantId,
                                         @Param("region") String region);

    ShopChangeRow selectChange(@Param("changeId") Long changeId,
                               @Param("merchantId") Long merchantId,
                               @Param("region") String region);

    ShopChangeRow selectPendingChangeForAudit(@Param("changeId") Long changeId,
                                              @Param("region") String region);

    long countChanges(@Param("merchantId") Long merchantId,
                      @Param("region") String region,
                      @Param("shopId") Long shopId,
                      @Param("status") Integer status,
                      @Param("changeType") Integer changeType,
                      @Param("shopIds") List<Long> shopIds);

    List<ShopChangeRow> selectChanges(@Param("merchantId") Long merchantId,
                                      @Param("region") String region,
                                      @Param("shopId") Long shopId,
                                      @Param("status") Integer status,
                                      @Param("changeType") Integer changeType,
                                      @Param("shopIds") List<Long> shopIds,
                                      @Param("limit") Integer limit,
                                      @Param("offset") Integer offset);

    void insertChange(ShopChangeRow row);

    void insertLiveShop(ShopChangeRow row);

    void insertLivePhotosFromChange(@Param("shopId") Long shopId,
                                    @Param("changeId") Long changeId);

    void insertLiveDishesFromChange(@Param("shopId") Long shopId,
                                    @Param("changeId") Long changeId);

    LocalDateTime selectLiveShopUpdatedAtForUpdate(@Param("shopId") Long shopId,
                                                   @Param("merchantId") Long merchantId,
                                                   @Param("region") String region);

    int applyLiveShopFields(ShopChangeRow row);

    void deleteLivePhotos(@Param("shopId") Long shopId);

    void deleteLiveDishes(@Param("shopId") Long shopId);

    int approveChange(@Param("changeId") Long changeId,
                      @Param("region") String region,
                      @Param("auditBy") Long auditBy,
                      @Param("targetShopId") Long targetShopId);

    int rejectChange(@Param("changeId") Long changeId,
                     @Param("region") String region,
                     @Param("auditBy") Long auditBy,
                     @Param("reason") String reason);

    int resetRejectedChange(@Param("changeId") Long changeId,
                            @Param("merchantId") Long merchantId,
                            @Param("region") String region,
                            @Param("operatorId") Long operatorId);

    int updateChangeFields(ShopChangeRow row);

    int submitChange(@Param("changeId") Long changeId,
                     @Param("merchantId") Long merchantId,
                     @Param("region") String region,
                     @Param("operatorId") Long operatorId);

    void copyLivePhotos(@Param("changeId") Long changeId, @Param("shopId") Long shopId);

    void copyLiveDishes(@Param("changeId") Long changeId, @Param("shopId") Long shopId);

    List<ShopChangePhotoRow> selectChangePhotos(@Param("changeId") Long changeId);

    List<ShopChangeDishRow> selectChangeDishes(@Param("changeId") Long changeId);

    void deleteChangePhotos(@Param("changeId") Long changeId);

    void insertChangePhotos(@Param("changeId") Long changeId,
                            @Param("photos") List<ShopChangePhotoRequest> photos);

    void deleteChangeDishes(@Param("changeId") Long changeId);

    void insertChangeDishes(@Param("changeId") Long changeId,
                            @Param("dishes") List<ShopChangeDishRequest> dishes);

    void insertOperationLog(@Param("merchantId") Long merchantId,
                            @Param("operatorId") Long operatorId,
                            @Param("action") String action,
                            @Param("targetType") String targetType,
                            @Param("targetId") Long targetId,
                            @Param("detail") String detail);
}
