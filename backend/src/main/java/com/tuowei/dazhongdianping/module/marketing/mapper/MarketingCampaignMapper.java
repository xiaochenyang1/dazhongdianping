package com.tuowei.dazhongdianping.module.marketing.mapper;

import com.tuowei.dazhongdianping.module.marketing.model.GroupBuyCampaignRow;
import com.tuowei.dazhongdianping.module.marketing.model.GroupBuyTeamRow;
import com.tuowei.dazhongdianping.module.marketing.model.SeckillClaimRow;
import com.tuowei.dazhongdianping.module.marketing.model.SeckillEventRow;
import java.time.LocalDateTime;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface MarketingCampaignMapper {

    String selectShopCurrency(@Param("shopId") Long shopId, @Param("region") String region);

    int countOwnedDeal(
            @Param("dealId") Long dealId,
            @Param("shopId") Long shopId,
            @Param("merchantId") Long merchantId,
            @Param("region") String region);

    void insertSeckill(SeckillEventRow row);

    List<SeckillEventRow> selectMerchantSeckills(
            @Param("merchantId") Long merchantId,
            @Param("shopId") Long shopId,
            @Param("region") String region);

    List<SeckillEventRow> selectActiveSeckills(@Param("region") String region, @Param("now") LocalDateTime now);

    List<SeckillEventRow> selectAdminSeckills(@Param("region") String region);

    SeckillEventRow selectSeckill(@Param("id") Long id, @Param("region") String region);

    int updateSeckillAudit(
            @Param("id") Long id,
            @Param("region") String region,
            @Param("auditStatus") Integer auditStatus,
            @Param("rejectReason") String rejectReason);

    int incrementSeckillSold(
            @Param("id") Long id, @Param("region") String region, @Param("now") LocalDateTime now);

    int countSeckillClaim(@Param("eventId") Long eventId, @Param("userId") Long userId);

    void insertSeckillClaim(SeckillClaimRow row);

    void insertGroup(GroupBuyCampaignRow row);

    List<GroupBuyCampaignRow> selectMerchantGroups(
            @Param("merchantId") Long merchantId,
            @Param("shopId") Long shopId,
            @Param("region") String region);

    List<GroupBuyCampaignRow> selectActiveGroups(@Param("region") String region, @Param("now") LocalDateTime now);

    List<GroupBuyCampaignRow> selectAdminGroups(@Param("region") String region);

    GroupBuyCampaignRow selectGroup(@Param("id") Long id, @Param("region") String region);

    int updateGroupAudit(
            @Param("id") Long id,
            @Param("region") String region,
            @Param("auditStatus") Integer auditStatus,
            @Param("rejectReason") String rejectReason);

    void insertTeam(GroupBuyTeamRow row);

    void insertMember(@Param("teamId") Long teamId, @Param("userId") Long userId);

    GroupBuyTeamRow selectTeam(@Param("id") Long id);

    int countTeamMember(@Param("teamId") Long teamId, @Param("userId") Long userId);

    int joinTeam(
            @Param("id") Long id,
            @Param("region") String region,
            @Param("groupSize") int groupSize,
            @Param("now") LocalDateTime now);
}
