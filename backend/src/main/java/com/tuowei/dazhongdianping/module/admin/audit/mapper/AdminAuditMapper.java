package com.tuowei.dazhongdianping.module.admin.audit.mapper;

import com.tuowei.dazhongdianping.module.admin.audit.model.AdminAuditLogQuery;
import com.tuowei.dazhongdianping.module.admin.audit.model.AdminAuditSlaAlertQuery;
import com.tuowei.dazhongdianping.module.admin.audit.model.AdminAuditSlaAlertRow;
import com.tuowei.dazhongdianping.module.admin.audit.model.AdminAuditTaskQuery;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditQueueMetricRow;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditQueueOverdueRow;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditQueueSlaThreshold;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditLogRow;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditTaskRow;
import com.tuowei.dazhongdianping.module.admin.audit.model.ModeratedContentRow;
import java.util.List;
import org.apache.ibatis.annotations.Param;

public interface AdminAuditMapper {

    void insertAuditTask(AuditTaskRow row);

    long countAuditLogs(AdminAuditLogQuery query);

    List<AuditLogRow> selectAuditLogs(AdminAuditLogQuery query);

    long countAuditTasks(AdminAuditTaskQuery query);

    List<AuditTaskRow> selectAuditTasks(AdminAuditTaskQuery query);

    List<AuditQueueMetricRow> selectModerationQueueMetrics(@Param("region") String region,
                                                           @Param("allowedBizTypes") List<Integer> allowedBizTypes);

    List<AuditQueueOverdueRow> selectModerationQueueOverdueCounts(@Param("region") String region,
                                                                  @Param("allowedBizTypes") List<Integer> allowedBizTypes,
                                                                  @Param("slaThresholds") List<AuditQueueSlaThreshold> slaThresholds);

    int upsertAdminAuditSlaAlert(@Param("region") String region,
                                 @Param("bizType") Integer bizType,
                                 @Param("pendingCount") Long pendingCount,
                                 @Param("overdueCount") Long overdueCount,
                                 @Param("oldestPendingAt") java.time.LocalDateTime oldestPendingAt);

    int resolveAdminAuditSlaAlert(@Param("region") String region, @Param("bizType") Integer bizType);

    long countAdminAuditSlaAlerts(AdminAuditSlaAlertQuery query);

    List<AdminAuditSlaAlertRow> selectAdminAuditSlaAlerts(AdminAuditSlaAlertQuery query);

    AuditTaskRow selectAuditTaskById(@Param("taskId") Long taskId);

    AuditTaskRow selectPendingAuditTaskByBiz(@Param("bizType") Integer bizType,
                                             @Param("bizId") Long bizId);

    int invalidatePendingAuditTasksByBiz(@Param("bizType") Integer bizType,
                                         @Param("bizId") Long bizId,
                                         @Param("remark") String remark);

    int invalidatePendingCommentAuditTasksByParent(@Param("bizType") Integer bizType,
                                                   @Param("parentId") Long parentId,
                                                   @Param("remark") String remark);

    int invalidatePendingCommentAuditTasksByContent(@Param("bizType") Integer bizType,
                                                    @Param("contentId") Long contentId,
                                                    @Param("remark") String remark);

    int updateAuditTaskDecision(@Param("taskId") Long taskId,
                                @Param("status") Integer status,
                                @Param("auditorId") Long auditorId,
                                @Param("remark") String remark);

    int claimPendingModeratedAuditTask(@Param("taskId") Long taskId,
                                       @Param("adminId") Long adminId,
                                       @Param("leaseMinutes") Integer leaseMinutes);

    int releasePendingModeratedAuditTask(@Param("taskId") Long taskId, @Param("adminId") Long adminId);

    int updateClaimedModeratedAuditTaskDecision(@Param("taskId") Long taskId,
                                                @Param("status") Integer status,
                                                @Param("adminId") Long adminId,
                                                @Param("remark") String remark);

    ModeratedContentRow selectModeratedContent(@Param("bizType") Integer bizType, @Param("bizId") Long bizId);

    int updateModeratedContentStatus(@Param("bizType") Integer bizType,
                                     @Param("bizId") Long bizId,
                                     @Param("status") Integer status,
                                     @Param("remark") String remark);

    int updateDealAuditDecision(@Param("dealId") Long dealId,
                                @Param("region") String region,
                                @Param("auditStatus") Integer auditStatus,
                                @Param("rejectReason") String rejectReason);

    int updatePostAuditDecision(@Param("postId") Long postId,
                                @Param("region") String region,
                                @Param("auditStatus") Integer auditStatus,
                                @Param("auditRemark") String auditRemark);

    void insertAuditLog(@Param("adminId") Long adminId,
                        @Param("action") String action,
                        @Param("target") String target,
                        @Param("detail") String detail,
                        @Param("ip") String ip);

    String selectLatestAuditLogDetail(@Param("action") String action,
                                      @Param("target") String target);
}
