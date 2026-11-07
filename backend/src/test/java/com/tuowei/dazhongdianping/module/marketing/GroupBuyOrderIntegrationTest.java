package com.tuowei.dazhongdianping.module.marketing;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.atLeast;
import static org.mockito.Mockito.doCallRealMethod;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.reset;
import static org.mockito.Mockito.verify;

import com.tuowei.dazhongdianping.common.api.ServiceUnavailableException;
import com.tuowei.dazhongdianping.common.admin.AdminCityScope;
import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.marketing.mapper.MarketingCampaignMapper;
import com.tuowei.dazhongdianping.module.marketing.model.GroupBuyCampaignRow;
import com.tuowei.dazhongdianping.module.marketing.service.GroupBuyOrderService;
import com.tuowei.dazhongdianping.module.marketing.service.GroupBuyReminderService;
import com.tuowei.dazhongdianping.module.marketing.scheduler.GroupBuyReminderScheduler;
import com.tuowei.dazhongdianping.module.admin.groupbuy.service.AdminGroupBuyOperationsService;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSessionContext;
import com.tuowei.dazhongdianping.module.merchant.service.MerchantFulfillmentService;
import com.tuowei.dazhongdianping.module.merchant.trade.model.request.MerchantRefundAuditRequest;
import com.tuowei.dazhongdianping.module.merchant.trade.service.MerchantTradeService;
import com.tuowei.dazhongdianping.module.trade.model.request.RefundRequest;
import com.tuowei.dazhongdianping.module.trade.payment.MockPaymentChannel;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentNotifyResult;
import com.tuowei.dazhongdianping.module.trade.scheduler.TradeCompensationScheduler;
import com.tuowei.dazhongdianping.module.trade.service.TradeCompensationService;
import com.tuowei.dazhongdianping.module.trade.service.TradeService;
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
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.jdbc.core.JdbcTemplate;

/** Committed fixtures are intentional: races run in independent, real transactions. */
@SpringBootTest(properties = {
        "app.launch.deferred-features-enabled=true",
        "app.launch.group-buy-feature-flag-enforced=false"
})
class GroupBuyOrderIntegrationTest {
    private static final AtomicLong IDS = new AtomicLong(800_000);

    @Autowired JdbcTemplate jdbc;
    @Autowired GroupBuyOrderService groupBuy;
    @Autowired MarketingCampaignMapper campaignMapper;
    @Autowired TradeService trade;
    @Autowired TradeCompensationService compensation;
    @Autowired MerchantTradeService merchantTrade;
    @Autowired MerchantFulfillmentService fulfillment;
    @Autowired AdminGroupBuyOperationsService groupBuyOperations;
    @Autowired GroupBuyReminderService reminders;
    @SpyBean MockPaymentChannel channel;
    @MockBean TradeCompensationScheduler compensationScheduler;
    @MockBean GroupBuyReminderScheduler reminderScheduler;

    @BeforeEach void prepare() { reset(channel); }

    @AfterEach void clear() {
        UserSessionContext.clear();
        RegionContext.clear();
        MerchantSessionContext.clear();
        AdminSessionContext.clear();
    }

    @Test void formsOnlyAfterEveryMemberPaysAndIssuesOneCouponPerOrder() {
        Fixture fixture = fixture(2, 2);
        long leader = user(), member = user();
        Map<String, Object> opened = as(leader, () -> groupBuy.open(fixture.campaign));
        long teamId = number(opened, "id"), leaderOrder = number(opened, "orderId");
        Map<String, Object> joined = as(member, () -> groupBuy.join(teamId));
        long memberOrder = number(joined, "orderId");

        assertThat(memberOrder).isNotEqualTo(leaderOrder);
        assertThat(count("SELECT COUNT(*) FROM `order` WHERE campaign_id=? AND order_source='groupbuy'", fixture.campaign))
                .isEqualTo(2);
        assertThat(stock(fixture)).isZero();

        as(leader, () -> trade.completeMockPayment(leaderOrder));
        assertThat(count("SELECT status FROM groupbuy_team WHERE id=?", teamId)).isEqualTo(1);
        assertThat(count("SELECT paid_count FROM groupbuy_team WHERE id=?", teamId)).isEqualTo(1);
        assertThat(count("SELECT COUNT(*) FROM coupon WHERE order_id IN (?,?)", leaderOrder, memberOrder)).isZero();

        as(member, () -> trade.completeMockPayment(memberOrder));
        assertThat(count("SELECT status FROM groupbuy_team WHERE id=?", teamId)).isEqualTo(2);
        assertThat(count("SELECT paid_count FROM groupbuy_team WHERE id=?", teamId)).isEqualTo(2);
        assertThat(count("SELECT COUNT(*) FROM coupon WHERE order_id=?", leaderOrder)).isEqualTo(1);
        assertThat(count("SELECT COUNT(*) FROM coupon WHERE order_id=?", memberOrder)).isEqualTo(1);
        assertThat(as(leader, () -> trade.order(leaderOrder)))
                .containsEntry("groupBuyTeamId", teamId)
                .containsEntry("groupBuyStatus", 2)
                .containsEntry("groupBuyMemberCount", 2)
                .containsEntry("groupBuyPaidCount", 2)
                .containsEntry("groupBuySize", 2);
    }

    @Test void concurrentJoinersCannotExceedEitherTeamSizeOrDealStock() throws Exception {
        for (int[] limits : List.of(new int[]{3, 10}, new int[]{10, 3})) {
            Fixture fixture = fixture(limits[0], limits[1]);
            long leader = user();
            long teamId = as(leader, () -> number(groupBuy.open(fixture.campaign), "id"));
            List<Callable<Long>> joiners = new ArrayList<>();
            for (int i = 0; i < 10; i++) {
                long candidate = user();
                joiners.add(() -> as(candidate, () -> {
                    try { return number(groupBuy.join(teamId), "orderId"); }
                    catch (IllegalArgumentException fullOrSoldOut) { return 0L; }
                }));
            }

            long expectedMembers = Math.min(limits[0], limits[1]);
            assertThat(race(joiners).stream().filter(id -> id > 0).count()).isEqualTo(expectedMembers - 1);
            assertThat(count("SELECT member_count FROM groupbuy_team WHERE id=?", teamId)).isEqualTo(expectedMembers);
            assertThat(count("SELECT COUNT(*) FROM groupbuy_member WHERE team_id=?", teamId)).isEqualTo(expectedMembers);
            assertThat(count("SELECT COUNT(*) FROM `order` WHERE campaign_id=?", fixture.campaign)).isEqualTo(expectedMembers);
            assertThat(stock(fixture)).isEqualTo(limits[1] - expectedMembers);
        }
    }

    @Test void concurrentSandboxPaymentsFormOnceAndDuplicateCallbacksStayIdempotent() throws Exception {
        Fixture fixture = fixture(12, 12);
        List<Participant> participants = new ArrayList<>();
        long leader = user();
        Map<String, Object> opened = as(leader, () -> groupBuy.open(fixture.campaign));
        long teamId = number(opened, "id");
        participants.add(new Participant(leader, number(opened, "orderId")));
        for (int index = 1; index < 12; index++) {
            long userId = user();
            long orderId = as(userId, () -> number(groupBuy.join(teamId), "orderId"));
            participants.add(new Participant(userId, orderId));
        }

        List<Callable<Long>> payments = participants.stream()
                .<Callable<Long>>map(participant -> () -> as(participant.userId,
                        () -> number(trade.completeMockPayment(participant.orderId), "id")))
                .toList();
        assertThat(race(payments)).hasSize(12);
        assertThat(count("SELECT status FROM groupbuy_team WHERE id=?", teamId)).isEqualTo(2);
        assertThat(count("SELECT paid_count FROM groupbuy_team WHERE id=?", teamId)).isEqualTo(12);
        assertThat(count("SELECT COUNT(*) FROM coupon c JOIN groupbuy_member m ON m.order_id=c.order_id WHERE m.team_id=?", teamId))
                .isEqualTo(12);

        List<Callable<Boolean>> duplicates = participants.stream().<Callable<Boolean>>map(participant -> () -> {
            Map<String, Object> payment = jdbc.queryForMap(
                    "SELECT p.channel,p.channel_txn,o.order_no,o.amount FROM payment p JOIN `order` o ON o.id=p.order_id WHERE p.order_id=?",
                    participant.orderId);
            return as(participant.userId, () -> Boolean.TRUE.equals(trade.notifyInternal(
                    String.valueOf(payment.get("channel")),
                    new PaymentNotifyResult(
                            String.valueOf(payment.get("order_no")),
                            String.valueOf(payment.get("channel_txn")),
                            new BigDecimal(String.valueOf(payment.get("amount"))), true)).get("processed")));
        }).toList();
        assertThat(race(duplicates)).containsOnly(false);
        assertThat(count("SELECT COUNT(*) FROM coupon c JOIN groupbuy_member m ON m.order_id=c.order_id WHERE m.team_id=?", teamId))
                .isEqualTo(12);
    }

    @Test void expiryClosesUnpaidOrderAndAutomaticallyRefundsPaidOrderExactlyOnce() {
        Fixture fixture = fixture(3, 3);
        long leader = user(), member = user();
        Map<String, Object> opened = as(leader, () -> groupBuy.open(fixture.campaign));
        long teamId = number(opened, "id"), paidOrder = number(opened, "orderId");
        long unpaidOrder = as(member, () -> number(groupBuy.join(teamId), "orderId"));
        as(leader, () -> trade.completeMockPayment(paidOrder));
        expire(teamId);

        compensation.reconcile();
        compensation.reconcile();

        assertThat(count("SELECT status FROM groupbuy_team WHERE id=?", teamId)).isEqualTo(3);
        assertThat(count("SELECT pay_status FROM `order` WHERE id=?", paidOrder)).isEqualTo(2);
        assertThat(count("SELECT status FROM refund WHERE order_id=?", paidOrder)).isEqualTo(1);
        assertThat(count("SELECT COUNT(*) FROM refund WHERE order_id=?", paidOrder)).isEqualTo(1);
        assertThat(count("SELECT status FROM `order` WHERE id=?", unpaidOrder)).isEqualTo(2);
        assertThat(count("SELECT pay_status FROM `order` WHERE id=?", unpaidOrder)).isZero();
        assertThat(count("SELECT COUNT(*) FROM coupon WHERE order_id IN (?,?)", paidOrder, unpaidOrder)).isZero();
        assertThat(stock(fixture)).isEqualTo(3);
    }

    @Test void failedExpiryRefundIsRetriedWithAStableIdempotencyKey() {
        Fixture fixture = fixture(2, 2);
        long leader = user();
        Map<String, Object> opened = as(leader, () -> groupBuy.open(fixture.campaign));
        long teamId = number(opened, "id"), orderId = number(opened, "orderId");
        as(leader, () -> trade.completeMockPayment(orderId));
        String orderNo = jdbc.queryForObject("SELECT order_no FROM `order` WHERE id=?", String.class, orderId);
        expire(teamId);
        doThrow(new ServiceUnavailableException("Connection lost"))
                .when(channel).refund(any(), any(), anyString(), anyString());

        compensation.reconcile();
        assertThat(count("SELECT status FROM refund WHERE order_id=?", orderId)).isEqualTo(3);
        assertThat(jdbc.queryForObject("SELECT channel_refund_txn FROM refund WHERE order_id=?", String.class, orderId))
                .isEmpty();

        doCallRealMethod().when(channel).refund(any(), any(), anyString(), anyString());
        compensation.reconcile();
        ArgumentCaptor<String> keys = ArgumentCaptor.forClass(String.class);
        verify(channel, atLeast(2)).refund(any(), any(), anyString(), keys.capture());
        assertThat(keys.getAllValues()).containsOnly("groupbuy-expired-refund-" + orderNo);
        assertThat(count("SELECT status FROM refund WHERE order_id=?", orderId)).isEqualTo(1);
        assertThat(count("SELECT pay_status FROM `order` WHERE id=?", orderId)).isEqualTo(2);
        assertThat(stock(fixture)).isEqualTo(2);
    }

    @Test void completedTeamUsesExistingRedemptionAndRefundRules() {
        Fixture fixture = fixture(2, 2);
        long leader = user(), member = user();
        Map<String, Object> opened = as(leader, () -> groupBuy.open(fixture.campaign));
        long teamId = number(opened, "id"), leaderOrder = number(opened, "orderId");
        long memberOrder = as(member, () -> number(groupBuy.join(teamId), "orderId"));
        as(leader, () -> trade.completeMockPayment(leaderOrder));
        as(member, () -> trade.completeMockPayment(memberOrder));
        String leaderCode = code(leaderOrder), memberCode = code(memberOrder);

        merchant();
        fulfillment.verifyCoupon(leaderCode);
        assertThatThrownBy(() -> as(leader, () -> trade.refund(leaderOrder, new RefundRequest("Refund"))))
                .hasMessageContaining("已核销");

        as(member, () -> trade.refund(memberOrder, new RefundRequest("Plans changed")));
        merchant();
        merchantTrade.auditRefund(memberOrder, new MerchantRefundAuditRequest("approve", "Approved"));
        assertThat(count("SELECT pay_status FROM `order` WHERE id=?", memberOrder)).isEqualTo(2);
        assertThat(count("SELECT status FROM coupon WHERE code=?", memberCode)).isEqualTo(4);
        assertThat(count("SELECT status FROM groupbuy_team WHERE id=?", teamId)).isEqualTo(2);
        assertThat(stock(fixture)).isEqualTo(1);
    }

    @Test void operationsSummaryFindsAndRepairsMissingVoucherWithinAdminScope() {
        Fixture fixture = fixture(2, 2);
        long leader = user(), member = user();
        Map<String, Object> opened = as(leader, () -> groupBuy.open(fixture.campaign));
        long teamId = number(opened, "id"), leaderOrder = number(opened, "orderId");
        long memberOrder = as(member, () -> number(groupBuy.join(teamId), "orderId"));
        as(leader, () -> trade.completeMockPayment(leaderOrder));
        as(member, () -> trade.completeMockPayment(memberOrder));
        jdbc.update("DELETE FROM coupon WHERE order_id=?", memberOrder);

        admin(new AdminCityScope(false, Set.of(), Set.of(10001L)));
        assertThat(groupBuyOperations.summary().missingCouponOrders()).isEqualTo(1);
        assertThat(groupBuyOperations.teams(null, true, 1, 20).list())
                .extracting("id").contains(teamId);

        var repaired = groupBuyOperations.reconcile(teamId, "127.0.0.1");

        assertThat(repaired.vouchersIssued()).isEqualTo(1);
        assertThat(repaired.failures()).isZero();
        assertThat(repaired.team().missingCouponOrders()).isZero();
        assertThat(count("SELECT COUNT(*) FROM coupon WHERE order_id=?", memberOrder)).isEqualTo(1);
    }

    @Test void deadlineReminderIsSentOnceToEveryActiveMember() {
        // Other committed fixtures in this class intentionally survive between
        // tests so transaction races use real connections. Exclude those teams
        // from this scheduler assertion and keep the due set deterministic.
        jdbc.update("UPDATE groupbuy_member SET remind_status=1");
        Fixture fixture = fixture(2, 2);
        long leader = user(), member = user();
        long teamId = as(leader, () -> number(groupBuy.open(fixture.campaign), "id"));
        as(member, () -> groupBuy.join(teamId));
        jdbc.update("UPDATE groupbuy_team SET expire_at=? WHERE id=?", LocalDateTime.now().plusMinutes(30), teamId);

        assertThat(reminders.dispatchDueReminders().sent()).isEqualTo(2);
        assertThat(reminders.dispatchDueReminders().sent()).isZero();

        assertThat(count("SELECT COUNT(*) FROM user_notification WHERE type='groupbuy.deadline' AND link_url=?",
                "/marketing/groupbuy?teamId=" + teamId)).isEqualTo(2);
        assertThat(count("SELECT COUNT(*) FROM groupbuy_member WHERE team_id=? AND remind_status=1", teamId)).isEqualTo(2);
    }

    private Fixture fixture(int groupSize, int dealStock) {
        long id = IDS.incrementAndGet();
        LocalDate validEnd = LocalDate.now().plusDays(30);
        jdbc.update("INSERT INTO deal(id,shop_id,merchant_id,region,type,title,cover_image,price,original_price,currency,stock,sold_count,valid_start,valid_end,rules,audit_status,status) VALUES(?,10001,1001,'CN',1,'Group deal','',20,30,'CNY',?,0,?,?,'Use in store',1,1)",
                id, dealStock, LocalDate.now(), validEnd);
        GroupBuyCampaignRow campaign = new GroupBuyCampaignRow();
        campaign.setRegion("CN");
        campaign.setShopId(10001L);
        campaign.setMerchantId(1001L);
        campaign.setDealId(id);
        campaign.setTitle("Group campaign");
        campaign.setGroupPrice(new BigDecimal("12.80"));
        campaign.setCurrency("CNY");
        campaign.setGroupSize(groupSize);
        campaign.setStartAt(LocalDateTime.now().minusHours(1));
        campaign.setEndAt(LocalDateTime.now().plusHours(1));
        campaignMapper.insertGroup(campaign);
        jdbc.update("UPDATE groupbuy_campaign SET audit_status=2 WHERE id=?", campaign.getId());
        return new Fixture(campaign.getId(), id);
    }

    private long user() {
        long id = IDS.incrementAndGet();
        jdbc.update("INSERT INTO app_user(id,nickname,email) VALUES(?,'Buyer',?)", id, UUID.randomUUID() + "@example.com");
        return id;
    }

    private <T> T as(long userId, Supplier<T> action) {
        UserSessionContext.set(new UserSession(userId, 1L));
        RegionContext.setRegion(Region.CN);
        try { return action.get(); }
        finally { UserSessionContext.clear(); RegionContext.clear(); }
    }

    private void merchant() {
        RegionContext.setRegion(Region.CN);
        MerchantSessionContext.set(new MerchantSession(12001L, 1001L, "merchant", 1, "CN"));
    }

    private void admin(AdminCityScope scope) {
        RegionContext.setRegion(Region.CN);
        AdminSessionContext.set(new AdminSession(
                1L, "admin", "Admin", Set.of("data:order:read", "data:order:write"),
                Set.of("CN"), Map.of("CN", scope)));
    }

    private void expire(long teamId) {
        LocalDateTime past = LocalDateTime.now().minusSeconds(1);
        jdbc.update("UPDATE groupbuy_team SET expire_at=? WHERE id=?", past, teamId);
        jdbc.update("UPDATE `order` SET expire_at=? WHERE id IN (SELECT order_id FROM groupbuy_member WHERE team_id=?)", past, teamId);
    }

    private String code(long orderId) {
        return jdbc.queryForObject("SELECT code FROM coupon WHERE order_id=?", String.class, orderId);
    }

    private long number(Map<String, Object> result, String key) {
        return ((Number) result.get(key)).longValue();
    }

    private long count(String sql, Object... args) {
        return jdbc.queryForObject(sql, Long.class, args);
    }

    private long stock(Fixture fixture) {
        return count("SELECT stock FROM deal WHERE id=?", fixture.deal);
    }

    private <T> List<T> race(List<Callable<T>> actions) throws Exception {
        var executor = Executors.newFixedThreadPool(actions.size());
        CountDownLatch ready = new CountDownLatch(actions.size());
        CountDownLatch start = new CountDownLatch(1);
        try {
            var futures = actions.stream().map(action -> executor.submit(() -> {
                ready.countDown();
                if (!start.await(10, TimeUnit.SECONDS)) throw new IllegalStateException("start timeout");
                return action.call();
            })).toList();
            assertThat(ready.await(10, TimeUnit.SECONDS)).isTrue();
            start.countDown();
            List<T> results = new ArrayList<>();
            for (var future : futures) results.add(future.get(30, TimeUnit.SECONDS));
            return results;
        } finally {
            start.countDown();
            executor.shutdownNow();
        }
    }

    private record Fixture(long campaign, long deal) {}
    private record Participant(long userId, long orderId) {}
}
