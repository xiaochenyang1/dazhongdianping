package com.tuowei.dazhongdianping.module.marketing.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.auth.mapper.AuthCommandMapper;
import com.tuowei.dazhongdianping.module.launch.LaunchPolicy;
import com.tuowei.dazhongdianping.module.marketing.mapper.MarketingCampaignMapper;
import com.tuowei.dazhongdianping.module.marketing.model.SeckillClaimRow;
import com.tuowei.dazhongdianping.module.marketing.model.SeckillEventRow;
import com.tuowei.dazhongdianping.module.trade.mapper.TradeMapper;
import com.tuowei.dazhongdianping.module.trade.model.DealRow;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import com.tuowei.dazhongdianping.module.trade.service.OrderInventoryService;
import com.tuowei.dazhongdianping.module.trade.service.TradeService;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class SeckillOrderService {
    private final MarketingCampaignMapper campaigns;
    private final TradeMapper trades;
    private final AuthCommandMapper accounts;
    private final OrderInventoryService inventory;
    private final TradeService tradeService;
    private final LaunchPolicy launch;

    public SeckillOrderService(MarketingCampaignMapper campaigns, TradeMapper trades,
            AuthCommandMapper accounts, OrderInventoryService inventory, TradeService tradeService, LaunchPolicy launch) {
        this.campaigns = campaigns;
        this.trades = trades;
        this.accounts = accounts;
        this.inventory = inventory;
        this.tradeService = tradeService;
        this.launch = launch;
    }

    @Transactional
    public Map<String, Object> create(Long eventId) {
        launch.require(LaunchPolicy.Feature.SECKILL);
        var session = UserSessionContext.get();
        if (session == null) throw new UnauthorizedException("用户登录状态不存在");
        var account = accounts.selectUserByIdForUpdate(session.userId());
        if (account == null || !Integer.valueOf(1).equals(account.getStatus())) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        String region = RegionContext.getRegion().name();
        SeckillClaimRow claim = campaigns.selectSeckillClaim(eventId, session.userId());
        if (claim != null && !region.equals(claim.getRegion())) throw new NotFoundException("秒杀活动不存在");
        if (claim != null && claim.getStatus() != 3) {
            if (claim.getOrderId() == null) throw new IllegalArgumentException("已参与过该秒杀");
            OrderRow existing = inventory.lockOrder(claim.getOrderId());
            if (claim.getStatus() == 1 && expired(existing)) inventory.closeUnpaid(existing);
            // Retry always returns the same purchase result. Once an expired order
            // is closed, a subsequent deliberate purchase may reserve a new one.
            return result(eventId, region, claim.getId(), existing.getId());
        }

        SeckillEventRow event = campaigns.selectSeckillForUpdate(eventId, region);
        if (event == null || !Integer.valueOf(2).equals(event.getAuditStatus())
                || !Integer.valueOf(1).equals(event.getStatus())) throw new NotFoundException("秒杀活动不存在");
        LocalDateTime now = LocalDateTime.now();
        if (now.isBefore(event.getStartAt()) || !now.isBefore(event.getEndAt())) {
            throw new IllegalArgumentException("不在秒杀活动时间内");
        }
        DealRow deal = trades.selectDealForUpdate(event.getDealId(), region);
        if (deal == null || !event.getShopId().equals(deal.getShopId())
                || !event.getMerchantId().equals(deal.getMerchantId())
                || !event.getCurrency().equals(deal.getCurrency())
                || deal.getValidEnd() != null && deal.getValidEnd().isBefore(LocalDate.now())) {
            throw new IllegalArgumentException("秒杀套餐已失效");
        }
        if (event.getSeckillPrice().compareTo(BigDecimal.ZERO) <= 0
                || event.getSeckillPrice().compareTo(deal.getPrice()) > 0) {
            throw new IllegalArgumentException("秒杀价格已失效");
        }
        // Both limits are reserved in one transaction, including ordinary deal sales.
        if (campaigns.incrementSeckillSold(eventId, region, now) != 1) {
            throw new IllegalArgumentException("秒杀已售罄");
        }
        if (trades.decrementDealStock(deal.getId(), 1) != 1) throw new IllegalArgumentException("团购库存不足");

        OrderRow order = new OrderRow();
        order.setOrderNo("OD" + UUID.randomUUID().toString().replace("-", "").substring(0, 30));
        order.setUserId(session.userId());
        order.setDealId(deal.getId());
        order.setShopId(deal.getShopId());
        order.setRegion(region);
        order.setQuantity(1);
        order.setOrderSource("seckill");
        order.setCampaignId(eventId);
        order.setCampaignTitle(event.getTitle());
        order.setDealTitleSnapshot(deal.getTitle());
        order.setCouponValidEnd(deal.getValidEnd());
        order.setUnitPrice(event.getSeckillPrice());
        order.setOriginalAmount(deal.getPrice());
        order.setDiscountAmount(deal.getPrice().subtract(event.getSeckillPrice()));
        order.setAmount(event.getSeckillPrice());
        order.setCurrency(event.getCurrency());
        LocalDateTime deadline = now.plusMinutes(15);
        if (event.getEndAt().isBefore(deadline)) deadline = event.getEndAt();
        if (deal.getValidEnd() != null && deal.getValidEnd().plusDays(1).atStartOfDay().isBefore(deadline)) {
            deadline = deal.getValidEnd().plusDays(1).atStartOfDay();
        }
        order.setExpireAt(deadline);
        trades.insertOrder(order);

        if (claim == null) {
            claim = new SeckillClaimRow();
            claim.setEventId(eventId);
            claim.setUserId(session.userId());
            claim.setRegion(region);
            claim.setOrderId(order.getId());
            campaigns.insertSeckillClaim(claim);
        } else {
            claim.setOrderId(order.getId());
            if (campaigns.reserveSeckillClaim(claim) != 1) throw new IllegalStateException("秒杀名额锁定失败");
        }
        return result(eventId, region, claim.getId(), order.getId());
    }

    private boolean expired(OrderRow order) {
        return Integer.valueOf(0).equals(order.getPayStatus()) && Integer.valueOf(1).equals(order.getStatus())
                && order.getExpireAt() != null && !order.getExpireAt().isAfter(LocalDateTime.now());
    }

    private Map<String, Object> result(Long eventId, String region, Long claimId, Long orderId) {
        SeckillEventRow event = campaigns.selectSeckill(eventId, region);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("id", eventId);
        body.put("claimId", claimId);
        body.put("sold", event == null ? null : event.getSold());
        body.put("orderId", orderId);
        body.put("order", tradeService.order(orderId));
        return body;
    }
}
