package com.tuowei.dazhongdianping.module.admin.hotword;

import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.hotword.mapper.AdminHotWordMapper;
import com.tuowei.dazhongdianping.module.admin.hotword.model.AdminHotWordRow;
import com.tuowei.dazhongdianping.module.admin.hotword.model.request.AdminHotWordSaveRequest;
import com.tuowei.dazhongdianping.module.admin.hotword.model.response.AdminHotWordResponse;
import com.tuowei.dazhongdianping.module.admin.rbac.service.AdminAuditLogService;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminHotWordService {

    private final AdminHotWordMapper mapper;
    private final AdminAuditLogService auditLogService;

    public AdminHotWordService(AdminHotWordMapper mapper,
                               AdminAuditLogService auditLogService) {
        this.mapper = mapper;
        this.auditLogService = auditLogService;
    }

    public List<AdminHotWordResponse> list() {
        return mapper.selectHotWords(region()).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public AdminHotWordResponse create(AdminHotWordSaveRequest request, String requestIp) {
        String keyword = normalizeKeyword(request.keyword());
        requireUnique(keyword, null);

        AdminHotWordRow row = new AdminHotWordRow();
        row.setRegion(region());
        row.setKeyword(keyword);
        row.setEnabled(true);
        row.setSortNo(request.sortNo());
        mapper.insertHotWord(row);

        AdminHotWordResponse response = toResponse(require(row.getId()));
        record("admin.hotword_create", "hotword:" + response.id(), response, requestIp);
        return response;
    }

    @Transactional
    public AdminHotWordResponse update(Long id, AdminHotWordSaveRequest request, String requestIp) {
        AdminHotWordRow row = require(id);
        String keyword = normalizeKeyword(request.keyword());
        requireUnique(keyword, id);

        row.setKeyword(keyword);
        row.setSortNo(request.sortNo());
        if (mapper.updateHotWord(row) != 1) {
            throw new NotFoundException("热词不存在");
        }

        AdminHotWordResponse response = toResponse(require(id));
        record("admin.hotword_update", "hotword:" + id, response, requestIp);
        return response;
    }

    @Transactional
    public AdminHotWordResponse updateStatus(Long id, boolean enabled, String requestIp) {
        AdminHotWordRow existing = require(id);
        if (mapper.updateHotWordStatus(id, region(), enabled) != 1) {
            throw new NotFoundException("热词不存在");
        }
        AdminHotWordResponse response = toResponse(require(id));
        String detail = String.format(
                "keyword=%s, enabled=%s -> %s",
                existing.getKeyword(),
                Boolean.TRUE.equals(existing.getEnabled()),
                enabled
        );
        auditLogService.record(currentAdmin().adminId(), "admin.hotword_status", "hotword:" + id, detail, requestIp);
        return response;
    }

    @Transactional
    public void delete(Long id, String requestIp) {
        AdminHotWordRow existing = require(id);
        if (mapper.deleteHotWord(id, region()) != 1) {
            throw new NotFoundException("热词不存在");
        }
        auditLogService.record(
                currentAdmin().adminId(),
                "admin.hotword_delete",
                "hotword:" + id,
                "keyword=" + existing.getKeyword(),
                requestIp
        );
    }

    private AdminHotWordRow require(Long id) {
        AdminHotWordRow row = mapper.selectHotWord(id, region());
        if (row == null) {
            throw new NotFoundException("热词不存在");
        }
        return row;
    }

    private void requireUnique(String keyword, Long excludeId) {
        Integer count = mapper.countKeywordConflict(region(), keyword, excludeId);
        if (count != null && count > 0) {
            throw new ConflictException("当前区域已存在同名热词");
        }
    }

    private AdminHotWordResponse toResponse(AdminHotWordRow row) {
        return new AdminHotWordResponse(
                row.getId(),
                row.getRegion(),
                row.getKeyword(),
                Boolean.TRUE.equals(row.getEnabled()),
                row.getSortNo() == null ? 0 : row.getSortNo()
        );
    }

    private void record(String action, String target, AdminHotWordResponse response, String requestIp) {
        String detail = String.format(
                "region=%s, keyword=%s, enabled=%s, sortNo=%d",
                response.region(),
                response.keyword(),
                response.enabled(),
                response.sortNo()
        );
        auditLogService.record(currentAdmin().adminId(), action, target, detail, requestIp);
    }

    private String normalizeKeyword(String value) {
        return value == null ? "" : value.trim();
    }

    private String region() {
        return RegionContext.getRegion().name();
    }

    private AdminSession currentAdmin() {
        AdminSession session = AdminSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("管理员未登录");
        }
        return session;
    }
}
