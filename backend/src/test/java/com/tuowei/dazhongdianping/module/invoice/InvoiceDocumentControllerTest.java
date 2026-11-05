package com.tuowei.dazhongdianping.module.invoice;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.auth.service.UserPrivacyService;
import com.tuowei.dazhongdianping.module.auth.model.request.PrivacyExportTaskCreateRequest;
import com.tuowei.dazhongdianping.module.auth.mapper.AuthCommandMapper;
import java.io.ByteArrayOutputStream;
import java.time.LocalDateTime;
import java.util.List;
import java.util.zip.ZipFile;
import java.util.concurrent.*;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.encryption.StandardProtectionPolicy;
import org.apache.pdfbox.pdmodel.encryption.AccessPermission;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.test.annotation.DirtiesContext;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.math.BigDecimal;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class InvoiceDocumentControllerTest {
    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private UserPrivacyService privacy;
    @Autowired private AuthCommandMapper accounts;
    @Autowired private PlatformTransactionManager transactions;
    @Autowired private org.mybatis.spring.SqlSessionTemplate sqlSession;

    @Test
    void deliversPrivatePdfWithExplicitIdempotentReceiptAndImmutableRetry() throws Exception {
        Registered owner = register();
        Registered other = register();
        long id = invoice(owner);
        String admin = adminToken();
        byte[] pdf = pdf(false, true);
        mockMvc.perform(get("/api/c/v1/invoices/{id}/document", id)).andExpect(status().isUnauthorized());
        mockMvc.perform(get("/api/c/v1/invoices/{id}/document", id).header("Authorization", bearer(owner.token())))
                .andExpect(status().isNotFound());
        MvcResult published = upload(id, admin, "INV-PDF-1", pdf).andExpect(status().isOk())
                .andExpect(jsonPath("$.data.documentAvailable").value(true))
                .andExpect(jsonPath("$.data.documentFileName").value("invoice-" + id + ".pdf"))
                .andExpect(jsonPath("$.data.status").value(2))
                .andExpect(jsonPath("$.data.receivedAt").isEmpty()).andReturn();
        String hash = objectMapper.readTree(published.getResponse().getContentAsString()).at("/data/documentSha256").asText();
        assertThat(hash).hasSize(64);
        mockMvc.perform(get("/api/c/v1/invoices/{id}/document", id).header("Authorization", bearer(owner.token())))
                .andExpect(status().isOk()).andExpect(content().bytes(pdf))
                .andExpect(content().contentType("application/pdf"))
                .andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(header().string("X-Content-Type-Options", "nosniff"))
                .andExpect(header().string("Content-Disposition", "attachment; filename=\"invoice-" + id + ".pdf\""));
        assertThat(jdbc.queryForObject("SELECT received_at FROM invoice_document WHERE invoice_id=?", LocalDateTime.class, id)).isNull();
        mockMvc.perform(get("/api/c/v1/invoices/{id}/document", id).header("Authorization", bearer(other.token())))
                .andExpect(status().isNotFound());
        mockMvc.perform(get("/api/c/v1/invoices/{id}/document", id).header("Authorization", bearer(owner.token())).header("X-Region", "EU"))
                .andExpect(status().isNotFound());
        mockMvc.perform(get("/api/admin/v1/invoices/{id}/document", id).header("Authorization", bearer(admin)))
                .andExpect(status().isOk()).andExpect(content().bytes(pdf));
        mockMvc.perform(get("/api/admin/v1/invoices/{id}/document", id).header("Authorization", bearer(admin)).header("X-Region", "EU"))
                .andExpect(status().isNotFound());
        upload(id, admin, "INV-PDF-1", pdf).andExpect(status().isOk());
        upload(id, admin, "DIFFERENT-NUMBER", pdf).andExpect(status().isConflict());
        upload(id, admin, "INV-PDF-1", pdf(false, true)).andExpect(status().isConflict());
        assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM audit_log WHERE action='invoice.document.publish' AND target=?", Integer.class, "invoice:" + id)).isEqualTo(1);
        receipt(id, other.token(), hash).andExpect(status().isNotFound());
        receipt(id, owner.token(), "0".repeat(64)).andExpect(status().isConflict());
        receipt(id, owner.token(), hash).andExpect(status().isOk()).andExpect(jsonPath("$.data.receivedAt").isNotEmpty());
        LocalDateTime received = jdbc.queryForObject("SELECT received_at FROM invoice_document WHERE invoice_id=?", LocalDateTime.class, id);
        receipt(id, owner.token(), hash).andExpect(status().isOk());
        assertThat(jdbc.queryForObject("SELECT received_at FROM invoice_document WHERE invoice_id=?", LocalDateTime.class, id)).isEqualTo(received);
        mockMvc.perform(get("/api/c/v1/invoices").header("Authorization", bearer(owner.token())))
                .andExpect(jsonPath("$.data.list[0].documentSha256").value(hash))
                .andExpect(jsonPath("$.data.list[0].content").doesNotExist())
                .andExpect(jsonPath("$.data.list[0].uploadedBy").doesNotExist());
    }

    @Test
    void rejectsInvalidEncryptedEmptyAndOversizedPdfWithoutChangingRequest() throws Exception {
        long id = invoice(register());
        String admin = adminToken();
        for (byte[] bytes : List.of(new byte[0], "not a PDF".getBytes(), "%PDF-1.7 broken".getBytes(),
                pdf(true, true), pdf(false, false), new byte[5 * 1024 * 1024 + 1])) {
            upload(id, admin, "INV-INVALID", bytes).andExpect(status().isBadRequest());
            assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM invoice_document WHERE invoice_id=?", Integer.class, id)).isZero();
            assertThat(jdbc.queryForObject("SELECT status FROM invoice_request WHERE id=?", Integer.class, id)).isEqualTo(1);
        }
        upload(id, admin, " ", pdf(false, true)).andExpect(status().isBadRequest());
    }

    @Test
    void backfillsRegisteredInvoicesAndRejectsRejectedOrInactiveAccounts() throws Exception {
        Registered owner = register();
        long id = invoice(owner);
        String admin = adminToken();
        jdbc.update("UPDATE invoice_request SET status=2,invoice_no='LEGACY' WHERE id=?", id);
        upload(id, admin, "LEGACY", pdf(false, true)).andExpect(status().isOk());
        long rejected = invoice(owner);
        jdbc.update("UPDATE invoice_request SET status=3 WHERE id=?", rejected);
        upload(rejected, admin, "REJECTED", pdf(false, true)).andExpect(status().isConflict());
        long pending = invoice(owner);
        jdbc.update("UPDATE app_user SET status=2 WHERE id=?", owner.userId());
        upload(pending, admin, "INACTIVE", pdf(false, true)).andExpect(status().isConflict());
        jdbc.update("UPDATE app_user SET is_deleted=TRUE WHERE id=?", owner.userId());
        upload(pending, admin, "DELETED", pdf(false, true)).andExpect(status().isConflict());
    }

    @Test
    void enforcesDistinctAdminReadWritePermissionsAndRegionScope() throws Exception {
        long id = invoice(register());
        String admin = adminToken();
        byte[] pdf = pdf(false, true);
        mockMvc.perform(multipart("/api/admin/v1/invoices/{id}/document", id)
                .file(new MockMultipartFile("file", "invoice.pdf", "application/pdf", pdf)).param("invoiceNo", "X"))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(multipart("/api/admin/v1/invoices/{id}/document", id)
                .file(new MockMultipartFile("file", "invoice.pdf", "application/pdf", pdf)).param("invoiceNo", "X")
                .header("Authorization", bearer(admin)).header("X-Region", "EU")).andExpect(status().isNotFound());
        jdbc.update("DELETE FROM admin_role_permission WHERE permission_id IN (SELECT id FROM admin_permission WHERE code='finance:invoice:write')");
        sqlSession.clearCache();
        upload(id, admin, "X", pdf).andExpect(status().isForbidden());
        mockMvc.perform(get("/api/admin/v1/invoices/{id}/document", id).header("Authorization", bearer(admin)))
                .andExpect(status().isNotFound());
        jdbc.update("DELETE FROM admin_role_permission WHERE permission_id IN (SELECT id FROM admin_permission WHERE code='finance:invoice:read')");
        sqlSession.clearCache();
        mockMvc.perform(get("/api/admin/v1/invoices/{id}/document", id).header("Authorization", bearer(admin)))
                .andExpect(status().isForbidden());
    }

    @Test
    void privacyArchiveIncludesOnlyOwnedPdfsWhenRequestedAndDeletionPurgesThem() throws Exception {
        Registered owner = register();
        Registered other = register();
        long id = invoice(owner);
        long euId = invoice(owner);
        long otherId = invoice(other);
        String admin = adminToken();
        byte[] bytes = pdf(false, true);
        upload(id, admin, "OWNER", bytes).andExpect(status().isOk());
        upload(euId, admin, "OWNER-EU", bytes).andExpect(status().isOk());
        jdbc.update("UPDATE `order` SET region='EU' WHERE id=(SELECT order_id FROM invoice_request WHERE id=?)", euId);
        jdbc.update("UPDATE invoice_title SET region='EU' WHERE id=(SELECT title_id FROM invoice_request WHERE id=?)", euId);
        jdbc.update("UPDATE invoice_request SET region='EU' WHERE id=?", euId);
        sqlSession.clearCache();
        upload(otherId, admin, "OTHER", bytes).andExpect(status().isOk());
        try {
            UserSessionContext.set(new UserSession(owner.userId(), 1L));
            PrivacyExportTaskCreateRequest request = new PrivacyExportTaskCreateRequest();
            request.setModules(List.of("invoices"));
            var task = privacy.createExportTask(request);
            try (ZipFile zip = archive(task.id())) {
                assertThat(zip.getEntry("invoices/invoice-" + id + ".pdf")).isNotNull();
                assertThat(zip.getInputStream(zip.getEntry("invoices/invoice-" + id + ".pdf")).readAllBytes()).isEqualTo(bytes);
                assertThat(zip.getInputStream(zip.getEntry("invoices/invoice-" + euId + ".pdf")).readAllBytes()).isEqualTo(bytes);
                assertThat(zip.getEntry("invoices/invoice-" + otherId + ".pdf")).isNull();
                JsonNode payload = objectMapper.readTree(zip.getInputStream(zip.entries().nextElement()));
                String exported = payload.toString();
                assertThat(exported).contains("documents", "sha256", "invoice-" + id + ".pdf").doesNotContain("uploadedBy");
            }
            request.setModules(List.of("account"));
            var accountOnly = privacy.createExportTask(request);
            try (ZipFile zip = archive(accountOnly.id())) { assertThat(zip.size()).isEqualTo(1); }
            jdbc.update("INSERT INTO privacy_delete_task(user_id,verify_type,account_snapshot,reason,status,cooling_off_expire_at) VALUES(?,'password','','',1,?)",
                    owner.userId(), LocalDateTime.now().minusDays(1));
            privacy.processDueDeleteTasksForUser(owner.userId());
            assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM invoice_document WHERE invoice_id=?", Integer.class, id)).isZero();
            assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM invoice_document WHERE invoice_id=?", Integer.class, euId)).isZero();
            assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM invoice_document WHERE invoice_id=?", Integer.class, otherId)).isEqualTo(1);
            assertThat(jdbc.queryForObject("SELECT amount FROM invoice_request WHERE id=?", BigDecimal.class, id)).isEqualByComparingTo("88.00");
        } finally { UserSessionContext.clear(); }
        upload(id, admin, "OWNER", bytes).andExpect(status().isConflict());
    }

    @Test
    @Transactional(propagation = Propagation.NOT_SUPPORTED)
    @DirtiesContext(methodMode = DirtiesContext.MethodMode.AFTER_METHOD)
    void uploadWaitsForAccountDeletionAndCannotRecreatePdfAfterCommit() throws Exception {
        Registered owner = register();
        long id = invoice(owner);
        String admin = adminToken();
        byte[] bytes = pdf(false, true);
        ExecutorService executor = Executors.newSingleThreadExecutor();
        try {
            Future<?>[] pending = new Future<?>[1];
            new TransactionTemplate(transactions).executeWithoutResult(tx -> {
                accounts.selectUserByIdForUpdate(owner.userId());
                CountDownLatch started = new CountDownLatch(1);
                pending[0] = executor.submit(() -> {
                    started.countDown();
                    try { upload(id, admin, "RACING", bytes).andExpect(status().isConflict()); }
                    catch (Exception ex) { throw new RuntimeException(ex); }
                });
                try { assertThat(started.await(3, TimeUnit.SECONDS)).isTrue(); }
                catch (InterruptedException ex) { throw new RuntimeException(ex); }
                assertThatThrownBy(() -> pending[0].get(250, TimeUnit.MILLISECONDS)).isInstanceOf(TimeoutException.class);
                jdbc.update("UPDATE app_user SET status=2,is_deleted=TRUE WHERE id=?", owner.userId());
            });
            pending[0].get(10, TimeUnit.SECONDS);
            assertThat(jdbc.queryForObject("SELECT COUNT(*) FROM invoice_document WHERE invoice_id=?", Integer.class, id)).isZero();
        } finally { executor.shutdownNow(); }
    }

    private ZipFile archive(long taskId) throws Exception {
        return new ZipFile(jdbc.queryForObject("SELECT file_path FROM privacy_export_task WHERE id=?", String.class, taskId));
    }

    private org.springframework.test.web.servlet.ResultActions receipt(long id, String token, String hash) throws Exception {
        return mockMvc.perform(post("/api/c/v1/invoices/{id}/receipt", id).header("Authorization", bearer(token))
                .contentType(MediaType.APPLICATION_JSON).content("{\"sha256\":\"" + hash + "\"}"));
    }

    private org.springframework.test.web.servlet.ResultActions upload(long id, String token, String number, byte[] pdf) throws Exception {
        return mockMvc.perform(multipart("/api/admin/v1/invoices/{id}/document", id)
                .file(new MockMultipartFile("file", "../../untrusted.pdf", "application/pdf", pdf))
                .param("invoiceNo", number).header("Authorization", bearer(token)).header("X-Region", "CN"));
    }

    private byte[] pdf(boolean encrypted, boolean page) throws Exception {
        try (PDDocument doc = new PDDocument(); ByteArrayOutputStream bytes = new ByteArrayOutputStream()) {
            if (page) doc.addPage(new PDPage());
            doc.getDocumentInformation().setTitle(UUID.randomUUID().toString());
            if (encrypted) doc.protect(new StandardProtectionPolicy("owner", "secret", new AccessPermission()));
            doc.save(bytes);
            return bytes.toByteArray();
        }
    }

    private long invoice(Registered user) throws Exception {
        long order = insertOrder(user.userId(), 1, "88.00");
        MvcResult title = mockMvc.perform(post("/api/c/v1/invoices/titles")
                .header("Authorization", bearer(user.token())).contentType(MediaType.APPLICATION_JSON)
                .content("{\"titleType\":2,\"name\":\"Test company\",\"taxNo\":\"TAX-TEST\"}"))
                .andExpect(status().isOk()).andReturn();
        long titleId = objectMapper.readTree(title.getResponse().getContentAsString()).at("/data/id").asLong();
        MvcResult result = mockMvc.perform(post("/api/c/v1/invoices").header("Authorization", bearer(user.token()))
                .contentType(MediaType.APPLICATION_JSON).content("{\"orderId\":" + order + ",\"titleId\":" + titleId + "}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(result.getResponse().getContentAsString()).at("/data/id").asLong();
    }

    private long insertOrder(long userId, int payStatus, String amount) {
        String orderNo = ("INV" + UUID.randomUUID().toString().replace("-", "")).substring(0, 32);
        jdbc.update("INSERT INTO `order`(order_no,user_id,deal_id,shop_id,region,quantity,unit_price,original_amount,discount_amount,amount,currency,pay_method,pay_status,status,paid_at) "
                        + "VALUES(?,?,40001,10001,'CN',1,?,?,0,?,'CNY','mock',?,1,CURRENT_TIMESTAMP)",
                orderNo, userId, new BigDecimal(amount), new BigDecimal(amount), new BigDecimal(amount), payStatus);
        return jdbc.queryForObject("SELECT id FROM `order` WHERE order_no=?", Long.class, orderNo);
    }

    private Registered register() throws Exception {
        String email = "inv-" + UUID.randomUUID() + "@example.com";
        mockMvc.perform(post("/api/c/v1/auth/send-code").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"scene\":\"register\",\"type\":\"email\",\"account\":\"" + email
                                + "\",\"deviceId\":\"invoice-test\"}"))
                .andExpect(status().isOk());
        MvcResult registered = mockMvc.perform(post("/api/c/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"type\":\"email\",\"account\":\"" + email
                                + "\",\"code\":\"123456\",\"password\":\"Passw0rd!\"}"))
                .andExpect(status().isOk()).andReturn();
        String token = objectMapper.readTree(registered.getResponse().getContentAsString()).at("/data/accessToken").asText();
        Long userId = jdbc.queryForObject("SELECT id FROM app_user WHERE email=?", Long.class, email);
        return new Registered(token, userId);
    }

    private String adminToken() throws Exception {
        MvcResult login = mockMvc.perform(post("/api/admin/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"admin\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk()).andReturn();
        return objectMapper.readTree(login.getResponse().getContentAsString()).at("/data/accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }

    private record Registered(String token, long userId) {
    }
}
