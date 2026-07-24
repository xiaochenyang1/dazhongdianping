package com.tuowei.dazhongdianping.module.admin.sensitiveword;

import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.rbac.service.AdminAuditLogService;
import com.tuowei.dazhongdianping.module.admin.sensitiveword.model.request.AdminSensitiveWordSaveRequest;
import com.tuowei.dazhongdianping.module.admin.sensitiveword.model.response.AdminSensitiveWordResponse;
import com.tuowei.dazhongdianping.module.moderation.mapper.SensitiveWordMapper;
import com.tuowei.dazhongdianping.module.moderation.model.SensitiveWordRow;
import com.tuowei.dazhongdianping.module.moderation.service.SensitiveWordFilterService;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminSensitiveWordService {

    private final SensitiveWordMapper mapper;
    private final SensitiveWordFilterService filterService;
    private final AdminAuditLogService auditLogService;

    public AdminSensitiveWordService(
            SensitiveWordMapper mapper,
            SensitiveWordFilterService filterService,
            AdminAuditLogService auditLogService
    ) {
        this.mapper = mapper;
        this.filterService = filterService;
        this.auditLogService = auditLogService;
    }

    public List<AdminSensitiveWordResponse> list() {
        return mapper.selectWords(region()).stream().map(this::toResponse).toList();
    }

    @Transactional
    public AdminSensitiveWordResponse create(AdminSensitiveWordSaveRequest request, String requestIp) {
        String word = normalizeWord(request.word());
        requireUnique(word, null);

        SensitiveWordRow row = new SensitiveWordRow();
        row.setRegion(region());
        row.setWord(word);
        row.setMatchMode(1);
        row.setEnabled(true);
        row.setRemark(normalizeRemark(request.remark()));
        mapper.insertWord(row);
        filterService.invalidate(region());

        AdminSensitiveWordResponse response = toResponse(require(row.getId()));
        record("admin.sensitive_word_create", "sensitive_word:" + response.id(), response, requestIp);
        return response;
    }

    @Transactional
    public AdminSensitiveWordResponse update(Long id, AdminSensitiveWordSaveRequest request, String requestIp) {
        SensitiveWordRow row = require(id);
        String word = normalizeWord(request.word());
        requireUnique(word, id);

        row.setWord(word);
        row.setMatchMode(1);
        row.setRemark(normalizeRemark(request.remark()));
        if (mapper.updateWord(row) != 1) {
            throw new NotFoundException("敏感词不存在");
        }
        filterService.invalidate(region());

        AdminSensitiveWordResponse response = toResponse(require(id));
        record("admin.sensitive_word_update", "sensitive_word:" + id, response, requestIp);
        return response;
    }

    @Transactional
    public AdminSensitiveWordResponse updateStatus(Long id, boolean enabled, String requestIp) {
        SensitiveWordRow existing = require(id);
        if (mapper.updateWordStatus(id, region(), enabled) != 1) {
            throw new NotFoundException("敏感词不存在");
        }
        filterService.invalidate(region());
        AdminSensitiveWordResponse response = toResponse(require(id));
        auditLogService.record(
                currentAdmin().adminId(),
                "admin.sensitive_word_status",
                "sensitive_word:" + id,
                String.format(
                        "word=%s, enabled=%s -> %s",
                        existing.getWord(),
                        Boolean.TRUE.equals(existing.getEnabled()),
                        enabled
                ),
                requestIp
        );
        return response;
    }

    @Transactional
    public void delete(Long id, String requestIp) {
        SensitiveWordRow existing = require(id);
        if (mapper.deleteWord(id, region()) != 1) {
            throw new NotFoundException("敏感词不存在");
        }
        filterService.invalidate(region());
        auditLogService.record(
                currentAdmin().adminId(),
                "admin.sensitive_word_delete",
                "sensitive_word:" + id,
                "word=" + existing.getWord(),
                requestIp
        );
    }

    private SensitiveWordRow require(Long id) {
        SensitiveWordRow row = mapper.selectWord(id, region());
        if (row == null) {
            throw new NotFoundException("敏感词不存在");
        }
        return row;
    }

    private void requireUnique(String word, Long excludeId) {
        Integer count = mapper.countWordConflict(region(), word, excludeId);
        if (count != null && count > 0) {
            throw new ConflictException("当前区域已存在相同敏感词");
        }
    }

    private AdminSensitiveWordResponse toResponse(SensitiveWordRow row) {
        return new AdminSensitiveWordResponse(
                row.getId(),
                row.getRegion(),
                row.getWord(),
                row.getMatchMode() == null ? 1 : row.getMatchMode(),
                Boolean.TRUE.equals(row.getEnabled()),
                row.getRemark() == null ? "" : row.getRemark()
        );
    }

    private void record(String action, String target, AdminSensitiveWordResponse response, String requestIp) {
        String detail = String.format(
                "region=%s, word=%s, enabled=%s, remark=%s",
                response.region(),
                response.word(),
                response.enabled(),
                response.remark()
        );
        auditLogService.record(currentAdmin().adminId(), action, target, detail, requestIp);
    }

    private String normalizeWord(String value) {
        String word = value == null ? "" : value.trim();
        if (word.isEmpty()) {
            throw new IllegalArgumentException("word 不能为空");
        }
        return word;
    }

    private String normalizeRemark(String value) {
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
