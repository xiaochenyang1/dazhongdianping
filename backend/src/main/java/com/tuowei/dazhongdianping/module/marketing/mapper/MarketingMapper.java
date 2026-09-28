package com.tuowei.dazhongdianping.module.marketing.mapper;

import com.tuowei.dazhongdianping.module.marketing.model.CouponTemplateRow;
import com.tuowei.dazhongdianping.module.marketing.model.UserCouponRow;
import java.time.LocalDateTime;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface MarketingMapper {

    // ---- 优惠券模板（运营端 + 领券中心） ----
    List<CouponTemplateRow> selectTemplates(
            @Param("region") String region,
            @Param("status") Integer status,
            @Param("limit") int limit,
            @Param("offset") int offset);

    long countTemplates(@Param("region") String region, @Param("status") Integer status);

    /** 领券中心：当前可领取（上架 + 在领取时间窗内）。 */
    List<CouponTemplateRow> selectClaimableTemplates(
            @Param("region") String region,
            @Param("now") LocalDateTime now);

    CouponTemplateRow selectTemplate(@Param("id") Long id, @Param("region") String region);

    void insertTemplate(CouponTemplateRow row);

    int updateTemplate(CouponTemplateRow row);

    /** 原子领券：仅当未限量或未发完时 +1，返回受影响行数。 */
    int incrementClaimed(@Param("id") Long id);

    // ---- 用户券 ----
    int countUserCouponsOfTemplate(@Param("userId") Long userId, @Param("templateId") Long templateId);

    /**
     * 原子领券插入：仅当该用户已持有的同模板券数 &lt; perUserLimit 时才插入,返回受影响行数(0/1)。
     * 用 COUNT 守卫的 INSERT ... SELECT 把「校验+插入」并成单条语句,配合
     * {@link #incrementClaimed} 对模板行的写锁串行化,杜绝并发超领。
     */
    int insertUserCouponIfUnderLimit(@Param("row") UserCouponRow row, @Param("perUserLimit") int perUserLimit);

    List<UserCouponRow> selectUserCoupons(
            @Param("userId") Long userId,
            @Param("region") String region,
            @Param("status") Integer status,
            @Param("limit") int limit,
            @Param("offset") int offset);

    long countUserCoupons(
            @Param("userId") Long userId,
            @Param("region") String region,
            @Param("status") Integer status);

    /** 下单可用券：未使用、未过期、门槛不超过金额、商户匹配。 */
    List<UserCouponRow> selectUsableCoupons(
            @Param("userId") Long userId,
            @Param("region") String region,
            @Param("shopId") Long shopId,
            @Param("amount") java.math.BigDecimal amount,
            @Param("now") LocalDateTime now);

    UserCouponRow selectUserCoupon(
            @Param("id") Long id,
            @Param("userId") Long userId,
            @Param("region") String region);

    /** 锁券：仅当当前未使用时置为已用，返回受影响行数。 */
    int markCouponUsed(
            @Param("id") Long id,
            @Param("userId") Long userId,
            @Param("usedAt") LocalDateTime usedAt);

    /** 锁定后回填订单 id（不校验状态，仅在下单事务内配合 markCouponUsed 使用）。 */
    int bindCouponOrderId(@Param("id") Long id, @Param("orderId") Long orderId);

    /** 订单未成交时释放券（回退到未使用）。 */
    int releaseCouponForOrder(@Param("orderId") Long orderId);

    /** 批量把过期未用券置为已过期。 */
    int expireDueUserCoupons(@Param("now") LocalDateTime now);
}
