package com.tuowei.dazhongdianping.module.auth.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.auth.model.request.PrivacyExportTaskCreateRequest;
import com.tuowei.dazhongdianping.module.notification.service.NotificationService;
import com.tuowei.dazhongdianping.module.trade.service.TradeService;
import com.tuowei.dazhongdianping.module.trade.payment.PaymentNotifyResult;
import com.tuowei.dazhongdianping.module.consult.mapper.ConsultMapper;
import com.tuowei.dazhongdianping.module.marketing.mapper.MarketingMapper;
import java.math.BigDecimal;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.zip.ZipFile;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.transaction.TestTransaction;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.annotation.Propagation;

@SpringBootTest(properties = {"app.privacy.delete-initial-delay-ms=3600000"})
@Transactional
class UserPrivacyDomainIntegrationTest {
    private static final long OWNER = 991001L;
    private static final long OTHER = 991002L;
    private static final String PERSONAL = "person@example.invalid";
    private static final String OTHER_PRIVATE = "other-private@example.invalid";
    @Autowired JdbcTemplate jdbc;
    @Autowired UserPrivacyService privacy;
    @Autowired ObjectMapper json;
    @Autowired NotificationService notifications;
    @Autowired TradeService trade;
    @Autowired ConsultMapper consult;
    @Autowired MarketingMapper marketing;

    @AfterEach
    void clearContextAndArchives() throws IOException {
        for (String path : jdbc.queryForList("SELECT file_path FROM privacy_export_task WHERE user_id IN (?,?) AND file_path!=''", String.class, OWNER, OTHER)) {
            Files.deleteIfExists(Path.of(path));
        }
        UserSessionContext.clear();
        RegionContext.clear();
    }

    @Test
    void exportsNewDomainsAcrossBothRegionsWithoutAnotherUsersDataOrCredentials() throws Exception {
        fixture();
        authenticate(OWNER);
        PrivacyExportTaskCreateRequest request = new PrivacyExportTaskCreateRequest();
        // Empty scope continues to mean all modules; this exercises every projection, including the account/order additions.
        request.setModules(List.of());
        var task = privacy.createExportTask(request);
        assertThat(task.modules()).hasSize(24).contains("invoices", "tickets", "consult", "waitlist", "translations");
        JsonNode payload = archive(task.id());
        assertThat(payload.at("/meta/scope").asText()).isEqualTo("account_all_regions");
        assertThat(payload.at("/modules/invoices/titles")).hasSize(2);
        assertThat(payload.at("/modules/invoices/titles/0/region").asText()).isEqualTo("CN");
        assertThat(payload.at("/modules/invoices/titles/1/region").asText()).isEqualTo("EU");
        assertThat(payload.at("/modules/invoices/titles/1/email").asText()).isEqualTo(PERSONAL);
        assertThat(payload.at("/modules/tickets/tickets")).hasSize(1);
        assertThat(payload.at("/modules/tickets/messages")).hasSize(2);
        assertThat(payload.at("/modules/consult/sessions")).hasSize(1);
        assertThat(payload.at("/modules/consult/messages")).hasSize(2);
        assertThat(payload.at("/modules/waitlist")).hasSize(2);
        assertThat(payload.at("/modules/translations")).hasSize(1);
        assertThat(payload.at("/modules/questions/questions")).hasSize(1);
        assertThat(payload.at("/modules/questions/answers")).hasSize(1);
        assertThat(payload.at("/modules/dish_reviews")).hasSize(1);
        assertThat(payload.at("/modules/marketing_coupons")).hasSize(2);
        assertThat(payload.at("/modules/complaints/tickets")).hasSize(1);
        assertThat(payload.at("/modules/activities/creatorClaims")).hasSize(2);
        assertThat(payload.at("/modules/activities/seckillClaims")).hasSize(1);
        assertThat(payload.at("/modules/activities/groupbuyMemberships")).hasSize(1);
        assertThat(payload.at("/modules/activities/experimentAssignments")).hasSize(1);
        assertThat(payload.at("/modules/behavior")).hasSize(1);
        assertThat(payload.at("/modules/account/records/sessions")).hasSize(1);
        assertThat(payload.at("/modules/orders/0/payments/0/amount").decimalValue()).isEqualByComparingTo("20.00");
        assertThat(payload.toString()).doesNotContain(OTHER_PRIVATE, "synthetic-client-secret", "synthetic-refresh-hash",
                "synthetic-push-token", "synthetic-password-hash", "synthetic-raw-payment", "internal-risk-rule");

        authenticate(OTHER);
        assertThatThrownBy(() -> privacy.downloadExportTask(task.id())).hasMessage("隐私导出任务不存在");
    }

    @Test
    void normalizesModuleSelectionAndRejectsUnknownModulesWithoutCreatingTasks() throws Exception {
        fixture();
        authenticate(OWNER);
        PrivacyExportTaskCreateRequest selected = new PrivacyExportTaskCreateRequest();
        selected.setModules(List.of(" INVOICES ", "invoices", "translations"));
        var task = privacy.createExportTask(selected);
        assertThat(task.modules()).containsExactly("invoices", "translations");
        assertThat(archive(task.id()).path("modules").fieldNames()).toIterable().containsExactly("invoices", "translations");
        PrivacyExportTaskCreateRequest invalid = new PrivacyExportTaskCreateRequest();
        invalid.setModules(List.of("payment_credentials"));
        assertThatThrownBy(() -> privacy.createExportTask(invalid)).isInstanceOf(IllegalArgumentException.class);
        assertThat(count("SELECT COUNT(*) FROM privacy_export_task WHERE user_id=?", OWNER)).isEqualTo(1);
    }

    @Test
    void preservesCommentThreadReferencesAndScrubsAppealAuditText() {
        fixture();
        // reply_to stores a comment ID, even when that ID happens to match the deleted account ID.
        jdbc.update("INSERT INTO review_comment(id,review_id,user_id,user_name,content,reply_to) VALUES(?,991901,?,'Other','Other comment',0), (991904,991901,?,'Owner','Public reply',?)", OWNER, OTHER, OWNER, OWNER);
        jdbc.update("INSERT INTO post_comment(id,post_id,user_id,user_name,content,reply_to) VALUES(?,991902,?,'Other','Other comment',0), (991905,991902,?,'Owner','Public reply',?)", OWNER, OTHER, OWNER, OWNER);
        jdbc.update("INSERT INTO user_ban_appeal(id,user_id,region,account,reason) VALUES(992400,?,'EU',?,?)", OWNER, PERSONAL, PERSONAL);
        jdbc.update("INSERT INTO audit_log(admin_id,action,target,detail) VALUES(1,'audit_user_appeal_pass','user_appeal:992400',?)", PERSONAL);
        due(OWNER);
        privacy.processDueDeleteTasksForUser(OWNER);
        assertThat(count("SELECT reply_to FROM review_comment WHERE id=991904")).isEqualTo(OWNER);
        assertThat(count("SELECT reply_to FROM post_comment WHERE id=991905")).isEqualTo(OWNER);
        assertThat(value("SELECT user_name FROM review_comment WHERE id=991904")).isEqualTo("已注销用户");
        assertThat(value("SELECT user_name FROM post_comment WHERE id=991905")).isEqualTo("已注销用户");
        assertThat(value("SELECT detail FROM audit_log WHERE target='user_appeal:992400'")).isEmpty();
    }

    @Test
    void deletionUnlinksPrivateDomainsPreservesOtherRolesAndKeepsRefundableTransactions() {
        fixture();
        due(OWNER);
        privacy.processDueDeleteTasksForUser(OWNER);

        assertThat(value("SELECT email FROM invoice_title WHERE id=991102")).isEmpty();
        assertThat(value("SELECT tax_no FROM invoice_title WHERE id=991102")).isEmpty();
        assertThat(value("SELECT name FROM invoice_title WHERE id=991102")).isEqualTo("已注销用户");
        assertThat(count("SELECT COUNT(*) FROM consult_session WHERE user_id=?", OWNER)).isZero();
        assertThat(count("SELECT COUNT(*) FROM consult_message WHERE sender_type=1 AND sender_id=?", OWNER)).isZero();
        assertThat(value("SELECT content FROM consult_message WHERE id=991202")).isEqualTo("内容已因账号注销移除");
        assertThat(value("SELECT content FROM consult_message WHERE id=991204")).isEqualTo(OTHER_PRIVATE);
        assertThat(count("SELECT sender_id FROM consult_message WHERE id=991204")).isEqualTo(OWNER);
        assertThat(value("SELECT content FROM ticket_message WHERE id=991302")).isEqualTo("内容已因账号注销移除");
        assertThat(value("SELECT content FROM ticket_message WHERE id=991304")).isEqualTo(OTHER_PRIVATE);
        assertThat(count("SELECT requester_id FROM support_ticket WHERE id=991303")).isEqualTo(OWNER);
        assertThat(count("SELECT sender_id FROM ticket_message WHERE id=991304")).isEqualTo(OWNER);
        assertThat(value("SELECT remark FROM complaint_log WHERE id=991404")).isEqualTo(OTHER_PRIVATE);
        assertThat(count("SELECT actor_id FROM complaint_log WHERE id=991404")).isEqualTo(OWNER);
        assertThat(value("SELECT content FROM complaint_ticket WHERE id=991401")).isEqualTo("内容已因账号注销移除");
        assertThat(count("SELECT status FROM waitlist_entry WHERE id=991501")).isEqualTo(5);
        assertThat(count("SELECT status FROM waitlist_entry WHERE id=991502")).isEqualTo(3);
        assertThat(count("SELECT status FROM waitlist_entry WHERE id=991503")).isEqualTo(1);
        assertThat(count("SELECT COUNT(*) FROM review_translation WHERE user_id=?", OWNER)).isZero();
        assertThat(count("SELECT COUNT(*) FROM user_behavior_event WHERE user_id=?", OWNER)).isZero();
        assertThat(count("SELECT COUNT(*) FROM experiment_assignment WHERE user_id=?", OWNER)).isZero();
        assertThat(count("SELECT user_id FROM shop_question WHERE id=991601")).isZero();
        assertThat(count("SELECT user_id FROM shop_answer WHERE id=991602")).isZero();
        assertThat(count("SELECT user_id FROM dish_review WHERE id=991603")).isZero();
        assertThat(count("SELECT COUNT(*) FROM creator_task_claim WHERE user_id=?", OWNER)).isZero();
        assertThat(count("SELECT COUNT(*) FROM creator_task_claim WHERE task_id=991801 AND status=2")).isEqualTo(2);
        assertThat(count("SELECT COUNT(*) FROM seckill_claim WHERE user_id=?", OWNER)).isZero();
        assertThat(count("SELECT sold FROM seckill_event WHERE id=991802")).isEqualTo(1);
        assertThat(count("SELECT member_count FROM groupbuy_team WHERE id=991803")).isEqualTo(1);
        assertThat(count("SELECT leader_user_id FROM groupbuy_team WHERE id=991803")).isEqualTo(OTHER);
        assertThat(count("SELECT status FROM groupbuy_team WHERE id=991803")).isEqualTo(2);
        assertThat(count("SELECT COUNT(*) FROM device_fingerprint_user WHERE user_id=?", OWNER)).isZero();
        assertThat(count("SELECT user_count FROM device_fingerprint WHERE id=991701")).isEqualTo(1);
        assertThat(count("SELECT COUNT(*) FROM device_fingerprint WHERE id=991702")).isZero();
        assertThat(count("SELECT COUNT(*) FROM risk_event WHERE user_id=? OR ip=? OR device_fingerprint=?", OWNER, PERSONAL, "only-owner")).isZero();
        assertThat(count("SELECT like_count FROM review WHERE id=991901")).isEqualTo(1);
        assertThat(count("SELECT helpful_count FROM review WHERE id=991901")).isEqualTo(1);
        assertThat(count("SELECT like_count FROM post WHERE id=991902")).isEqualTo(1);
        assertThat(count("SELECT COUNT(*) FROM user_favorite WHERE user_id=?", OWNER)).isZero();
        assertThat(count("SELECT reserved_count FROM reservation_slot WHERE id=992001")).isEqualTo(2);
        assertThat(count("SELECT status FROM reservation WHERE id=992002")).isEqualTo(3);
        assertThat(value("SELECT contact_phone FROM reservation WHERE id=992002")).isEmpty();
        assertThat(count("SELECT stock FROM points_product WHERE id=992101")).isEqualTo(6);
        assertThat(count("SELECT exchange_count FROM points_product WHERE id=992101")).isEqualTo(2);
        assertThat(count("SELECT status FROM points_exchange WHERE id=992102")).isEqualTo(2);
        assertThat(count("SELECT status FROM points_exchange WHERE id=992103")).isEqualTo(1);
        assertThat(value("SELECT redeem_code FROM points_exchange WHERE id=992103")).isEqualTo("synthetic-issued-code");
        assertThat(count("SELECT pay_status FROM `order` WHERE id=992201")).isEqualTo(1);
        assertThat(count("SELECT user_id FROM `order` WHERE id=992201")).isEqualTo(OWNER);
        assertThat(count("SELECT status FROM refund WHERE id=992203")).isEqualTo(0);
        assertThat(value("SELECT channel_txn FROM payment WHERE id=992202")).isEqualTo("synthetic-payment-txn");
        assertThat(value("SELECT client_secret FROM payment WHERE id=992202")).isEmpty();
        assertThat(value("SELECT raw_response FROM payment WHERE id=992202")).isNull();
        assertThat(count("SELECT user_id FROM user_coupon WHERE id=992206")).isEqualTo(OWNER);
        assertThat(count("SELECT used_order_id FROM user_coupon WHERE id=992206")).isEqualTo(992201);
        assertThat(count("SELECT claimed_quantity FROM marketing_coupon_template WHERE id=992204")).isEqualTo(3);
        assertThat(count("SELECT COUNT(*) FROM user_session WHERE user_id=?", OWNER)).isZero();
        assertThat(count("SELECT COUNT(*) FROM user_device WHERE user_id=? OR push_token=? OR device_uid=?", OWNER, "synthetic-push-token", PERSONAL)).isZero();
        assertThat(value("SELECT account_snapshot FROM privacy_delete_task WHERE user_id=?", OWNER)).isEmpty();
        assertThat(count("SELECT status FROM privacy_delete_task WHERE user_id=?", OWNER)).isEqualTo(3);
        assertThat(jdbc.queryForObject("SELECT is_deleted FROM app_user WHERE id=?", Boolean.class, OWNER)).isTrue();
        assertThat(value("SELECT email FROM app_user WHERE id=?", OTHER)).isEqualTo(OTHER_PRIVATE);

        // Reprocessing is harmless; parent quantities and the other member remain stable.
        privacy.processDueDeleteTasksForUser(OWNER);
        assertThat(count("SELECT stock FROM points_product WHERE id=992101")).isEqualTo(6);
        assertThat(count("SELECT member_count FROM groupbuy_team WHERE id=991803")).isEqualTo(1);
    }

    @Test
    void consecutiveDeletionsOfUsersSharingObjectsDoNotCollideUnderUniqueKeys() {
        fixture();
        jdbc.update("INSERT INTO consult_session(id,region,user_id,shop_id,merchant_id) VALUES(991205,'EU',?,20001,2001)", OTHER);
        jdbc.update("INSERT INTO post_report(post_id,reporter_user_id,reporter_user_name,reason) VALUES(991902,?,'owner',?), (991902,?,'other',?)", OWNER, PERSONAL, OTHER, OTHER_PRIVATE);
        jdbc.update("INSERT INTO review_comment_report(review_id,comment_id,reporter_user_id,reporter_user_name,reason) VALUES(991901,991903,?,'owner',?), (991901,991903,?,'other',?)", OWNER, PERSONAL, OTHER, OTHER_PRIVATE);
        jdbc.update("INSERT INTO post_comment_report(post_id,comment_id,reporter_user_id,reporter_user_name,reason) VALUES(991902,991904,?,'owner',?), (991902,991904,?,'other',?)", OWNER, PERSONAL, OTHER, OTHER_PRIVATE);
        jdbc.update("INSERT INTO conversation(id,user_a,user_b,last_message_preview) VALUES(992301,?,91000,?), (992302,?,91000,?)", OWNER, PERSONAL, OTHER, OTHER_PRIVATE);
        jdbc.update("INSERT INTO message_report(reporter_user_id,target_type,target_id,reason) VALUES(?,2,992301,?), (?,2,992301,?)", OWNER, PERSONAL, OTHER, OTHER_PRIVATE);
        due(OWNER);
        due(OTHER);
        privacy.processDueDeleteTasksForUser(OWNER);
        privacy.processDueDeleteTasksForUser(OTHER);
        assertThat(count("SELECT COUNT(*) FROM privacy_delete_task WHERE user_id IN (?,?) AND status=3", OWNER, OTHER)).isEqualTo(2);
        assertThat(count("SELECT COUNT(*) FROM consult_session WHERE id IN(991201,991205) AND user_id IS NULL")).isEqualTo(2);
        assertThat(count("SELECT COUNT(*) FROM conversation WHERE id IN(992301,992302) AND user_a IS NULL")).isEqualTo(2);
        assertThat(count("SELECT COUNT(*) FROM post_report WHERE post_id=991902 AND reporter_user_id IS NULL")).isEqualTo(2);
        assertThat(count("SELECT COUNT(*) FROM review_comment_report WHERE comment_id=991903 AND reporter_user_id IS NULL")).isEqualTo(2);
        assertThat(count("SELECT COUNT(*) FROM post_comment_report WHERE comment_id=991904 AND reporter_user_id IS NULL")).isEqualTo(2);
        assertThat(count("SELECT COUNT(*) FROM message_report WHERE target_id=992301 AND reporter_user_id IS NULL")).isEqualTo(2);
        assertThat(count("SELECT COUNT(*) FROM creator_task_claim WHERE task_id=991801 AND user_id IS NULL AND status=2")).isEqualTo(2);
    }

    @Test
    void upgradesHistoricalCompletedDeletionWithoutRewritingCompletionOrTouchingActiveAccounts() throws Exception {
        fixture();
        authenticate(OWNER);
        var archive = privacy.createExportTask(new PrivacyExportTaskCreateRequest());
        due(OWNER);
        due(OTHER);
        LocalDateTime originalCompletion = LocalDateTime.of(2026, 10, 1, 12, 30);
        jdbc.update("UPDATE privacy_delete_task SET status=3,completed_at=? WHERE user_id IN(?,?)", originalCompletion, OWNER, OTHER);
        jdbc.update("UPDATE app_user SET is_deleted=TRUE,status=2,nickname='已注销用户1001',email=NULL,phone=NULL,password_hash=NULL WHERE id=?", OWNER);
        // Old MySQL SET ordering could detach the sender before removing their message body.
        jdbc.update("INSERT INTO conversation(id,user_a,user_b,last_message_preview) VALUES(992301,?,?,?)", OWNER, OTHER, PERSONAL);
        jdbc.update("INSERT INTO message(conversation_id,from_user_id,to_user_id,content) VALUES(992301,0,?,?)", OTHER, PERSONAL);

        assertThat(privacy.dueDeleteUserIds()).contains(OWNER).doesNotContain(OTHER);
        privacy.processDueDeleteTasksForUser(OWNER);
        privacy.processDueDeleteTasksForUser(OTHER);
        assertThat(count("SELECT domain_cleanup_version FROM privacy_delete_task WHERE user_id=?", OWNER)).isEqualTo(1);
        assertThat(jdbc.queryForObject("SELECT completed_at FROM privacy_delete_task WHERE user_id=?", LocalDateTime.class, OWNER)).isEqualTo(originalCompletion);
        assertThat(value("SELECT email FROM invoice_title WHERE id=991102")).isEmpty();
        assertThat(value("SELECT content FROM consult_message WHERE id=991201")).isEqualTo("内容已因账号注销移除");
        assertThat(value("SELECT content FROM message WHERE conversation_id=992301")).isEqualTo("消息已因账号注销移除");
        assertThat(count("SELECT COUNT(*) FROM conversation WHERE id=992301 AND user_a IS NULL")).isEqualTo(1);
        assertThat(count("SELECT status FROM privacy_export_task WHERE id=?", archive.id())).isEqualTo(5);
        assertThat(value("SELECT nickname FROM app_user WHERE id=?", OWNER)).isEqualTo("已注销用户");
        assertThat(value("SELECT email FROM invoice_title WHERE id=991103")).isEqualTo(OTHER_PRIVATE);
        assertThat(count("SELECT domain_cleanup_version FROM privacy_delete_task WHERE user_id=?", OTHER)).isZero();
        assertThat(privacy.dueDeleteUserIds()).doesNotContain(OWNER, OTHER);
        privacy.processDueDeleteTasksForUser(OWNER);
        assertThat(count("SELECT stock FROM points_product WHERE id=992101")).isEqualTo(6);
    }

    @Test
    void latePaymentCompletesAfterDeletionWithoutRecreatingNotificationsOrGrowthData() {
        fixture();
        jdbc.update("UPDATE `order` SET deal_id=41001,pay_status=0 WHERE id=992201");
        jdbc.update("UPDATE payment SET status=0 WHERE id=992202");
        due(OWNER);
        privacy.processDueDeleteTasksForUser(OWNER);
        assertThat(consult.selectMerchantSession(991201L, 2001L, "EU")).isNull();
        assertThat(notifications.create(OWNER, "EU", "synthetic.delayed", "Synthetic", PERSONAL, ""))
                .containsEntry("delivered", false);
        var result = trade.notifyInternal("stripe", new PaymentNotifyResult("SYNTHETIC-ORDER", "synthetic-payment-txn", new BigDecimal("20.00"), true));
        assertThat(result).containsEntry("processed", true);
        assertThat(count("SELECT pay_status FROM `order` WHERE id=992201")).isEqualTo(1);
        assertThat(count("SELECT status FROM payment WHERE id=992202")).isEqualTo(1);
        assertThat(value("SELECT raw_response FROM payment WHERE id=992202")).isEmpty();
        assertThat(count("SELECT COUNT(*) FROM coupon WHERE order_id=992201")).isEqualTo(1);
        assertThat(count("SELECT COUNT(*) FROM growth_points_log WHERE user_id=?", OWNER)).isZero();
        assertThat(count("SELECT COUNT(*) FROM user_notification WHERE user_id=?", OWNER)).isZero();
        assertThat(trade.notifyInternal("stripe", new PaymentNotifyResult("SYNTHETIC-ORDER", "synthetic-payment-txn", new BigDecimal("20.00"), true)))
                .containsEntry("processed", false);
        marketing.releaseCouponForOrder(992201L);
        assertThat(count("SELECT status FROM user_coupon WHERE id=992206")).isEqualTo(3);
    }

    @Test
    @Transactional(propagation = Propagation.NOT_SUPPORTED)
    @DirtiesContext(methodMode = DirtiesContext.MethodMode.AFTER_METHOD)
    void rollsBackEveryDomainAndLeavesArchiveAvailableWhenDeletionFails() throws Exception {
        fixture();
        authenticate(OWNER);
        PrivacyExportTaskCreateRequest request = new PrivacyExportTaskCreateRequest();
        request.setModules(List.of("invoices"));
        var task = privacy.createExportTask(request);
        Path path = Path.of(value("SELECT file_path FROM privacy_export_task WHERE id=?", task.id()));
        due(OWNER);
        // A real constraint failure late in the transaction must undo earlier invoice/session/counter changes.
        jdbc.execute("ALTER TABLE privacy_delete_task ADD CONSTRAINT synthetic_deletion_failure CHECK(status!=3)");
        try {
            assertThatThrownBy(() -> privacy.processDueDeleteTasksForUser(OWNER)).isInstanceOf(RuntimeException.class);
            assertThat(count("SELECT status FROM privacy_delete_task WHERE user_id=?", OWNER)).isEqualTo(1);
            assertThat(jdbc.queryForObject("SELECT is_deleted FROM app_user WHERE id=?", Boolean.class, OWNER)).isFalse();
            assertThat(value("SELECT email FROM invoice_title WHERE id=991102")).isEqualTo(PERSONAL);
            assertThat(value("SELECT content FROM consult_message WHERE id=991201")).isEqualTo(PERSONAL);
            assertThat(count("SELECT member_count FROM groupbuy_team WHERE id=991803")).isEqualTo(99);
            assertThat(count("SELECT stock FROM points_product WHERE id=992101")).isEqualTo(5);
            assertThat(count("SELECT COUNT(*) FROM user_session WHERE user_id=?", OWNER)).isEqualTo(1);
            assertThat(count("SELECT status FROM privacy_export_task WHERE id=?", task.id())).isEqualTo(2);
            assertThat(Files.exists(path)).isTrue();
        } finally {
            jdbc.execute("ALTER TABLE privacy_delete_task DROP CONSTRAINT synthetic_deletion_failure");
            Files.deleteIfExists(path);
        }
    }

    @Test
    void successfulCommitRemovesOwnedArchiveAndPreservesOtherArchive() throws Exception {
        // Keep this commit test small and explicitly remove all committed synthetic rows afterwards.
        jdbc.update("INSERT INTO app_user(id,nickname,email,status,is_deleted) VALUES(?,'owner',?,1,FALSE), (?,'other',?,1,FALSE)", OWNER, PERSONAL, OTHER, OTHER_PRIVATE);
        authenticate(OWNER);
        PrivacyExportTaskCreateRequest request = new PrivacyExportTaskCreateRequest();
        request.setModules(List.of("invoices"));
        var owned = privacy.createExportTask(request);
        Path ownedPath = Path.of(value("SELECT file_path FROM privacy_export_task WHERE id=?", owned.id()));
        authenticate(OTHER);
        var other = privacy.createExportTask(request);
        Path otherPath = Path.of(value("SELECT file_path FROM privacy_export_task WHERE id=?", other.id()));
        due(OWNER);
        privacy.processDueDeleteTasksForUser(OWNER);
        assertThat(count("SELECT status FROM privacy_export_task WHERE id=?", owned.id())).isEqualTo(5);
        assertThat(Files.exists(ownedPath)).isTrue(); // Physical deletion must await commit.
        TestTransaction.flagForCommit();
        TestTransaction.end();
        try {
            assertThat(Files.exists(ownedPath)).isFalse();
            assertThat(value("SELECT file_path FROM privacy_export_task WHERE id=?", owned.id())).isEmpty();
            assertThat(Files.exists(otherPath)).isTrue();
            assertThat(count("SELECT status FROM privacy_export_task WHERE id=?", other.id())).isEqualTo(2);
        } finally {
            Files.deleteIfExists(otherPath);
            jdbc.update("DELETE FROM privacy_export_task WHERE user_id IN (?,?)", OWNER, OTHER);
            jdbc.update("DELETE FROM privacy_delete_task WHERE user_id IN (?,?)", OWNER, OTHER);
            jdbc.update("DELETE FROM app_user WHERE id IN (?,?)", OWNER, OTHER);
            TestTransaction.start();
        }
    }

    private void authenticate(long userId) {
        UserSessionContext.set(new UserSession(userId, null));
        RegionContext.setRegion(Region.EU);
    }

    private JsonNode archive(long taskId) throws IOException {
        try (ZipFile zip = new ZipFile(value("SELECT file_path FROM privacy_export_task WHERE id=?", taskId))) {
            return json.readTree(zip.getInputStream(zip.entries().nextElement()));
        }
    }

    private int count(String sql, Object... args) { return jdbc.queryForObject(sql, Integer.class, args); }
    private String value(String sql, Object... args) { return jdbc.queryForObject(sql, String.class, args); }
    private void due(long userId) {
        jdbc.update("INSERT INTO privacy_delete_task(user_id,verify_type,account_snapshot,reason,status,cooling_off_expire_at) VALUES(?,'password',?,?,1,?)",
                userId, PERSONAL, PERSONAL, LocalDateTime.now().minusDays(1));
    }

    private void fixture() {
        jdbc.update("INSERT INTO app_user(id,nickname,email,password_hash,preferred_region,status,is_deleted) VALUES(?,'owner',?,'synthetic-password-hash','EU',1,FALSE), (?,'other',?,'other-hash','CN',1,FALSE)", OWNER, PERSONAL, OTHER, OTHER_PRIVATE);
        jdbc.update("INSERT INTO invoice_title(id,user_id,region,title_type,name,tax_no,email) VALUES(991101,?,'CN',1,'Synthetic person','SYNTHETIC-TAX',?), (991102,?,'EU',1,'Synthetic person','SYNTHETIC-TAX',?), (991103,?,'EU',1,'Other person','OTHER-TAX',?)", OWNER, PERSONAL, OWNER, PERSONAL, OTHER, OTHER_PRIVATE);
        jdbc.update("INSERT INTO consult_session(id,region,user_id,shop_id,merchant_id,last_message) VALUES(991201,'EU',?,20001,2001,?), (991203,'CN',?,10001,1001,?)", OWNER, PERSONAL, OTHER, OTHER_PRIVATE);
        jdbc.update("INSERT INTO consult_message(id,session_id,region,sender_type,sender_id,content) VALUES(991201,991201,'EU',1,?,?), (991202,991201,'EU',2,?,?), (991204,991203,'CN',2,?,?)", OWNER, PERSONAL, OWNER, PERSONAL, OWNER, OTHER_PRIVATE);
        jdbc.update("INSERT INTO support_ticket(id,region,requester_type,requester_id,subject,content) VALUES(991301,'EU',1,?,? ,?), (991303,'CN',2,?,?,?)", OWNER, PERSONAL, PERSONAL, OWNER, OTHER_PRIVATE, OTHER_PRIVATE);
        jdbc.update("INSERT INTO ticket_message(id,ticket_id,sender_type,sender_id,content) VALUES(991301,991301,1,?,?), (991302,991301,3,?,?), (991304,991303,2,?,?)", OWNER, PERSONAL, OWNER, PERSONAL, OWNER, OTHER_PRIVATE);
        jdbc.update("INSERT INTO complaint_ticket(id,region,ticket_no,user_id,title,content,merchant_reply,resolution) VALUES(991401,'EU','SYNTHETIC-COMPLAINT',?,?,?, ?,?), (991403,'CN','OTHER-COMPLAINT',?,?,?,'','')", OWNER, PERSONAL, PERSONAL, PERSONAL, PERSONAL, OTHER, OTHER_PRIVATE, OTHER_PRIVATE);
        jdbc.update("INSERT INTO complaint_log(id,ticket_id,actor_type,actor_id,action,remark) VALUES(991402,991401,1,?,1,?), (991404,991403,2,?,2,?)", OWNER, PERSONAL, OWNER, OTHER_PRIVATE);
        jdbc.update("INSERT INTO waitlist_entry(id,region,shop_id,merchant_id,user_id,status) VALUES(991501,'EU',20001,2001,?,1), (991502,'CN',10001,1001,?,3), (991503,'EU',20001,2001,?,1)", OWNER, OWNER, OTHER);
        jdbc.update("INSERT INTO review_translation(id,review_id,user_id,region,target_lang,content) VALUES(991504,991901,?,'EU','en',?), (991505,991901,?,'EU','en',?)", OWNER, PERSONAL, OTHER, OTHER_PRIVATE);
        jdbc.update("INSERT INTO shop_question(id,region,shop_id,user_id,content,answer_count) VALUES(991601,'EU',20001,?,'Synthetic public question',1)", OWNER);
        jdbc.update("INSERT INTO shop_answer(id,region,question_id,user_id,content) VALUES(991602,'EU',991601,?,'Synthetic public answer')", OWNER);
        jdbc.update("INSERT INTO dish_review(id,region,shop_id,dish_id,user_id,score,content) VALUES(991603,'EU',20001,1,?,4,'Synthetic public dish review')", OWNER);
        jdbc.update("INSERT INTO user_behavior_event(user_id,region,event_type,keyword) VALUES(?,'EU',4,?), (?,'CN',4,?)", OWNER, PERSONAL, OTHER, OTHER_PRIVATE);
        jdbc.update("INSERT INTO device_fingerprint(id,region,fingerprint,user_count,last_user_id) VALUES(991701,'EU','shared',99,?), (991702,'CN','only-owner',1,?)", OWNER, OWNER);
        jdbc.update("INSERT INTO device_fingerprint_user(region,fingerprint,user_id) VALUES('EU','shared',?), ('EU','shared',?), ('CN','only-owner',?)", OWNER, OTHER, OWNER);
        jdbc.update("INSERT INTO risk_event(region,scene,user_id,device_fingerprint,ip,reason,hit_rules,dispose_remark) VALUES('EU','review_create',?,'only-owner',?,?,'internal-risk-rule',?)", OWNER, PERSONAL, PERSONAL, PERSONAL);
        jdbc.update("INSERT INTO creator_task(id,region,title,reward_points) VALUES(991801,'EU','Synthetic creator task',5)");
        jdbc.update("INSERT INTO creator_task_claim(task_id,user_id,region,status) VALUES(991801,?,'EU',2), (991801,?,'EU',2), (991802,?,'EU',1)", OWNER, OTHER, OWNER);
        jdbc.update("INSERT INTO seckill_event(id,region,shop_id,merchant_id,title,seckill_price,currency,stock,sold,start_at,end_at) VALUES(991802,'EU',20001,2001,'Synthetic seckill',2,'EUR',10,99,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)");
        jdbc.update("INSERT INTO seckill_claim(event_id,user_id,region) VALUES(991802,?,'EU'), (991802,?,'EU')", OWNER, OTHER);
        jdbc.update("INSERT INTO groupbuy_team(id,campaign_id,region,leader_user_id,status,member_count,expire_at) VALUES(991803,1,'EU',?,2,99,?)", OWNER, LocalDateTime.now().plusDays(1));
        jdbc.update("INSERT INTO groupbuy_member(team_id,user_id) VALUES(991803,?), (991803,?)", OWNER, OTHER);
        jdbc.update("INSERT INTO experiment(id,region,name) VALUES(991804,'EU','Synthetic experiment')");
        jdbc.update("INSERT INTO experiment_assignment(experiment_id,user_id,variant) VALUES(991804,?,'A'), (991804,?,'B')", OWNER, OTHER);
        jdbc.update("INSERT INTO review(id,user_id,shop_id,region,user_name,content,score_overall,like_count,helpful_count) VALUES(991901,?,20001,'EU','Other person','Synthetic public review',4,99,99)", OTHER);
        jdbc.update("INSERT INTO post(id,user_id,region,user_name,title,content,like_count) VALUES(991902,?,'EU','Other person','Synthetic public post','Synthetic public content',99)", OTHER);
        jdbc.update("INSERT INTO review_like(review_id,user_id) VALUES(991901,?), (991901,?)", OWNER, OTHER);
        jdbc.update("INSERT INTO review_helpful_vote(review_id,user_id,region) VALUES(991901,?,'EU'), (991901,?,'EU')", OWNER, OTHER);
        jdbc.update("INSERT INTO post_like(post_id,user_id) VALUES(991902,?), (991902,?)", OWNER, OTHER);
        jdbc.update("INSERT INTO user_favorite(user_id,target_type,target_id) VALUES(?,1,20001), (?,1,20001)", OWNER, OTHER);
        jdbc.update("INSERT INTO reservation_slot(id,shop_id,region,biz_date,start_time,end_time,capacity,reserved_count) VALUES(992001,20001,'EU',CURRENT_DATE,'18:00','19:00',10,99)");
        jdbc.update("INSERT INTO reservation(id,reservation_no,user_id,shop_id,slot_id,region,reserve_time,people_count,contact_name,contact_phone,remark,status) VALUES(992002,'SYNTHETIC-RESERVATION',?,20001,992001,'EU',CURRENT_TIMESTAMP,3,?,?,?,1), (992003,'OTHER-RESERVATION',?,20001,992001,'EU',CURRENT_TIMESTAMP,2,?,?,?,1)", OWNER, PERSONAL, PERSONAL, PERSONAL, OTHER, OTHER_PRIVATE, OTHER_PRIVATE, OTHER_PRIVATE);
        jdbc.update("INSERT INTO points_product(id,region,name,points_price,stock,exchange_count) VALUES(992101,'EU','Synthetic points product',5,5,3)");
        jdbc.update("INSERT INTO points_exchange(id,user_id,product_id,product_name,region,points_cost,status,redeem_code,remark) VALUES(992102,?,992101,'Synthetic points product','EU',5,0,'synthetic-pending-code',?), (992103,?,992101,'Synthetic points product','EU',5,1,'synthetic-issued-code',?)", OWNER, PERSONAL, OWNER, PERSONAL);
        jdbc.update("INSERT INTO `order`(id,order_no,user_id,deal_id,shop_id,region,quantity,unit_price,amount,currency,pay_status) VALUES(992201,'SYNTHETIC-ORDER',?,1,20001,'EU',1,20,20,'EUR',1)", OWNER);
        jdbc.update("INSERT INTO payment(id,order_id,order_no,channel,channel_txn,client_secret,amount,currency,status,raw_response) VALUES(992202,992201,'SYNTHETIC-ORDER','stripe','synthetic-payment-txn','synthetic-client-secret',20,'EUR',1,'synthetic-raw-payment')");
        jdbc.update("INSERT INTO refund(id,order_id,amount,reason,status) VALUES(992203,992201,20,?,0)", PERSONAL);
        jdbc.update("INSERT INTO marketing_coupon_template(id,region,name,claimed_quantity) VALUES(992204,'EU','Synthetic discount',3)");
        jdbc.update("INSERT INTO user_coupon(id,template_id,user_id,region,status,used_order_id) VALUES(992205,992204,?,'EU',1,NULL), (992206,992204,?,'EU',2,992201), (992207,992204,?,'EU',1,NULL)", OWNER, OWNER, OTHER);
        jdbc.update("INSERT INTO invoice_request(id,user_id,region,order_id,title_id,amount,tax_amount,currency) VALUES(992208,?,'EU',992201,991102,20,2,'EUR')", OWNER);
        jdbc.update("INSERT INTO user_device(user_id,device_uid,platform,push_token) VALUES(?,?,1,'synthetic-push-token')", OWNER, PERSONAL);
        jdbc.update("INSERT INTO user_session(user_id,refresh_token_hash,refresh_expire_at) VALUES(?,'synthetic-refresh-hash',?)", OWNER, LocalDateTime.now().plusDays(1));
    }
}
