package com.tuowei.dazhongdianping.module.marketing.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.auth.mapper.AuthCommandMapper;
import com.tuowei.dazhongdianping.module.launch.LaunchPolicy;
import com.tuowei.dazhongdianping.module.marketing.mapper.MarketingCampaignMapper;
import com.tuowei.dazhongdianping.module.marketing.model.GroupBuyCampaignRow;
import com.tuowei.dazhongdianping.module.marketing.model.GroupBuyMemberRow;
import com.tuowei.dazhongdianping.module.marketing.model.GroupBuyTeamRow;
import com.tuowei.dazhongdianping.module.trade.mapper.TradeMapper;
import com.tuowei.dazhongdianping.module.trade.model.DealRow;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.model.PaymentRow;
import com.tuowei.dazhongdianping.module.trade.model.RefundRow;
import com.tuowei.dazhongdianping.module.trade.service.OrderInventoryService;
import com.tuowei.dazhongdianping.module.trade.service.TradeService;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

/** 拼团订单：每位成员预占一份套餐，全部成员付款后成团并统一履约。 */
@Service
public class GroupBuyOrderService {

    private static final Logger log = LoggerFactory.getLogger(GroupBuyOrderService.class);
    private static final String EXPIRED_REFUND_TYPE = "groupbuy_expired";
    private static final String EXPIRED_REFUND_REASON = "拼团未在截止时间前完成，系统自动退款";

    private final MarketingCampaignMapper campaigns;
    private final TradeMapper trades;
    private final AuthCommandMapper accounts;
    private final OrderInventoryService inventory;
    private final TradeService tradeService;
    private final LaunchPolicy launch;
    private final TransactionTemplate transactions;

    public GroupBuyOrderService(
            MarketingCampaignMapper campaigns,
            TradeMapper trades,
            AuthCommandMapper accounts,
            OrderInventoryService inventory,
            TradeService tradeService,
            LaunchPolicy launch,
            PlatformTransactionManager transactionManager) {
        this.campaigns = campaigns;
        this.trades = trades;
        this.accounts = accounts;
        this.inventory = inventory;
        this.tradeService = tradeService;
        this.launch = launch;
        this.transactions = new TransactionTemplate(transactionManager);
    }

    @Transactional
    public Map<String, Object> open(Long campaignId) {
        launch.require(LaunchPolicy.Feature.GROUP_BUY);
        long userId = requireActiveUser();
        String region = region();
        LocalDateTime now = LocalDateTime.now();
        GroupBuyCampaignRow campaign = requireOpenCampaign(campaignId, region, now);
        requireNotParticipating(campaignId, userId, region);
        DealRow deal = requireDealAndReserve(campaign);

        GroupBuyTeamRow team = new GroupBuyTeamRow();
        team.setCampaignId(campaignId);
        team.setRegion(region);
        team.setLeaderUserId(userId);
        team.setExpireAt(deadline(campaign, deal, now));
        campaigns.insertTeam(team);

        OrderRow order = createOrder(campaign, deal, userId, team.getExpireAt());
        insertMember(team.getId(), campaignId, region, userId, order.getId());
        return result(team.getId(), order.getId());
    }

    @Transactional
    public Map<String, Object> join(Long teamId) {
        launch.require(LaunchPolicy.Feature.GROUP_BUY);
        long userId = requireActiveUser();
        String region = region();
        LocalDateTime now = LocalDateTime.now();

        GroupBuyTeamRow visible = campaigns.selectTeam(teamId);
        if (visible == null || !region.equals(visible.getRegion())) throw new NotFoundException("拼团不存在");
        GroupBuyCampaignRow campaign = requireOpenCampaign(visible.getCampaignId(), region, now);
        GroupBuyTeamRow team = campaigns.selectTeamForUpdate(teamId);
        if (team == null || !region.equals(team.getRegion())) throw new NotFoundException("拼团不存在");
        if (!Integer.valueOf(1).equals(team.getStatus())) throw new IllegalArgumentException("拼团已结束");
        if (team.getExpireAt() == null || !team.getExpireAt().isAfter(now)) throw new IllegalArgumentException("拼团已过期");
        requireNotParticipating(campaign.getId(), userId, region);

        int groupSize = campaign.getGroupSize() == null ? 2 : campaign.getGroupSize();
        if (campaigns.joinTeam(teamId, region, groupSize, now) != 1) {
            throw new IllegalArgumentException("拼团已满员或已结束");
        }
        DealRow deal = requireDealAndReserve(campaign);
        OrderRow order = createOrder(campaign, deal, userId, team.getExpireAt());
        insertMember(teamId, campaign.getId(), region, userId, order.getId());
        return result(teamId, order.getId());
    }

    /** 由交易补偿任务调用；返回本轮真正置为过期的团数量。 */
    public int expireDueTeams(int limit) {
        int expired = 0;
        for (Long teamId : campaigns.selectExpiredGroupBuyTeamIds(limit)) {
            Integer state = transactions.execute(ignored -> {
                if (campaigns.markGroupBuyTeamExpired(teamId) == 1) return 1;
                GroupBuyTeamRow team = campaigns.selectTeam(teamId);
                return team != null && Integer.valueOf(3).equals(team.getStatus()) ? 0 : -1;
            });
            if (state == null || state < 0) continue;
            if (state == 1) expired++;
            for (Long orderId : campaigns.selectGroupBuyOrderIds(teamId)) {
                try {
                    transactions.executeWithoutResult(ignored -> expireOrder(orderId));
                } catch (RuntimeException failure) {
                    log.warn("expired group-buy order reconcile failed: teamId={}, orderId={}",
                            teamId, orderId, failure);
                }
            }
        }
        return expired;
    }

    private void expireOrder(Long orderId) {
        OrderRow order = inventory.lockOrder(orderId);
        if (!Integer.valueOf(1).equals(order.getStatus()) || Integer.valueOf(2).equals(order.getPayStatus())) return;
        if (Integer.valueOf(0).equals(order.getPayStatus())) {
            inventory.closeUnpaid(order);
            return;
        }
        if (!Integer.valueOf(1).equals(order.getPayStatus())) return;
        PaymentRow payment = trades.selectPaymentForUpdate(orderId);
        if (payment == null || payment.getChannel() == null || payment.getChannel().isBlank()) {
            throw new IllegalStateException("拼团订单缺少可退款支付记录");
        }
        RefundRow refund = trades.selectRefundForUpdate(orderId);
        if (refund == null) {
            trades.insertAutomaticRefund(orderId, order.getAmount(), payment.getChannel(),
                    EXPIRED_REFUND_TYPE, EXPIRED_REFUND_REASON);
        } else if (Integer.valueOf(0).equals(refund.getStatus())) {
            trades.promoteRefundToAutomatic(orderId, payment.getChannel(), EXPIRED_REFUND_TYPE, EXPIRED_REFUND_REASON);
        }
        tradeService.processAutomaticRefund(orderId);
    }

    private long requireActiveUser() {
        var session = UserSessionContext.get();
        if (session == null) throw new UnauthorizedException("用户登录状态不存在");
        var account = accounts.selectUserByIdForUpdate(session.userId());
        if (account == null || !Integer.valueOf(1).equals(account.getStatus())) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        return session.userId();
    }

    private GroupBuyCampaignRow requireOpenCampaign(Long id, String region, LocalDateTime now) {
        GroupBuyCampaignRow campaign = campaigns.selectGroupForUpdate(id, region);
        if (campaign == null || !Integer.valueOf(2).equals(campaign.getAuditStatus())
                || !Integer.valueOf(1).equals(campaign.getStatus())) throw new NotFoundException("拼团活动不存在");
        if (campaign.getStartAt() != null && now.isBefore(campaign.getStartAt())
                || campaign.getEndAt() != null && !now.isBefore(campaign.getEndAt())) {
            throw new IllegalArgumentException("不在拼团活动时间内");
        }
        return campaign;
    }

    private void requireNotParticipating(Long campaignId, Long userId, String region) {
        if (campaigns.selectActiveMember(campaignId, userId, region) != null) {
            throw new IllegalArgumentException("已参加该拼团活动");
        }
    }

    private DealRow requireDealAndReserve(GroupBuyCampaignRow campaign) {
        DealRow deal = trades.selectDealForUpdate(campaign.getDealId(), campaign.getRegion());
        if (deal == null || !campaign.getShopId().equals(deal.getShopId())
                || !campaign.getMerchantId().equals(deal.getMerchantId())
                || !campaign.getCurrency().equals(deal.getCurrency())
                || deal.getValidEnd() != null && deal.getValidEnd().isBefore(LocalDate.now())) {
            throw new IllegalArgumentException("拼团套餐已失效");
        }
        if (campaign.getGroupPrice() == null || campaign.getGroupPrice().compareTo(BigDecimal.ZERO) <= 0
                || campaign.getGroupPrice().compareTo(deal.getPrice()) > 0) {
            throw new IllegalArgumentException("拼团价格已失效");
        }
        if (trades.decrementDealStock(deal.getId(), 1) != 1) throw new IllegalArgumentException("团购库存不足");
        return deal;
    }

    private LocalDateTime deadline(GroupBuyCampaignRow campaign, DealRow deal, LocalDateTime now) {
        LocalDateTime deadline = now.plusHours(24);
        if (campaign.getEndAt() != null && campaign.getEndAt().isBefore(deadline)) deadline = campaign.getEndAt();
        if (deal.getValidEnd() != null) {
            LocalDateTime validityEnd = deal.getValidEnd().plusDays(1).atStartOfDay();
            if (validityEnd.isBefore(deadline)) deadline = validityEnd;
        }
        return deadline;
    }

    private OrderRow createOrder(GroupBuyCampaignRow campaign, DealRow deal, Long userId, LocalDateTime deadline) {
        OrderRow order = new OrderRow();
        order.setOrderNo("OD" + UUID.randomUUID().toString().replace("-", "").substring(0, 30));
        order.setUserId(userId);
        order.setDealId(deal.getId());
        order.setShopId(deal.getShopId());
        order.setRegion(campaign.getRegion());
        order.setQuantity(1);
        order.setOrderSource("groupbuy");
        order.setCampaignId(campaign.getId());
        order.setCampaignTitle(campaign.getTitle());
        order.setDealTitleSnapshot(deal.getTitle());
        order.setCouponValidEnd(deal.getValidEnd());
        order.setUnitPrice(campaign.getGroupPrice());
        order.setOriginalAmount(deal.getPrice());
        order.setDiscountAmount(deal.getPrice().subtract(campaign.getGroupPrice()));
        order.setAmount(campaign.getGroupPrice());
        order.setCurrency(campaign.getCurrency());
        order.setExpireAt(deadline);
        trades.insertOrder(order);
        return order;
    }

    private void insertMember(Long teamId, Long campaignId, String region, Long userId, Long orderId) {
        GroupBuyMemberRow member = new GroupBuyMemberRow();
        member.setTeamId(teamId);
        member.setCampaignId(campaignId);
        member.setRegion(region);
        member.setUserId(userId);
        member.setOrderId(orderId);
        campaigns.insertMember(member);
    }

    private Map<String, Object> result(Long teamId, Long orderId) {
        GroupBuyTeamRow team = campaigns.selectTeam(teamId);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("id", team.getId());
        body.put("campaignId", team.getCampaignId());
        body.put("leaderUserId", team.getLeaderUserId());
        body.put("status", team.getStatus());
        body.put("memberCount", team.getMemberCount());
        body.put("paidCount", team.getPaidCount());
        body.put("groupSize", team.getGroupSize());
        body.put("expireAt", team.getExpireAt());
        body.put("orderId", orderId);
        body.put("order", tradeService.order(orderId));
        return body;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
