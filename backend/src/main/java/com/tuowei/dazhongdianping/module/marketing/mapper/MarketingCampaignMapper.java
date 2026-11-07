package com.tuowei.dazhongdianping.module.marketing.mapper;

import com.tuowei.dazhongdianping.module.marketing.model.GroupBuyCampaignRow;
import com.tuowei.dazhongdianping.module.marketing.model.GroupBuyMemberRow;
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

    SeckillEventRow selectSeckillForUpdate(@Param("id") Long id, @Param("region") String region);

    int updateSeckillAudit(
            @Param("id") Long id,
            @Param("region") String region,
            @Param("auditStatus") Integer auditStatus,
            @Param("rejectReason") String rejectReason);

    int incrementSeckillSold(
            @Param("id") Long id, @Param("region") String region, @Param("now") LocalDateTime now);

    int countSeckillClaim(@Param("eventId") Long eventId, @Param("userId") Long userId);

    void insertSeckillClaim(SeckillClaimRow row);

    SeckillClaimRow selectSeckillClaim(@Param("eventId") Long eventId, @Param("userId") Long userId);

    List<SeckillClaimRow> selectSeckillClaimsForUser(@Param("userId") Long userId, @Param("region") String region);

    int reserveSeckillClaim(SeckillClaimRow row);

    int markSeckillClaimPaid(@Param("orderId") Long orderId);

    int releaseSeckillClaim(@Param("orderId") Long orderId, @Param("status") Integer status);

    int releaseSeckillStock(@Param("id") Long id, @Param("quantity") Integer quantity);

    void insertGroup(GroupBuyCampaignRow row);

    List<GroupBuyCampaignRow> selectMerchantGroups(
            @Param("merchantId") Long merchantId,
            @Param("shopId") Long shopId,
            @Param("region") String region);

    List<GroupBuyCampaignRow> selectActiveGroups(@Param("region") String region, @Param("now") LocalDateTime now);

    List<GroupBuyCampaignRow> selectAdminGroups(@Param("region") String region);

    GroupBuyCampaignRow selectGroup(@Param("id") Long id, @Param("region") String region);

    GroupBuyCampaignRow selectGroupForUpdate(@Param("id") Long id, @Param("region") String region);

    int updateGroupAudit(
            @Param("id") Long id,
            @Param("region") String region,
            @Param("auditStatus") Integer auditStatus,
            @Param("rejectReason") String rejectReason);

    void insertTeam(GroupBuyTeamRow row);

    void insertMember(GroupBuyMemberRow row);

    GroupBuyTeamRow selectTeam(@Param("id") Long id);

    GroupBuyTeamRow selectTeamForUpdate(@Param("id") Long id);

    GroupBuyTeamRow selectTeamByOrder(@Param("orderId") Long orderId);

    GroupBuyMemberRow selectActiveMember(
            @Param("campaignId") Long campaignId,
            @Param("userId") Long userId,
            @Param("region") String region);

    GroupBuyMemberRow selectMemberByOrderForUpdate(@Param("orderId") Long orderId);

    int countTeamMember(@Param("teamId") Long teamId, @Param("userId") Long userId);

    int joinTeam(
            @Param("id") Long id,
            @Param("region") String region,
            @Param("groupSize") int groupSize,
            @Param("now") LocalDateTime now);

    int markGroupBuyMemberPaid(@Param("orderId") Long orderId);

    int recordGroupBuyPayment(@Param("teamId") Long teamId);

    List<Long> selectPaidGroupBuyOrderIds(@Param("teamId") Long teamId);

    int releaseGroupBuyMember(@Param("orderId") Long orderId);

    int refreshOpenGroupBuyTeam(@Param("teamId") Long teamId);

    List<Long> selectExpiredGroupBuyTeamIds(@Param("limit") Integer limit);

    int markGroupBuyTeamExpired(@Param("teamId") Long teamId);

    List<Long> selectGroupBuyOrderIds(@Param("teamId") Long teamId);
}
