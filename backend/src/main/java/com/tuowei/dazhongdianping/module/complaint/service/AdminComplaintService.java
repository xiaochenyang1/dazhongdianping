package com.tuowei.dazhongdianping.module.complaint.service;

import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.complaint.mapper.ComplaintMapper;
import com.tuowei.dazhongdianping.module.complaint.model.ComplaintLogRow;
import com.tuowei.dazhongdianping.module.complaint.model.ComplaintTicketRow;
import com.tuowei.dazhongdianping.module.complaint.model.request.ComplaintDisposeRequest;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** 平台侧投诉仲裁：查看工单、处置（解决/驳回）。 */
@Service
public class AdminComplaintService {

    private final ComplaintMapper mapper;
    private final ComplaintPresenter presenter;

    public AdminComplaintService(ComplaintMapper mapper, ComplaintPresenter presenter) {
        this.mapper = mapper;
        this.presenter = presenter;
    }

    public PageResult<Map<String, Object>> complaints(Integer status, Integer page, Integer pageSize) {
        String region = region();
        int p = page == null ? 1 : Math.max(1, page);
        int s = pageSize == null ? 12 : Math.min(50, Math.max(1, pageSize));
        long total = mapper.countAdminTickets(region, status);
        List<Map<String, Object>> list = presenter.tickets(
                mapper.selectAdminTickets(region, status, s, (p - 1) * s));
        return new PageResult<>(list, total, p, s, (p - 1) * s + list.size() < total);
    }

    public Map<String, Object> detail(Long id) {
        ComplaintTicketRow row = mapper.selectTicket(id, region());
        if (row == null) {
            throw new NotFoundException("投诉工单不存在");
        }
        return presenter.ticket(row, true);
    }

    @Transactional
    public Map<String, Object> dispose(Long id, ComplaintDisposeRequest req) {
        String region = region();
        AdminSession admin = AdminSessionContext.get();
        long adminId = admin == null ? 0L : admin.adminId();
        ComplaintTicketRow row = mapper.selectTicket(id, region);
        if (row == null) {
            throw new NotFoundException("投诉工单不存在");
        }
        int targetStatus = req.resolved() ? 3 : 4;
        String resolution = req.resolution().trim();
        if (mapper.updateResolution(id, region, targetStatus, resolution, adminId, LocalDateTime.now()) == 0) {
            throw new ConflictException("投诉当前状态不可处置");
        }
        addLog(id, adminId, targetStatus == 3 ? 4 : 5, resolution);
        return presenter.ticket(mapper.selectTicket(id, region), true);
    }

    private void addLog(Long ticketId, long adminId, int action, String remark) {
        ComplaintLogRow log = new ComplaintLogRow();
        log.setTicketId(ticketId);
        log.setActorType(3);
        log.setActorId(adminId);
        log.setAction(action);
        log.setRemark(remark);
        mapper.insertLog(log);
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
