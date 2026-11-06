package com.tuowei.dazhongdianping.module.creator;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.auth.mapper.AuthCommandMapper;
import com.tuowei.dazhongdianping.module.auth.model.request.PrivacyExportTaskCreateRequest;
import com.tuowei.dazhongdianping.module.auth.service.UserPrivacyService;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.zip.ZipFile;
import org.junit.jupiter.api.Test;
import org.mybatis.spring.SqlSessionTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

@SpringBootTest(properties = {"app.launch.deferred-features-enabled=true", "app.privacy.delete-initial-delay-ms=3600000"})
@AutoConfigureMockMvc
@Transactional
class CreatorReviewControllerTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired JdbcTemplate jdbc;
    @Autowired SqlSessionTemplate sql;
    @Autowired UserPrivacyService privacy;
    @Autowired AuthCommandMapper accounts;
    @Autowired PlatformTransactionManager transactions;

    @Test
    void submitsRejectsResubmitsAndAwardsFrozenPointsExactlyOnce() throws Exception {
        Session owner = register();
        String admin = admin();
        long work = work(owner, "post", "CN", true);
        jdbc.update("UPDATE post SET shop_id=10001 WHERE id=?", work);
        jdbc.update("INSERT INTO post_image(post_id,url,sort_no) VALUES(?,'https://example.invalid/work.jpg',0)", work);
        claim(owner, 9101);
        jdbc.update("UPDATE creator_task SET title='Changed task',description='Changed terms',reward_points=999,status=0 WHERE id=9101");
        sql.clearCache();
        JsonNode submitted = data(submit(owner, 9101, "post", work, "Work meets the original requirements").andExpect(status().isOk()));
        assertThat(submitted.path("claimStatus").asInt()).isEqualTo(3);
        assertThat(submitted.path("rewardPoints").asInt()).isEqualTo(20);
        assertThat(submitted.path("evidence").path("images").get(0).asText()).endsWith("work.jpg");
        assertThat(submitted.path("evidence").path("shopId").asLong()).isEqualTo(10001);
        assertThat(submitted.path("evidence").path("createdAt").asText()).isNotEmpty();
        assertThat(submitted.path("evidence").path("updatedAt").asText()).isNotEmpty();
        assertThat(submitted.path("taskTitle").asText()).isNotEqualTo("Changed task");
        assertThat(points(owner)).isZero();
        submit(owner, 9101, "post", work, "Work meets the original requirements")
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.submissionVersion").value(1));
        submit(owner, 9101, "post", work, "Changed while pending").andExpect(status().isConflict());
        decide(admin, submitted, false, " ").andExpect(status().isBadRequest());
        decide(admin, submitted, false, "Please add the menu photo").andExpect(status().isOk())
                .andExpect(jsonPath("$.data.claimStatus").value(4));
        decide(admin, submitted, false, "Please add the menu photo").andExpect(status().isOk());
        assertThat(points(owner)).isZero();
        JsonNode revised = data(submit(owner, 9101, "post", work, "Updated submission").andExpect(status().isOk()));
        assertThat(revised.path("submissionVersion").asInt()).isEqualTo(2);
        decide(admin, submitted, true, "").andExpect(status().isConflict());
        decide(admin, revised, true, "Verified").andExpect(status().isOk())
                .andExpect(jsonPath("$.data.claimStatus").value(2)).andExpect(jsonPath("$.data.completedAt").isNotEmpty());
        decide(admin, revised, true, "Verified").andExpect(status().isOk());
        decide(admin, revised, false, "Too late").andExpect(status().isConflict());
        submit(owner, 9101, "post", work, "Again").andExpect(status().isConflict());
        assertThat(points(owner)).isEqualTo(20);
        assertThat(count("SELECT COUNT(*) FROM growth_points_log WHERE user_id=? AND action='creator_task'", owner.id())).isEqualTo(1);
        assertThat(count("SELECT COUNT(*) FROM audit_log WHERE action='creator.claim.approve' AND target=?", "creator_claim:" + revised.path("id").asLong())).isEqualTo(1);
        assertThat(count("SELECT COUNT(*) FROM audit_log WHERE action='creator.claim.reject' AND target=?", "creator_claim:" + revised.path("id").asLong())).isEqualTo(1);
        mvc.perform(get("/api/c/v1/creator/tasks").header("Authorization", bearer(owner.token())))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.list[?(@.id==9101)].rewardPoints").value(org.hamcrest.Matchers.hasItem(20)));
    }

    @Test
    void onlyAcceptsOwnedPublicWorkInTheClaimedRegionAndValidatesInputs() throws Exception {
        Session owner = register();
        Session other = register();
        long own = work(owner, "review", "CN", true);
        long foreign = work(other, "review", "CN", true);
        long eu = work(owner, "post", "EU", true);
        long pending = work(owner, "post", "CN", false);
        mvc.perform(get("/api/c/v1/creator/evidence").param("type", "post")).andExpect(status().isUnauthorized());
        submit(owner, 9101, "review", own, "").andExpect(status().isNotFound());
        claim(owner, 9101);
        submit(other, 9101, "review", own, "").andExpect(status().isNotFound());
        submit(owner, 9101, "review", foreign, "").andExpect(status().isNotFound());
        submit(owner, 9101, "post", eu, "").andExpect(status().isNotFound());
        submit(owner, 9101, "post", pending, "").andExpect(status().isNotFound());
        submit(owner, 9101, "review", -1, "").andExpect(status().isBadRequest());
        submit(owner, 9101, "unknown", own, "").andExpect(status().isBadRequest());
        submit(owner, 9101, "review", own, "x".repeat(1001)).andExpect(status().isBadRequest());
        jdbc.update("UPDATE review SET status=0 WHERE id=?", own); sql.clearCache();
        submit(owner, 9101, "review", own, "").andExpect(status().isNotFound());
        jdbc.update("UPDATE review SET status=1,is_deleted=TRUE WHERE id=?", own); sql.clearCache();
        submit(owner, 9101, "review", own, "").andExpect(status().isNotFound());
        assertThat(points(owner)).isZero();
    }

    @Test
    void pagesEvidenceWithoutLeakingOtherUsersUnpublishedOrCrossRegionContent() throws Exception {
        Session owner = register();
        Session other = register();
        List<Long> ids = new ArrayList<>();
        for (int i = 0; i < 23; i++) ids.add(work(owner, "post", "CN", true));
        work(owner, "post", "CN", false); work(owner, "post", "EU", true); work(other, "post", "CN", true);
        JsonNode first = data(mvc.perform(get("/api/c/v1/creator/evidence").param("type", "post")
                .header("Authorization", bearer(owner.token()))).andExpect(status().isOk()));
        assertThat(first.path("total").asInt()).isEqualTo(23);
        assertThat(first.path("list")).hasSize(20);
        assertThat(first.path("hasMore").asBoolean()).isTrue();
        JsonNode second = data(mvc.perform(get("/api/c/v1/creator/evidence").param("type", "post").param("page", "2")
                .header("Authorization", bearer(owner.token()))).andExpect(status().isOk()));
        assertThat(second.path("list")).hasSize(3);
        assertThat(second.path("hasMore").asBoolean()).isFalse();
        List<Long> returned = new ArrayList<>();
        first.path("list").forEach(row -> returned.add(row.path("id").asLong()));
        second.path("list").forEach(row -> returned.add(row.path("id").asLong()));
        java.util.Collections.reverse(ids);
        assertThat(returned).containsExactlyElementsOf(ids);
        for (Map<String, String> query : List.of(Map.of("type", "bad"), Map.of("type", "post", "page", "0"),
                Map.of("type", "post", "pageSize", "51"), Map.of("type", "post", "page", "1000001"))) {
            var request = get("/api/c/v1/creator/evidence").header("Authorization", bearer(owner.token()));
            query.forEach(request::param);
            mvc.perform(request).andExpect(status().isBadRequest());
        }
    }

    @Test
    void rejectsChangedTextAndImagesUntilTheReviewerRefreshesTheWork() throws Exception {
        Session owner = register(); String admin = admin();
        long work = work(owner, "review", "CN", true); claim(owner, 9101);
        JsonNode original = data(submit(owner, 9101, "review", work, "").andExpect(status().isOk()));
        jdbc.update("UPDATE review SET content='Changed public content' WHERE id=?", work); sql.clearCache();
        decide(admin, original, true, "").andExpect(status().isConflict());
        JsonNode refreshed = findClaim(admin, original.path("id").asLong(), 3);
        assertThat(refreshed.path("evidenceHash").asText()).isNotEqualTo(original.path("evidenceHash").asText());
        jdbc.update("INSERT INTO review_image(review_id,url,sort_no) VALUES(?,'https://example.invalid/new-image.jpg',0)", work); sql.clearCache();
        decide(admin, refreshed, true, "").andExpect(status().isConflict());
        JsonNode withImage = findClaim(admin, original.path("id").asLong(), 3);
        assertThat(withImage.path("evidence").path("images")).hasSize(1);
        decide(admin, withImage, true, "Image checked").andExpect(status().isOk());
        assertThat(points(owner)).isEqualTo(20);
    }

    @Test
    void unavailableWorkCanBeRejectedButCannotBeApproved() throws Exception {
        Session owner = register(); String admin = admin();
        long work = work(owner, "post", "CN", true); claim(owner, 9101);
        JsonNode submitted = data(submit(owner, 9101, "post", work, "").andExpect(status().isOk()));
        jdbc.update("UPDATE post SET is_deleted=TRUE WHERE id=?", work); sql.clearCache();
        decide(admin, submitted, true, "").andExpect(status().isConflict());
        JsonNode missing = findClaim(admin, submitted.path("id").asLong(), 3);
        assertThat(missing.path("evidence").isNull()).isTrue();
        assertThat(missing.path("evidenceHash").isNull()).isTrue();
        decide(admin, missing, false, "Please submit a public post").andExpect(status().isOk());
        assertThat(points(owner)).isZero();
    }

    @Test
    void enforcesAdminPermissionsAndRegionBeforeReadingOrAwarding() throws Exception {
        Session owner = register(); String admin = admin();
        long work = work(owner, "post", "CN", true); claim(owner, 9101);
        JsonNode submitted = data(submit(owner, 9101, "post", work, "").andExpect(status().isOk()));
        mvc.perform(get("/api/admin/v1/creator/claims")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/admin/v1/creator/claims").header("Authorization", bearer(admin)).header("X-Region", "EU"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.total").value(0));
        mvc.perform(post("/api/admin/v1/creator/claims/{id}/review", submitted.path("id").asLong())
                .header("Authorization", bearer(admin)).header("X-Region", "EU").contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsString(decision(submitted, false, "Wrong region")))).andExpect(status().isNotFound());
        jdbc.update("DELETE FROM admin_role_permission WHERE permission_id IN (SELECT id FROM admin_permission WHERE code='operations:creator:write')"); sql.clearCache();
        decide(admin, submitted, true, "").andExpect(status().isForbidden());
        findClaim(admin, submitted.path("id").asLong(), 3);
        jdbc.update("DELETE FROM admin_role_permission WHERE permission_id IN (SELECT id FROM admin_permission WHERE code='operations:creator:read')"); sql.clearCache();
        mvc.perform(get("/api/admin/v1/creator/claims").header("Authorization", bearer(admin))).andExpect(status().isForbidden());
        assertThat(points(owner)).isZero();
    }

    @Test
    void invalidReviewOverflowAndInactiveAccountCannotPartiallyAward() throws Exception {
        Session owner = register(); String admin = admin();
        long work = work(owner, "post", "CN", true); claim(owner, 9101);
        JsonNode submitted = data(submit(owner, 9101, "post", work, "").andExpect(status().isOk()));
        Map<String, Object> invalid = decision(submitted, true, ""); invalid.put("evidenceHash", null);
        mvc.perform(post("/api/admin/v1/creator/claims/{id}/review", submitted.path("id").asLong())
                .header("Authorization", bearer(admin)).contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(invalid)))
                .andExpect(status().isBadRequest());
        jdbc.update("UPDATE app_user SET points=? WHERE id=?", Integer.MAX_VALUE - 10, owner.id()); sql.clearCache();
        decide(admin, submitted, true, "").andExpect(status().isConflict());
        assertThat(points(owner)).isEqualTo(Integer.MAX_VALUE - 10);
        jdbc.update("UPDATE app_user SET points=0,status=2 WHERE id=?", owner.id()); sql.clearCache();
        decide(admin, submitted, true, "").andExpect(status().isConflict());
        assertThat(count("SELECT status FROM creator_task_claim WHERE id=?", submitted.path("id").asLong())).isEqualTo(3);
        assertThat(count("SELECT COUNT(*) FROM growth_points_log WHERE user_id=? AND action='creator_task'", owner.id())).isZero();
    }

    @Test
    void privacyExportsSubmissionAndScrubsNotesWhileRetainingOnlyAnonymousAwards() throws Exception {
        Session owner = register(); String admin = admin();
        long work = work(owner, "post", "CN", true); claim(owner, 9101);
        JsonNode awarded = data(submit(owner, 9101, "post", work, "Personal submission note").andExpect(status().isOk()));
        decide(admin, awarded, true, "Personal review note").andExpect(status().isOk());
        jdbc.update("INSERT INTO creator_task_claim(task_id,user_id,region,status,submission_note) VALUES(9110,?,'CN',3,'Pending note'),(9111,?,'CN',4,'Rejected note')", owner.id(), owner.id());
        Path archive = null;
        try {
            UserSessionContext.set(new UserSession(owner.id(), 1L));
            var request = new PrivacyExportTaskCreateRequest(); request.setModules(List.of("activities"));
            var task = privacy.createExportTask(request);
            archive = Path.of(jdbc.queryForObject("SELECT file_path FROM privacy_export_task WHERE id=?", String.class, task.id()));
            try (ZipFile zip = new ZipFile(archive.toFile())) {
                JsonNode payload = json.readTree(zip.getInputStream(zip.entries().nextElement()));
                assertThat(payload.at("/modules/activities/creatorClaims")).hasSize(3);
                assertThat(payload.toString()).contains("Personal submission note", "Personal review note", "submissionVersion", "evidenceId");
            }
            jdbc.update("INSERT INTO privacy_delete_task(user_id,verify_type,account_snapshot,reason,status,cooling_off_expire_at) VALUES(?,'password','','',1,?)", owner.id(), LocalDateTime.now().minusDays(1));
            privacy.processDueDeleteTasksForUser(owner.id());
            assertThat(count("SELECT COUNT(*) FROM creator_task_claim WHERE user_id=?", owner.id())).isZero();
            assertThat(count("SELECT status FROM creator_task_claim WHERE id=?", awarded.path("id").asLong())).isEqualTo(2);
            Map<String, Object> row = jdbc.queryForMap("SELECT user_id,evidence_id,submission_note,review_note FROM creator_task_claim WHERE id=?", awarded.path("id").asLong());
            assertThat(row.get("user_id")).isNull(); assertThat(row.get("evidence_id")).isNull();
            assertThat(row.get("submission_note")).isEqualTo(""); assertThat(row.get("review_note")).isEqualTo("");
        } finally {
            UserSessionContext.clear();
            if (archive != null) Files.deleteIfExists(archive);
        }
    }

    @Test
    @Transactional(propagation = Propagation.NOT_SUPPORTED)
    @DirtiesContext(methodMode = DirtiesContext.MethodMode.AFTER_METHOD)
    void concurrentApprovalsAwardOneLedgerEntry() throws Exception {
        Session owner = register(); String admin = admin();
        long work = work(owner, "post", "CN", true); claim(owner, 9101);
        JsonNode submitted = data(submit(owner, 9101, "post", work, "").andExpect(status().isOk()));
        var executor = Executors.newFixedThreadPool(2); var start = new CountDownLatch(1);
        try {
            List<Future<Integer>> requests = new ArrayList<>();
            for (int i = 0; i < 2; i++) requests.add(executor.submit(() -> {
                start.await(); return decide(admin, submitted, true, "Verified").andReturn().getResponse().getStatus();
            }));
            start.countDown();
            for (var request : requests) assertThat(request.get(20, TimeUnit.SECONDS)).isEqualTo(200);
            assertThat(points(owner)).isEqualTo(20);
            assertThat(count("SELECT COUNT(*) FROM growth_points_log WHERE user_id=? AND action='creator_task'", owner.id())).isEqualTo(1);
        } finally { executor.shutdownNow(); }
    }

    @Test
    @Transactional(propagation = Propagation.NOT_SUPPORTED)
    @DirtiesContext(methodMode = DirtiesContext.MethodMode.AFTER_METHOD)
    void approvalWaitsForAccountDeletionAndCannotAwardAfterDeletionCommits() throws Exception {
        Session owner = register(); String admin = admin();
        long work = work(owner, "post", "CN", true); claim(owner, 9101);
        JsonNode submitted = data(submit(owner, 9101, "post", work, "").andExpect(status().isOk()));
        var executor = Executors.newSingleThreadExecutor();
        try {
            Future<?>[] pending = new Future<?>[1];
            new TransactionTemplate(transactions).executeWithoutResult(tx -> {
                accounts.selectUserByIdForUpdate(owner.id());
                var started = new CountDownLatch(1);
                pending[0] = executor.submit(() -> {
                    started.countDown();
                    try { decide(admin, submitted, true, "").andExpect(status().isConflict()); }
                    catch (Exception error) { throw new RuntimeException(error); }
                });
                try { assertThat(started.await(3, TimeUnit.SECONDS)).isTrue(); }
                catch (InterruptedException error) { throw new RuntimeException(error); }
                assertThatThrownBy(() -> pending[0].get(200, TimeUnit.MILLISECONDS)).isInstanceOf(TimeoutException.class);
                jdbc.update("UPDATE app_user SET status=2,is_deleted=TRUE WHERE id=?", owner.id());
            });
            pending[0].get(20, TimeUnit.SECONDS);
            assertThat(points(owner)).isZero();
            assertThat(count("SELECT COUNT(*) FROM growth_points_log WHERE user_id=? AND action='creator_task'", owner.id())).isZero();
        } finally { executor.shutdownNow(); }
    }

    private Session register() throws Exception {
        String account = "creator-review-" + UUID.randomUUID() + "@example.com";
        mvc.perform(post("/api/c/v1/auth/send-code").contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsString(Map.of("scene", "register", "type", "email", "account", account, "deviceId", UUID.randomUUID().toString()))))
                .andExpect(status().isOk());
        JsonNode result = data(mvc.perform(post("/api/c/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsString(Map.of("type", "email", "account", account, "code", "123456", "password", "Passw0rd!")))).andExpect(status().isOk()));
        return new Session(result.path("user").path("id").asLong(), result.path("accessToken").asText());
    }

    private String admin() throws Exception {
        return data(mvc.perform(post("/api/admin/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"account\":\"admin\",\"password\":\"admin123456\"}")).andExpect(status().isOk())).path("accessToken").asText();
    }

    private long work(Session owner, String type, String region, boolean published) {
        String content = "Creator work " + UUID.randomUUID();
        if (type.equals("post")) jdbc.update("INSERT INTO post(user_id,region,user_name,title,content,audit_status) VALUES(?,?,'Creator','My work',?,?)", owner.id(), region, content, published ? 1 : 0);
        else jdbc.update("INSERT INTO review(user_id,shop_id,region,user_name,content,score_overall,audit_status) VALUES(?,10001,?,'Creator',?,4.5,?)", owner.id(), region, content, published ? 1 : 0);
        return jdbc.queryForObject("SELECT id FROM " + type + " WHERE user_id=? AND content=?", Long.class, owner.id(), content);
    }

    private void claim(Session owner, long task) throws Exception {
        mvc.perform(post("/api/c/v1/creator/tasks/{id}/claim", task).header("Authorization", bearer(owner.token())))
                .andExpect(status().isOk());
    }

    private ResultActions submit(Session owner, long task, String type, long work, String note) throws Exception {
        return mvc.perform(post("/api/c/v1/creator/tasks/{id}/submit", task).header("Authorization", bearer(owner.token()))
                .contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(Map.of("evidenceType", type, "evidenceId", work, "note", note))));
    }

    private Map<String, Object> decision(JsonNode row, boolean approved, String note) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("approved", approved); body.put("submissionVersion", row.path("submissionVersion").asInt());
        body.put("evidenceHash", row.path("evidenceHash").isNull() ? null : row.path("evidenceHash").asText()); body.put("note", note);
        return body;
    }

    private ResultActions decide(String admin, JsonNode row, boolean approved, String note) throws Exception {
        return mvc.perform(post("/api/admin/v1/creator/claims/{id}/review", row.path("id").asLong())
                .header("Authorization", bearer(admin)).contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(decision(row, approved, note))));
    }

    private JsonNode findClaim(String admin, long id, int status) throws Exception {
        JsonNode page = data(mvc.perform(get("/api/admin/v1/creator/claims").param("status", String.valueOf(status)).param("pageSize", "50")
                .header("Authorization", bearer(admin))).andExpect(status().isOk()));
        for (JsonNode row : page.path("list")) if (row.path("id").asLong() == id) return row;
        throw new AssertionError("Missing claim " + id);
    }

    private JsonNode data(ResultActions result) throws Exception { return json.readTree(result.andReturn().getResponse().getContentAsString()).path("data"); }
    private int points(Session owner) { return jdbc.queryForObject("SELECT points FROM app_user WHERE id=?", Integer.class, owner.id()); }
    private long count(String query, Object... args) { return jdbc.queryForObject(query, Long.class, args); }
    private String bearer(String token) { return "Bearer " + token; }
    private record Session(long id, String token) {}
}
