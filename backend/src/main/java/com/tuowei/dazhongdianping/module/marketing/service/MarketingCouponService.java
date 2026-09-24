package com.tuowei.dazhongdianping.module.marketing.service;

import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.marketing.mapper.MarketingMapper;
import com.tuowei.dazhongdianping.module.marketing.model.CouponTemplateRow;
import com.tuowei.dazhongdianping.module.marketing.model.UserCouponRow;
import com.tuowei.dazhongdianping.module.marketing.model.response.CouponCenterItemResponse;
import com.tuowei.dazhongdianping.module.marketing.model.response.UserCouponResponse;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** C端营销券：领券中心、领券、我的券、下单可用券。 */
@Service
public class MarketingCouponService {

    private final MarketingMapper mapper;

    public MarketingCouponService(MarketingMapper mapper) {
        this.mapper = mapper;
    }

    /** 领券中心：列出当前区域可领取的券，并附带当前用户领取状态（未登录则按可领展示）。 */
    public List<CouponCenterItemResponse> couponCenter() {
        String region = region();
        UserSession u = UserSessionContext.get();
        List<CouponTemplateRow> templates = mapper.selectClaimableTemplates(region, LocalDateTime.now());
        return templates.stream().map(t -> {
            boolean soldOut = t.getTotalQuantity() != null && t.getTotalQuantity() > 0
                    && t.getClaimedQuantity() != null && t.getClaimedQuantity() >= t.getTotalQuantity();
            boolean claimed = false;
            if (u != null) {
                int owned = mapper.countUserCouponsOfTemplate(u.userId(), t.getId());
                claimed = owned >= (t.getPerUserLimit() == null ? 1 : t.getPerUserLimit());
            }
            boolean claimable = !soldOut && !claimed;
            return new CouponCenterItemResponse(
                    t.getId(), t.getName(), t.getType(), typeText(t.getType()),
                    t.getThresholdAmount(), t.getDiscountAmount(), t.getCurrency(), t.getShopId(),
                    t.getPerUserLimit(), t.getValidDays(), claimed, soldOut, claimable);
        }).toList();
    }

    /** 领取一张券。 */
    @Transactional
    public UserCouponResponse claim(Long templateId) {
        UserSession u = requireUser();
        String region = region();
        CouponTemplateRow t = mapper.selectTemplate(templateId, region);
        if (t == null || t.getStatus() == null || t.getStatus() != 1
                || t.getAuditStatus() == null || t.getAuditStatus() != 2) {
            throw new NotFoundException("优惠券不存在或已下架");
        }
        LocalDateTime now = LocalDateTime.now();
        if (t.getClaimStart() != null && t.getClaimStart().isAfter(now)) {
            throw new ConflictException("领券活动尚未开始");
        }
        if (t.getClaimEnd() != null && t.getClaimEnd().isBefore(now)) {
            throw new ConflictException("领券活动已结束");
        }
        int perUserLimit = t.getPerUserLimit() == null ? 1 : t.getPerUserLimit();
        int owned = mapper.countUserCouponsOfTemplate(u.userId(), templateId);
        if (owned >= perUserLimit) {
            throw new ConflictException("已达到每人限领数量");
        }
        // 原子扣减发放量：限量券抢光时返回 0。
        if (mapper.incrementClaimed(templateId) == 0) {
            throw new ConflictException("优惠券已被领完");
        }
        UserCouponRow row = new UserCouponRow();
        row.setTemplateId(templateId);
        row.setUserId(u.userId());
        row.setRegion(region);
        row.setType(t.getType());
        row.setThresholdAmount(t.getThresholdAmount());
        row.setDiscountAmount(t.getDiscountAmount());
        row.setCurrency(t.getCurrency());
        row.setShopId(t.getShopId());
        row.setExpireAt(now.plusDays(t.getValidDays() == null ? 7 : t.getValidDays()));
        mapper.insertUserCoupon(row);
        row.setTemplateName(t.getName());
        row.setStatus(1);
        return toUserCoupon(row);
    }

    /** 我的营销券钱包。 */
    public PageResult<UserCouponResponse> myCoupons(Integer status, Integer page, Integer pageSize) {
        UserSession u = requireUser();
        String region = region();
        mapper.expireDueUserCoupons(LocalDateTime.now());
        int p = page == null ? 1 : Math.max(1, page);
        int s = pageSize == null ? 12 : Math.min(50, Math.max(1, pageSize));
        long total = mapper.countUserCoupons(u.userId(), region, status);
        List<UserCouponResponse> list = mapper.selectUserCoupons(u.userId(), region, status, s, (p - 1) * s)
                .stream().map(this::toUserCoupon).toList();
        return new PageResult<>(list, total, p, s, (p - 1) * s + list.size() < total);
    }

    /** 下单前查询某笔订单金额下可用的券。 */
    public List<UserCouponResponse> usableForOrder(Long shopId, java.math.BigDecimal amount) {
        UserSession u = requireUser();
        if (shopId == null || amount == null) {
            return List.of();
        }
        mapper.expireDueUserCoupons(LocalDateTime.now());
        return mapper.selectUsableCoupons(u.userId(), region(), shopId, amount, LocalDateTime.now())
                .stream().map(this::toUserCoupon).toList();
    }

    /**
     * 下单时锁券并计算抵扣（在 trade 的下单事务内调用）。
     * 校验归属/区域/未使用/未过期/门槛/商户匹配，满足则原子置为已用并绑定订单。
     * 抵扣金额封顶为订单金额（不产生负数订单）。
     */
    @Transactional
    public CouponDiscount applyForOrder(Long userId, Long userCouponId, Long shopId,
                                        java.math.BigDecimal orderAmount) {
        if (userCouponId == null) {
            return CouponDiscount.none();
        }
        String region = region();
        UserCouponRow c = mapper.selectUserCoupon(userCouponId, userId, region);
        if (c == null) {
            throw new NotFoundException("优惠券不存在");
        }
        if (c.getStatus() == null || c.getStatus() != 1) {
            throw new ConflictException("优惠券不可用");
        }
        if (c.getExpireAt() != null && c.getExpireAt().isBefore(LocalDateTime.now())) {
            throw new ConflictException("优惠券已过期");
        }
        if (c.getShopId() != null && c.getShopId() != 0 && !c.getShopId().equals(shopId)) {
            throw new ConflictException("优惠券不适用于该商户");
        }
        if (c.getThresholdAmount() != null && orderAmount.compareTo(c.getThresholdAmount()) < 0) {
            throw new ConflictException("订单未达到优惠券使用门槛");
        }
        // 锁券：并发下同一张券只会成功一次。
        if (mapper.markCouponUsed(userCouponId, userId, LocalDateTime.now()) == 0) {
            throw new ConflictException("优惠券已被使用");
        }
        java.math.BigDecimal discount = c.getDiscountAmount() == null ? BigDecimal.ZERO : c.getDiscountAmount();
        if (discount.compareTo(orderAmount) > 0) {
            discount = orderAmount;
        }
        return new CouponDiscount(userCouponId, discount.setScale(2));
    }

    /** 用券后回填订单 id（下单事务内，插入订单拿到 id 后调用）。 */
    @Transactional
    public void bindCouponToOrder(Long userCouponId, Long orderId) {
        if (userCouponId == null || orderId == null) {
            return;
        }
        mapper.bindCouponOrderId(userCouponId, orderId);
    }

    /** 订单未成交（取消/超时关单）时释放已锁定的券。 */
    @Transactional
    public void releaseForOrder(Long orderId) {
        if (orderId != null) {
            mapper.releaseCouponForOrder(orderId);
        }
    }

    private UserCouponResponse toUserCoupon(UserCouponRow r) {
        return new UserCouponResponse(
                r.getId(), r.getTemplateId(),
                r.getTemplateName() == null ? "" : r.getTemplateName(),
                r.getType(), typeText(r.getType()),
                r.getThresholdAmount(), r.getDiscountAmount(), r.getCurrency(), r.getShopId(),
                r.getStatus(), statusText(r.getStatus()), r.getExpireAt(), r.getUsedAt());
    }

    private String typeText(Integer type) {
        return type != null && type == 2 ? "新客立减" : "满减券";
    }

    private String statusText(Integer status) {
        if (status == null) {
            return "未使用";
        }
        return switch (status) {
            case 2 -> "已使用";
            case 3 -> "已过期";
            default -> "未使用";
        };
    }

    private UserSession requireUser() {
        UserSession u = UserSessionContext.get();
        if (u == null) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        return u;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
