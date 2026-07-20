package com.tuowei.dazhongdianping.module.admin.rbac.service;

import com.tuowei.dazhongdianping.module.admin.rbac.mapper.AdminRbacMapper;
import org.springframework.stereotype.Service;

@Service
public class AdminAuditLogService {
    private final AdminRbacMapper mapper;

    public AdminAuditLogService(AdminRbacMapper mapper) {
        this.mapper = mapper;
    }

    public void record(Long adminId, String action, String target, String detail, String ip) {
        mapper.insertAuditLog(
                adminId == null ? 0L : adminId,
                safe(action),
                safe(target),
                safe(detail),
                safe(ip)
        );
    }

    private String safe(String value) {
        return value == null ? "" : value;
    }
}
