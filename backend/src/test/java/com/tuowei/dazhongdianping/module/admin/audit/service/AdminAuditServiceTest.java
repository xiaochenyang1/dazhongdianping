package com.tuowei.dazhongdianping.module.admin.audit.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.module.admin.auth.service.AdminPermissionChecker;
import com.tuowei.dazhongdianping.module.admin.audit.mapper.AdminAuditMapper;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditTaskRow;
import com.tuowei.dazhongdianping.module.admin.audit.model.request.AdminAuditPassRequest;
import com.tuowei.dazhongdianping.module.admin.audit.model.request.AdminAuditRejectRequest;
import com.tuowei.dazhongdianping.module.auth.certification.model.UserExpertCertificationRow;
import com.tuowei.dazhongdianping.module.auth.certification.service.UserExpertCertificationService;
import com.tuowei.dazhongdianping.module.merchant.review.service.MerchantReviewService;
import com.tuowei.dazhongdianping.module.review.mapper.ReviewMapper;
import com.tuowei.dazhongdianping.module.review.model.ReviewRow;
import com.tuowei.dazhongdianping.module.review.service.ReviewService;
import com.tuowei.dazhongdianping.module.merchant.shop.service.MerchantShopChangeService;
import com.tuowei.dazhongdianping.module.search.event.ShopSearchIndexChangedEvent;
import com.tuowei.dazhongdianping.module.topic.service.TopicService;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicBoolean;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.context.ApplicationEventPublisher;

@ExtendWith(MockitoExtension.class)
class AdminAuditServiceTest {

    @Mock
    private AdminAuditMapper adminAuditMapper;

    @Mock
    private ReviewMapper reviewMapper;

    @Mock
    private ReviewService reviewService;

    @Mock
    private MerchantShopChangeService merchantShopChangeService;

    @Mock
    private MerchantReviewService merchantReviewService;

    @Mock
    private UserExpertCertificationService userExpertCertificationService;

    @Mock
    private ApplicationEventPublisher applicationEventPublisher;

    @Mock
    private TopicService topicService;

    @Spy
    private AdminPermissionChecker permissionChecker = new AdminPermissionChecker();

    @InjectMocks
    private AdminAuditService adminAuditService;

    @AfterEach
    void clearAdminSession() {
        AdminSessionContext.clear();
    }

    @Test
    void shouldAllowOnlyOneConcurrentDecisionToMutateReview() throws Exception {
        AuditTaskRow pendingTask = new AuditTaskRow();
        pendingTask.setId(101L);
        pendingTask.setBizType(3);
        pendingTask.setBizId(201L);
        pendingTask.setRegion("CN");
        pendingTask.setStatus(0);

        ReviewRow review = new ReviewRow();
        review.setId(201L);
        review.setShopId(10001L);

        when(adminAuditMapper.selectAuditTaskById(101L)).thenReturn(pendingTask);
        when(reviewMapper.selectReviewById(201L)).thenReturn(review);
        AtomicBoolean claimed = new AtomicBoolean();
        when(adminAuditMapper.updateAuditTaskDecision(anyLong(), anyInt(), anyLong(), anyString()))
                .thenAnswer(invocation -> claimed.compareAndSet(false, true) ? 1 : 0);
        when(reviewMapper.updateReviewAuditDecision(anyLong(), anyInt(), anyString())).thenReturn(1);

        AdminAuditPassRequest passRequest = new AdminAuditPassRequest();
        passRequest.setRemark("并发通过");
        AdminAuditRejectRequest rejectRequest = new AdminAuditRejectRequest();
        rejectRequest.setReason("并发驳回");

        CountDownLatch ready = new CountDownLatch(2);
        CountDownLatch start = new CountDownLatch(1);
        ExecutorService executor = Executors.newFixedThreadPool(2);
        try {
            Callable<Boolean> pass = concurrentDecision(ready, start,
                    () -> adminAuditService.passTask(101L, passRequest, "127.0.0.1"));
            Callable<Boolean> reject = concurrentDecision(ready, start,
                    () -> adminAuditService.rejectTask(101L, rejectRequest, "127.0.0.1"));
            Future<Boolean> passResult = executor.submit(pass);
            Future<Boolean> rejectResult = executor.submit(reject);

            ready.await();
            start.countDown();

            assertThat(List.of(passResult.get(), rejectResult.get()))
                    .containsExactlyInAnyOrder(true, false);
        } finally {
            executor.shutdownNow();
        }

        verify(reviewMapper, times(1)).updateReviewAuditDecision(anyLong(), anyInt(), anyString());
        verify(applicationEventPublisher, times(1)).publishEvent(any(ShopSearchIndexChangedEvent.class));
        verify(adminAuditMapper, times(1)).insertAuditLog(anyLong(), anyString(), anyString(), anyString(), anyString());
    }

    @Test
    void shouldDispatchExpertCertificationPass() {
        setAdminSession("audit:expert_certification:write");

        AuditTaskRow pendingTask = auditTask(701L, 7, 8801L, "CN", 0, "");
        AuditTaskRow passedTask = auditTask(701L, 7, 8801L, "CN", 1, "资料完整，可授予认证");
        UserExpertCertificationRow certification = new UserExpertCertificationRow();
        certification.setId(8801L);
        certification.setUserId(9001L);
        certification.setRegion("CN");
        certification.setStatus(1);

        when(adminAuditMapper.selectAuditTaskById(701L)).thenReturn(pendingTask, passedTask);
        when(userExpertCertificationService.pendingCertificationForAudit(8801L, "CN")).thenReturn(certification);
        when(adminAuditMapper.updateAuditTaskDecision(701L, 1, 1L, "资料完整，可授予认证")).thenReturn(1);

        AdminAuditPassRequest request = new AdminAuditPassRequest();
        request.setRemark("资料完整，可授予认证");

        var response = adminAuditService.passTask(701L, request, "127.0.0.1");

        assertThat(response.bizType()).isEqualTo(7);
        assertThat(response.bizTypeText()).isEqualTo("达人认证");
        verify(userExpertCertificationService).approveCertification(certification, 1L, "资料完整，可授予认证");
        verify(adminAuditMapper).insertAuditLog(
                1L,
                "audit_expert_certification_pass",
                "expert_certification:8801",
                "资料完整，可授予认证",
                "127.0.0.1"
        );
    }

    @Test
    void shouldDispatchExpertCertificationReject() {
        setAdminSession("audit:expert_certification:write");

        AuditTaskRow pendingTask = auditTask(702L, 7, 8802L, "CN", 0, "");
        AuditTaskRow rejectedTask = auditTask(702L, 7, 8802L, "CN", 2, "公开内容不足，先补更多真实体验");
        UserExpertCertificationRow certification = new UserExpertCertificationRow();
        certification.setId(8802L);
        certification.setUserId(9002L);
        certification.setRegion("CN");
        certification.setStatus(1);

        when(adminAuditMapper.selectAuditTaskById(702L)).thenReturn(pendingTask, rejectedTask);
        when(userExpertCertificationService.pendingCertificationForAudit(8802L, "CN")).thenReturn(certification);
        when(adminAuditMapper.updateAuditTaskDecision(702L, 2, 1L, "公开内容不足，先补更多真实体验")).thenReturn(1);

        AdminAuditRejectRequest request = new AdminAuditRejectRequest();
        request.setReason("公开内容不足，先补更多真实体验");

        var response = adminAuditService.rejectTask(702L, request, "127.0.0.1");

        assertThat(response.bizType()).isEqualTo(7);
        assertThat(response.status()).isEqualTo(2);
        verify(userExpertCertificationService).rejectCertification(certification, 1L, "公开内容不足，先补更多真实体验");
        verify(adminAuditMapper).insertAuditLog(
                1L,
                "audit_expert_certification_reject",
                "expert_certification:8802",
                "公开内容不足，先补更多真实体验",
                "127.0.0.1"
        );
    }

    private Callable<Boolean> concurrentDecision(CountDownLatch ready,
                                                 CountDownLatch start,
                                                 Runnable decision) {
        return () -> {
        AdminSessionContext.set(new AdminSession(
                1L,
                "admin",
                "系统管理员",
                java.util.Set.of("audit:review:write"),
                java.util.Set.of("CN", "EU")
        ));
            ready.countDown();
            start.await();
            try {
                decision.run();
                return true;
            } catch (IllegalArgumentException exception) {
                return false;
            } finally {
                AdminSessionContext.clear();
            }
        };
    }

    private void setAdminSession(String permission) {
        AdminSessionContext.set(new AdminSession(
                1L,
                "admin",
                "系统管理员",
                java.util.Set.of(permission),
                java.util.Set.of("CN", "EU")
        ));
    }

    private AuditTaskRow auditTask(Long taskId,
                                   Integer bizType,
                                   Long bizId,
                                   String region,
                                   Integer status,
                                   String remark) {
        AuditTaskRow row = new AuditTaskRow();
        row.setId(taskId);
        row.setBizType(bizType);
        row.setBizId(bizId);
        row.setRegion(region);
        row.setStatus(status);
        row.setRemark(remark);
        return row;
    }
}
