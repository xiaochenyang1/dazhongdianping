package com.tuowei.dazhongdianping.module.waitlist.mapper;

import com.tuowei.dazhongdianping.module.waitlist.model.WaitlistEntryRow;
import java.time.LocalDateTime;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface WaitlistMapper {

    Long selectShopMerchantId(@Param("shopId") Long shopId, @Param("region") String region);

    int nextQueueNo(@Param("shopId") Long shopId, @Param("tableType") Integer tableType);

    void insertEntry(WaitlistEntryRow row);

    WaitlistEntryRow selectEntry(@Param("id") Long id, @Param("region") String region);

    WaitlistEntryRow selectUserEntry(
            @Param("id") Long id, @Param("userId") Long userId, @Param("region") String region);

    WaitlistEntryRow selectMerchantEntry(
            @Param("id") Long id, @Param("merchantId") Long merchantId, @Param("region") String region);

    List<WaitlistEntryRow> selectUserActiveEntries(@Param("userId") Long userId, @Param("region") String region);

    List<WaitlistEntryRow> selectShopQueue(
            @Param("shopId") Long shopId, @Param("merchantId") Long merchantId, @Param("region") String region);

    /** 该用户在该门店是否已有排队中/已叫号的号（防重复取号）。 */
    int countActiveForUserShop(
            @Param("userId") Long userId, @Param("shopId") Long shopId, @Param("region") String region);

    /** 前面还有多少桌在排（同门店同桌型、排队中、号更小）。 */
    int aheadCount(
            @Param("shopId") Long shopId, @Param("tableType") Integer tableType, @Param("queueNo") Integer queueNo);

    /** 商家状态流转：仅当前状态在 fromA/fromB 时置为目标状态。 */
    int updateStatus(
            @Param("id") Long id, @Param("merchantId") Long merchantId,
            @Param("toStatus") Integer toStatus,
            @Param("fromA") Integer fromA, @Param("fromB") Integer fromB,
            @Param("calledAt") LocalDateTime calledAt, @Param("seatedAt") LocalDateTime seatedAt);

    /** 用户取消：仅当排队中(1)可取消。 */
    int cancel(@Param("id") Long id, @Param("userId") Long userId);
}
