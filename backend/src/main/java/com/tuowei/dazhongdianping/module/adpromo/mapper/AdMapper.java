package com.tuowei.dazhongdianping.module.adpromo.mapper;

import com.tuowei.dazhongdianping.module.adpromo.model.AdCampaignRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface AdMapper {

    /** 校验门店归属并取商户 id；不属于该商户或不存在返回 null。 */
    Long selectShopMerchantId(@Param("shopId") Long shopId, @Param("region") String region);

    void insertCampaign(AdCampaignRow row);

    int updateCampaign(AdCampaignRow row);

    AdCampaignRow selectCampaign(@Param("id") Long id, @Param("region") String region);

    AdCampaignRow selectMerchantCampaign(
            @Param("id") Long id, @Param("merchantId") Long merchantId, @Param("region") String region);

    List<AdCampaignRow> selectMerchantCampaigns(
            @Param("merchantId") Long merchantId, @Param("region") String region,
            @Param("limit") int limit, @Param("offset") int offset);

    long countMerchantCampaigns(@Param("merchantId") Long merchantId, @Param("region") String region);

    List<AdCampaignRow> selectAdminCampaigns(
            @Param("region") String region, @Param("auditStatus") Integer auditStatus,
            @Param("limit") int limit, @Param("offset") int offset);

    long countAdminCampaigns(@Param("region") String region, @Param("auditStatus") Integer auditStatus);

    /** 商家暂停/恢复投放（0下线/1投放中/2暂停），仅本商户可改。 */
    int updateStatus(
            @Param("id") Long id, @Param("merchantId") Long merchantId, @Param("status") Integer status);

    /** 平台审核置为通过(2)/驳回(3)，仅待审核(1)可处置。 */
    int updateAudit(
            @Param("id") Long id, @Param("region") String region,
            @Param("auditStatus") Integer auditStatus, @Param("rejectReason") String rejectReason);

    /** 固定坑位竞价召回：已过审、投放中、预算未用尽，按出价降序。 */
    List<AdCampaignRow> selectServing(
            @Param("region") String region, @Param("slotType") Integer slotType,
            @Param("keyword") String keyword, @Param("limit") int limit);

    /** 原子点击计费：跨天清零 + 预算封顶，命中则累加花费返回 1，超预算/不可投返回 0。 */
    int chargeClick(@Param("id") Long id, @Param("region") String region);

    void insertClickLog(
            @Param("campaignId") Long campaignId, @Param("region") String region,
            @Param("shopId") Long shopId, @Param("userId") Long userId,
            @Param("cost") java.math.BigDecimal cost);
}
