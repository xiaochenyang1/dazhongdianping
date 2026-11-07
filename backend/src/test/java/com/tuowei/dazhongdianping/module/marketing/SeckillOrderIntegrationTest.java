package com.tuowei.dazhongdianping.module.marketing;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doCallRealMethod;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.ServiceUnavailableException;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.admin.AdminCityScope;
import com.tuowei.dazhongdianping.module.admin.trade.model.request.AdminRefundAuditRequest;
import com.tuowei.dazhongdianping.module.admin.trade.service.AdminTradeService;
import com.tuowei.dazhongdianping.module.auth.mapper.UserPrivacyDomainMapper;
import com.tuowei.dazhongdianping.module.marketing.mapper.MarketingCampaignMapper;
import com.tuowei.dazhongdianping.module.marketing.model.SeckillEventRow;
import com.tuowei.dazhongdianping.module.marketing.service.MarketingCampaignService;
import com.tuowei.dazhongdianping.module.marketing.service.SeckillOrderService;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSessionContext;
import com.tuowei.dazhongdianping.module.merchant.service.MerchantFulfillmentService;
import com.tuowei.dazhongdianping.module.merchant.trade.model.request.MerchantRefundAuditRequest;
import com.tuowei.dazhongdianping.module.merchant.trade.service.MerchantTradeService;
import com.tuowei.dazhongdianping.module.trade.model.request.OrderCreateRequest;
import com.tuowei.dazhongdianping.module.trade.model.request.RefundRequest;
import com.tuowei.dazhongdianping.module.trade.payment.MockPaymentChannel;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentNotifyResult;
import com.tuowei.dazhongdianping.module.trade.payment.RefundChannelState;
import com.tuowei.dazhongdianping.module.trade.payment.RefundResult;
import com.tuowei.dazhongdianping.module.trade.service.TradeCompensationService;
import com.tuowei.dazhongdianping.module.trade.service.TradeService;
import com.tuowei.dazhongdianping.module.trade.scheduler.TradeCompensationScheduler;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Supplier;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

/** Committed fixtures are intentional: races run in independent, real transactions. */
@SpringBootTest(properties = {"app.launch.deferred-features-enabled=true", "app.launch.eu.seckill-enabled=true"})
class SeckillOrderIntegrationTest {
    private static final AtomicLong IDS = new AtomicLong(700_000);
    @Autowired JdbcTemplate jdbc;
    @Autowired SeckillOrderService seckill;
    @Autowired MarketingCampaignService campaigns;
    @Autowired MarketingCampaignMapper campaignMapper;
    @Autowired TradeService trade;
    @Autowired TradeCompensationService compensation;
    @Autowired MerchantTradeService merchantTrade;
    @Autowired AdminTradeService adminTrade;
    @Autowired MerchantFulfillmentService fulfillment;
    @Autowired UserPrivacyDomainMapper privacy;
    @Autowired PlatformTransactionManager transactions;
    @SpyBean MockPaymentChannel channel;
    // Reconciliation is invoked explicitly so its scheduler cannot consume fixtures.
    @MockBean TradeCompensationScheduler compensationScheduler;

    @BeforeEach void prepare() { reset(channel); }
    @AfterEach void clear() {
        UserSessionContext.clear(); RegionContext.clear();
        MerchantSessionContext.clear(); AdminSessionContext.clear();
    }

    @ParameterizedTest @ValueSource(strings = {"CN", "EU"})
    void freezesPriceSourceAndValidityAndIssuesOneCouponOnlyAfterPayment(String region) {
        Fixture f = fixture(region, 2, 3);
        long user = user();
        Map<String, Object> first = as(user, region, () -> seckill.create(f.event));
        long id = id(first);
        assertThat(as(user, region, () -> seckill.create(f.event)).get("orderId")).isEqualTo(id);
        assertThat(count("SELECT COUNT(*) FROM `order` WHERE campaign_id=?", f.event)).isEqualTo(1);
        assertThat(count("SELECT COUNT(*) FROM coupon WHERE order_id=?", id)).isZero();
        Map<String, Object> intent = as(user, region, () -> trade.pay(id));
        assertThat(intent.get("amount")).isEqualTo(new BigDecimal("9.90"));
        assertThat(intent.get("currency")).isEqualTo(region.equals("CN") ? "CNY" : "EUR");
        jdbc.update("UPDATE seckill_event SET title='Changed event',seckill_price=12,status=0 WHERE id=?", f.event);
        jdbc.update("UPDATE deal SET title='Changed deal',price=99,valid_end=?,status=0 WHERE id=?", LocalDate.now().plusDays(2), f.deal);
        assertThat(notify(intent).get("processed")).isEqualTo(true);
        assertThat(notify(intent).get("processed")).isEqualTo(false);
        Map<String, Object> order = as(user, region, () -> trade.order(id));
        assertThat(order).containsEntry("orderSource", "seckill").containsEntry("campaignId", f.event)
                .containsEntry("campaignTitle", "Flash sale").containsEntry("dealTitle", "Original deal")
                .containsEntry("payStatus", 1).containsEntry("amount", new BigDecimal("9.90"));
        assertThat(count("SELECT COUNT(*) FROM coupon WHERE order_id=?", id)).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT expire_at FROM coupon WHERE order_id=?", LocalDate.class, id)).isEqualTo(f.validEnd);
        assertThat(count("SELECT status FROM seckill_claim WHERE order_id=?", id)).isEqualTo(2);
        assertThat(stock(f)).isEqualTo(2);
    }

    @Test void cancelledAttemptCanBeReorderedAndItsLatePaymentCannotReleaseTheNewReservation() {
        Fixture f = fixture("CN", 1, 1); long user = user();
        long old = as(user, f.region, () -> id(seckill.create(f.event)));
        Map<String, Object> intent = as(user, f.region, () -> trade.pay(old));
        as(user, f.region, () -> trade.cancel(old));
        assertThat(sold(f)).isZero(); assertThat(stock(f)).isEqualTo(1);
        assertThatThrownBy(() -> as(user, f.region, () -> trade.cancel(old))).isInstanceOf(IllegalArgumentException.class);
        long current = as(user, f.region, () -> id(seckill.create(f.event)));
        assertThat(current).isNotEqualTo(old);
        notify(intent); notify(intent);
        assertThat(count("SELECT pay_status FROM `order` WHERE id=?", old)).isEqualTo(2);
        assertThat(count("SELECT status FROM refund WHERE order_id=?", old)).isEqualTo(1);
        assertThat(count("SELECT COUNT(*) FROM coupon WHERE order_id=?", old)).isZero();
        assertThat(count("SELECT order_id FROM seckill_claim WHERE event_id=?", f.event)).isEqualTo(current);
        assertThat(count("SELECT status FROM seckill_claim WHERE event_id=?", f.event)).isEqualTo(1);
        assertThat(sold(f)).isEqualTo(1); assertThat(stock(f)).isZero();
    }

    @Test void ordersAtTheirDeadlineRejectPaymentAndCompensationReleasesBothStocksExactlyOnce() {
        Fixture f = fixture("CN", 1, 1); long user = user();
        long id = as(user, f.region, () -> id(seckill.create(f.event)));
        Map<String, Object> intent = as(user, f.region, () -> trade.pay(id));
        jdbc.update("UPDATE `order` SET expire_at=CURRENT_TIMESTAMP WHERE id=?", id);
        assertThatThrownBy(() -> as(user, f.region, () -> trade.pay(id))).hasMessageContaining("超时");
        assertThat(compensation.reconcile().closedOrders())
                .as("Expired order at application time %s: %s", LocalDateTime.now(), jdbc.queryForMap(
                        "SELECT status,pay_status,expire_at,CURRENT_TIMESTAMP AS db_now FROM `order` WHERE id=?", id))
                .isEqualTo(1);
        assertThat(compensation.reconcile().closedOrders()).isZero();
        assertThat(sold(f)).isZero(); assertThat(stock(f)).isEqualTo(1);
        // A locally timed-out payment can still be captured by the external channel.
        assertThat(count("SELECT status FROM payment WHERE order_id=?", id)).isEqualTo(2);
        notify(intent);
        assertThat(count("SELECT status FROM payment WHERE order_id=?", id)).isEqualTo(1);
        assertThat(count("SELECT status FROM refund WHERE order_id=?", id)).isEqualTo(1);
        assertThat(sold(f)).isZero(); assertThat(stock(f)).isEqualTo(1);
    }

    @Test void latePaymentClosesAnExpiredReservationEvenBeforeTheSchedulerRuns() {
        Fixture f = fixture("EU", 1, 1); long user = user();
        long id = as(user, f.region, () -> id(seckill.create(f.event)));
        Map<String, Object> intent = as(user, f.region, () -> trade.pay(id));
        jdbc.update("UPDATE `order` SET expire_at=? WHERE id=?", LocalDateTime.now().minusSeconds(1), id);
        notify(intent);
        assertThat(count("SELECT status FROM `order` WHERE id=?", id)).isEqualTo(2);
        assertThat(count("SELECT pay_status FROM `order` WHERE id=?", id)).isEqualTo(2);
        assertThat(count("SELECT COUNT(*) FROM coupon WHERE order_id=?", id)).isZero();
        assertThat(sold(f)).isZero(); assertThat(stock(f)).isEqualTo(1);
    }

    @ParameterizedTest @ValueSource(booleans = {false, true})
    void merchantAndAdminRefundsReleaseStockButRetainTheSuccessfulPurchaseLimit(boolean platform) {
        Fixture f = fixture("CN", 1, 1); long user = user();
        long id = as(user, f.region, () -> id(seckill.create(f.event)));
        as(user, f.region, () -> trade.completeMockPayment(id));
        String code = jdbc.queryForObject("SELECT code FROM coupon WHERE order_id=?", String.class, id);
        as(user, f.region, () -> trade.refund(id, new RefundRequest("Plans changed")));
        merchant();
        assertThatThrownBy(() -> fulfillment.verifyCoupon(code)).hasMessageContaining("退款处理中");
        if (platform) {
            admin(); adminTrade.auditRefund(id, new AdminRefundAuditRequest("approve", "Approved"), "127.0.0.1");
        } else merchantTrade.auditRefund(id, new MerchantRefundAuditRequest("approve", "Approved"));
        assertThat(count("SELECT status FROM seckill_claim WHERE order_id=?", id)).isEqualTo(4);
        assertThat(count("SELECT pay_status FROM `order` WHERE id=?", id)).isEqualTo(2);
        assertThat(sold(f)).isZero(); assertThat(stock(f)).isEqualTo(1);
        assertThat(as(user, f.region, () -> id(seckill.create(f.event)))).isEqualTo(id);
        assertThat(count("SELECT COUNT(*) FROM `order` WHERE campaign_id=?", f.event)).isEqualTo(1);
        assertThatThrownBy(() -> fulfillment.verifyCoupon(code)).isInstanceOf(IllegalArgumentException.class);
    }

    @Test void issuedCouponUsesTheExistingRedemptionFlowAndCannotBeRefundedAfterUse() {
        Fixture f = fixture("CN", 1, 1); long user = user();
        long id = as(user, f.region, () -> id(seckill.create(f.event)));
        as(user, f.region, () -> trade.completeMockPayment(id));
        String code = jdbc.queryForObject("SELECT code FROM coupon WHERE order_id=?", String.class, id);
        merchant(); fulfillment.verifyCoupon(code);
        assertThatThrownBy(() -> as(user, f.region, () -> trade.refund(id, new RefundRequest("Refund"))))
                .hasMessageContaining("已核销");
        assertThat(sold(f)).isEqualTo(1); assertThat(stock(f)).isZero();
    }

    @Test void lostRefundResponseIsPersistedAndRetriedWithTheSameChannelIdempotencyKey() {
        Fixture f = fixture("CN", 1, 1); long user = user();
        long id = as(user, f.region, () -> id(seckill.create(f.event)));
        Map<String, Object> intent = as(user, f.region, () -> trade.pay(id));
        as(user, f.region, () -> trade.cancel(id));
        doThrow(new ServiceUnavailableException("Connection lost")).when(channel).refund(any(), any(), anyString(), anyString());
        notify(intent);
        assertThat(count("SELECT status FROM refund WHERE order_id=?", id)).isEqualTo(3);
        assertThat(count("SELECT pay_status FROM `order` WHERE id=?", id)).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT channel_refund_txn FROM refund WHERE order_id=?", String.class, id)).isEmpty();
        doCallRealMethod().when(channel).refund(any(), any(), anyString(), anyString());
        assertThat(compensation.reconcile().reconciledRefunds()).isEqualTo(1);
        ArgumentCaptor<String> keys = ArgumentCaptor.forClass(String.class);
        verify(channel, times(2)).refund(any(), any(), anyString(), keys.capture());
        assertThat(keys.getAllValues()).containsOnly("late-order-refund-" + intent.get("orderNo"));
        assertThat(count("SELECT status FROM refund WHERE order_id=?", id)).isEqualTo(1);
        assertThat(sold(f)).isZero(); assertThat(stock(f)).isEqualTo(1);
    }

    @Test void asynchronousRefundIsReconciledWithoutReturningStockTwice() {
        Fixture f = fixture("EU", 1, 1); long user = user();
        long id = as(user, f.region, () -> id(seckill.create(f.event)));
        Map<String, Object> intent = as(user, f.region, () -> trade.pay(id));
        as(user, f.region, () -> trade.cancel(id));
        doReturn(new RefundResult("stripe_mock", "pending_" + id, new BigDecimal("9.90"), RefundChannelState.PENDING, ""))
                .when(channel).refund(any(), any(), anyString(), anyString());
        notify(intent);
        assertThat(count("SELECT status FROM refund WHERE order_id=?", id)).isEqualTo(3);
        assertThat(compensation.reconcile().reconciledRefunds()).isEqualTo(1);
        assertThat(compensation.reconcile().reconciledRefunds()).isZero();
        assertThat(count("SELECT pay_status FROM `order` WHERE id=?", id)).isEqualTo(2);
        assertThat(sold(f)).isZero(); assertThat(stock(f)).isEqualTo(1);
    }

    @Test void concurrentBuyersCannotExceedEitherCampaignOrDealStock() throws Exception {
        for (int campaignStock : List.of(2, 8)) {
            Fixture f = fixture("CN", campaignStock, 3);
            List<Callable<Long>> buyers = new ArrayList<>();
            for (int i = 0; i < 10; i++) {
                long user = user();
                buyers.add(() -> as(user, f.region, () -> {
                    try { return id(seckill.create(f.event)); }
                    catch (IllegalArgumentException soldOut) { return 0L; }
                }));
            }
            List<Long> results = race(buyers);
            int purchased = Math.min(campaignStock, 3);
            assertThat(results.stream().filter(id -> id > 0).count()).isEqualTo(purchased);
            assertThat(count("SELECT COUNT(*) FROM `order` WHERE campaign_id=?", f.event)).isEqualTo(purchased);
            assertThat(count("SELECT COUNT(*) FROM seckill_claim WHERE event_id=?", f.event)).isEqualTo(purchased);
            assertThat(sold(f)).isEqualTo(purchased); assertThat(stock(f)).isEqualTo(3 - purchased);
        }
    }

    @Test void simultaneousRetriesShareOneOrderOnePaymentAndOneCoupon() throws Exception {
        Fixture f = fixture("CN", 8, 8); long user = user();
        List<Callable<Long>> requests = new ArrayList<>();
        for (int i = 0; i < 8; i++) requests.add(() -> as(user, f.region, () -> id(seckill.create(f.event))));
        List<Long> ids = race(requests); long id = ids.get(0);
        assertThat(ids).containsOnly(id);
        List<Callable<String>> payments = new ArrayList<>();
        for (int i = 0; i < 8; i++) payments.add(() -> as(user, f.region, () -> (String) trade.pay(id).get("channelTxn")));
        List<String> intents = race(payments);
        assertThat(intents).containsOnly(intents.get(0));
        Map<String, Object> intent = as(user, f.region, () -> trade.pay(id));
        List<Callable<Boolean>> callbacks = new ArrayList<>();
        for (int i = 0; i < 8; i++) callbacks.add(() -> (Boolean) notify(intent).get("processed"));
        assertThat(race(callbacks).stream().filter(Boolean::booleanValue).count()).isEqualTo(1);
        assertThat(count("SELECT COUNT(*) FROM payment WHERE order_id=?", id)).isEqualTo(1);
        assertThat(count("SELECT COUNT(*) FROM coupon WHERE order_id=?", id)).isEqualTo(1);
        assertThat(sold(f)).isEqualTo(1); assertThat(stock(f)).isEqualTo(7);
    }

    @Test void ordinaryAndFlashPurchasesShareTheLastUnitOfDealStock() throws Exception {
        Fixture f = fixture("CN", 2, 1); long first = user(), second = user();
        List<Boolean> results = race(List.of(
                () -> as(first, f.region, () -> tryPurchase(() -> seckill.create(f.event))),
                () -> as(second, f.region, () -> tryPurchase(() -> trade.createOrder(new OrderCreateRequest(f.deal, 1, null))))));
        assertThat(results.stream().filter(Boolean::booleanValue).count()).isEqualTo(1);
        assertThat(stock(f)).isZero();
        assertThat(count("SELECT COUNT(*) FROM `order` WHERE deal_id=?", f.deal)).isEqualTo(1);
        assertThat(sold(f)).isEqualTo(count("SELECT COUNT(*) FROM `order` WHERE campaign_id=?", f.event));
    }

    @Test void cancellationRacingPaymentEndsInEitherFulfillmentOrRefundWithConsistentStock() throws Exception {
        Fixture f = fixture("CN", 1, 1); long user = user();
        long id = as(user, f.region, () -> id(seckill.create(f.event)));
        Map<String, Object> intent = as(user, f.region, () -> trade.pay(id));
        race(List.of(() -> notify(intent), () -> as(user, f.region, () -> {
            try { return trade.cancel(id); } catch (IllegalArgumentException alreadyPaid) { return Map.of(); }
        })));
        long payStatus = count("SELECT pay_status FROM `order` WHERE id=?", id);
        assertThat(payStatus).isIn(1L, 2L);
        assertThat(sold(f)).isEqualTo(payStatus == 1 ? 1 : 0);
        assertThat(stock(f)).isEqualTo(payStatus == 1 ? 0 : 1);
        assertThat(count("SELECT COUNT(*) FROM coupon WHERE order_id=?", id)).isEqualTo(payStatus == 1 ? 1 : 0);
    }

    @Test void rejectsInvalidEventsAndCrossRegionAccessWithoutReservingAnything() {
        Fixture f = fixture("CN", 1, 1); long user = user();
        assertThatThrownBy(() -> as(user, "EU", () -> seckill.create(f.event))).isInstanceOf(NotFoundException.class);
        jdbc.update("UPDATE seckill_event SET audit_status=1 WHERE id=?", f.event);
        assertThatThrownBy(() -> as(user, f.region, () -> seckill.create(f.event))).isInstanceOf(NotFoundException.class);
        jdbc.update("UPDATE seckill_event SET audit_status=2,start_at=? WHERE id=?", LocalDateTime.now().plusMinutes(1), f.event);
        assertThatThrownBy(() -> as(user, f.region, () -> seckill.create(f.event))).hasMessageContaining("活动时间");
        jdbc.update("UPDATE seckill_event SET start_at=?,end_at=? WHERE id=?", LocalDateTime.now().minusHours(1), LocalDateTime.now().minusSeconds(1), f.event);
        assertThatThrownBy(() -> as(user, f.region, () -> seckill.create(f.event))).hasMessageContaining("活动时间");
        jdbc.update("UPDATE seckill_event SET end_at=?,currency='EUR' WHERE id=?", LocalDateTime.now().plusHours(1), f.event);
        assertThatThrownBy(() -> as(user, f.region, () -> seckill.create(f.event))).hasMessageContaining("套餐已失效");
        assertThat(sold(f)).isZero(); assertThat(stock(f)).isEqualTo(1);
        assertThat(count("SELECT COUNT(*) FROM `order` WHERE campaign_id=?", f.event)).isZero();
    }

    @Test void legacyClaimsDoNotMintOrdersAndPrivacyDeletionDoesNotReopenPaidInventory() {
        Fixture f = fixture("CN", 2, 2); long legacy = user(), buyer = user();
        jdbc.update("INSERT INTO seckill_claim(event_id,user_id,region) VALUES(?,?,'CN')", f.event, legacy);
        jdbc.update("UPDATE seckill_event SET sold=1 WHERE id=?", f.event);
        assertThatThrownBy(() -> as(legacy, f.region, () -> seckill.create(f.event))).hasMessageContaining("已参与");
        long id = as(buyer, f.region, () -> id(seckill.create(f.event)));
        as(buyer, f.region, () -> trade.completeMockPayment(id));
        new TransactionTemplate(transactions).executeWithoutResult(ignored -> {
            privacy.lockAffectedSeckillEvents(buyer); privacy.deleteSeckillClaims(buyer); privacy.refreshSeckillSold(f.event);
        });
        assertThat(sold(f)).isEqualTo(2); assertThat(stock(f)).isEqualTo(1);
        assertThat(count("SELECT COUNT(*) FROM `order` WHERE campaign_id=?", f.event)).isEqualTo(1);
    }

    private Fixture fixture(String region, int campaignStock, int dealStock) {
        long id = IDS.incrementAndGet(); LocalDate end = LocalDate.now().plusDays(30);
        long shop = region.equals("CN") ? 10001 : 20001, merchant = region.equals("CN") ? 1001 : 2001;
        String currency = region.equals("CN") ? "CNY" : "EUR";
        jdbc.update("INSERT INTO deal(id,shop_id,merchant_id,region,type,title,cover_image,price,original_price,currency,stock,sold_count,valid_start,valid_end,rules,audit_status,status) VALUES(?,?,?,?,1,'Original deal','',20,30,?,?,0,?,?,'Use in store',1,1)",
                id, shop, merchant, region, currency, dealStock, LocalDate.now(), end);
        SeckillEventRow event = new SeckillEventRow();
        event.setRegion(region);event.setShopId(shop);event.setMerchantId(merchant);event.setDealId(id);
        event.setTitle("Flash sale");event.setSeckillPrice(new BigDecimal("9.90"));event.setCurrency(currency);
        event.setStock(campaignStock);event.setStartAt(LocalDateTime.now().minusHours(1));event.setEndAt(LocalDateTime.now().plusHours(1));
        campaignMapper.insertSeckill(event);
        jdbc.update("UPDATE seckill_event SET audit_status=2 WHERE id=?", event.getId());
        return new Fixture(event.getId(), id, region, end);
    }
    private long user() {
        long id = IDS.incrementAndGet();
        jdbc.update("INSERT INTO app_user(id,nickname,email) VALUES(?,'Buyer',?)", id, UUID.randomUUID() + "@example.com");
        return id;
    }
    private <T> T as(long user, String region, Supplier<T> action) {
        UserSessionContext.set(new UserSession(user, 1L)); RegionContext.setRegion(Region.valueOf(region));
        try { return action.get(); } finally { UserSessionContext.clear(); RegionContext.clear(); }
    }
    private long id(Map<String, Object> result) { return ((Number) result.get("orderId")).longValue(); }
    private long count(String sql, Object... args) { return jdbc.queryForObject(sql, Long.class, args); }
    private long stock(Fixture f) { return count("SELECT stock FROM deal WHERE id=?", f.deal); }
    private long sold(Fixture f) { return count("SELECT sold FROM seckill_event WHERE id=?", f.event); }
    private Map<String, Object> notify(Map<String, Object> intent) {
        return trade.notifyInternal((String) intent.get("channel"), new PaymentNotifyResult((String) intent.get("orderNo"),
                (String) intent.get("channelTxn"), (BigDecimal) intent.get("amount"), true));
    }
    private boolean tryPurchase(Supplier<?> purchase) {
        try { purchase.get(); return true; } catch (IllegalArgumentException soldOut) { return false; }
    }
    private void merchant() {
        RegionContext.setRegion(Region.CN);
        MerchantSessionContext.set(new MerchantSession(12001L, 1001L, "merchant", 1, "CN"));
    }
    private void admin() {
        RegionContext.setRegion(Region.CN);
        AdminSessionContext.set(new AdminSession(1L,"admin","Admin",Set.of(),Set.of("CN"),
                Map.of("CN",new AdminCityScope(true,Set.of(),Set.of()))));
    }
    private <T> List<T> race(List<Callable<T>> actions) throws Exception {
        var executor = Executors.newFixedThreadPool(actions.size());
        CountDownLatch ready = new CountDownLatch(actions.size()), start = new CountDownLatch(1);
        try {
            var futures = actions.stream().map(action -> executor.submit(() -> {
                ready.countDown(); if (!start.await(10, TimeUnit.SECONDS)) throw new IllegalStateException("start timeout");
                return action.call();
            })).toList();
            assertThat(ready.await(10, TimeUnit.SECONDS)).isTrue(); start.countDown();
            List<T> result = new ArrayList<>();
            for (var future : futures) result.add(future.get(30, TimeUnit.SECONDS));
            return result;
        } finally { start.countDown();executor.shutdownNow(); }
    }
    private record Fixture(long event, long deal, String region, LocalDate validEnd) {}
}
