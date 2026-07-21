package com.tuowei.dazhongdianping.module.admin.audit.mapper;

import com.tuowei.dazhongdianping.module.admin.audit.model.AdminAuditLogQuery;
import com.tuowei.dazhongdianping.module.admin.audit.model.AdminAuditTaskQuery;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditLogRow;
import com.tuowei.dazhongdianping.module.admin.audit.model.AuditTaskRow;
import java.util.List;
import org.apache.ibatis.annotations.Param;

public interface AdminAuditMapper {

    void insertAuditTask(AuditTaskRow row);

    long countAuditLogs(AdminAuditLogQuery query);

    List<AuditLogRow> selectAuditLogs(AdminAuditLogQuery query);

    long countAuditTasks(AdminAuditTaskQuery query);

    List<AuditTaskRow> selectAuditTasks(AdminAuditTaskQuery query);

    AuditTaskRow selectAuditTaskById(@Param("taskId") Long taskId);

    AuditTaskRow selectPendingAuditTaskByBiz(@Param("bizType") Integer bizType,
                                             @Param("bizId") Long bizId);

    int invalidatePendingAuditTasksByBiz(@Param("bizType") Integer bizType,
                                         @Param("bizId") Long bizId,
                                         @Param("remark") String remark);

    int updateAuditTaskDecision(@Param("taskId") Long taskId,
                                @Param("status") Integer status,
                                @Param("auditorId") Long auditorId,
                                @Param("remark") String remark);

    int updateDealAuditDecision(@Param("dealId") Long dealId,
                                @Param("region") String region,
                                @Param("auditStatus") Integer auditStatus);

    int updatePostAuditDecision(@Param("postId") Long postId,
                                @Param("region") String region,
                                @Param("auditStatus") Integer auditStatus,
                                @Param("auditRemark") String auditRemark);

    void insertAuditLog(@Param("adminId") Long adminId,
                        @Param("action") String action,
                        @Param("target") String target,
                        @Param("detail") String detail,
                        @Param("ip") String ip);
}
