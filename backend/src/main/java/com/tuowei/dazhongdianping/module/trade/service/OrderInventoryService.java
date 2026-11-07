package com.tuowei.dazhongdianping.module.trade.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.module.auth.mapper.AuthCommandMapper;
import com.tuowei.dazhongdianping.module.marketing.mapper.MarketingCampaignMapper;
import com.tuowei.dazhongdianping.module.marketing.service.MarketingCouponService;
import com.tuowei.dazhongdianping.module.trade.mapper.TradeMapper;
import com.tuowei.dazhongdianping.module.trade.model.OrderRow;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/** Account -> order -> campaign -> deal. All stock returns participate in the caller's transaction. */
@Service
@Transactional(propagation = Propagation.MANDATORY)
public class OrderInventoryService {
    private final TradeMapper trades;
    private final MarketingCampaignMapper campaigns;
    private final AuthCommandMapper accounts;
    private final MarketingCouponService coupons;

    public OrderInventoryService(TradeMapper trades, MarketingCampaignMapper campaigns,
            AuthCommandMapper accounts, MarketingCouponService coupons) {
        this.trades = trades;
        this.campaigns = campaigns;
        this.accounts = accounts;
        this.coupons = coupons;
    }

    public OrderRow lockOrder(Long id) {
        OrderRow display = trades.selectOrderById(id);
        if (display == null) throw new NotFoundException("订单不存在");
        accounts.selectUserByIdForUpdate(display.getUserId());
        // Lock only the order, not joined shop/deal rows. A locking read also avoids
        // stale REPEATABLE READ snapshots when a callback has just won the race.
        OrderRow order = trades.selectOrderForUpdate(id);
        if (order == null) throw new NotFoundException("订单不存在");
        order.setDealTitle(order.getDealTitleSnapshot() == null || order.getDealTitleSnapshot().isBlank()
                ? display.getDealTitle() : order.getDealTitleSnapshot());
        order.setShopName(display.getShopName());
        order.setCoverImage(display.getCoverImage());
        return order;
    }

    public boolean closeUnpaid(OrderRow order) {
        if (trades.closeOrder(order.getId(), order.getUserId()) != 1) return false;
        release(order);
        coupons.releaseForOrder(order.getId());
        order.setStatus(2);
        return true;
    }

    public void release(OrderRow order) {
        if (trades.markInventoryReleased(order.getId()) != 1) return;
        if (isSeckill(order)) {
            if (campaigns.releaseSeckillStock(order.getCampaignId(), order.getQuantity()) != 1) {
                throw new IllegalStateException("秒杀库存恢复失败");
            }
            // A cancelled attempt may already have been replaced by a new order.
            campaigns.releaseSeckillClaim(order.getId(), Integer.valueOf(0).equals(order.getPayStatus()) ? 3 : 4);
        }
        if (trades.restoreDealStock(order.getDealId(), order.getQuantity()) != 1) {
            throw new IllegalStateException("订单库存恢复失败");
        }
        order.setInventoryReleased(true);
    }

    public void markPaid(OrderRow order) {
        if (isSeckill(order) && campaigns.markSeckillClaimPaid(order.getId()) != 1) {
            throw new IllegalStateException("秒杀订单名额状态不一致");
        }
    }

    public static boolean isSeckill(OrderRow order) {
        return "seckill".equals(order.getOrderSource()) && order.getCampaignId() != null;
    }
}
