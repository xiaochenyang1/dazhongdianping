package com.tuowei.dazhongdianping.module.ticket.service;

import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.admin.AdminSessionContext;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.ticket.mapper.TicketMapper;
import com.tuowei.dazhongdianping.module.ticket.model.SupportTicketRow;
import com.tuowei.dazhongdianping.module.ticket.model.TicketMessageRow;
import com.tuowei.dazhongdianping.module.ticket.model.request.TicketMessageRequest;
import com.tuowei.dazhongdianping.module.ticket.model.request.TicketStatusRequest;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** 平台客服：查看工单、回复（待处理自动转为处理中）、改状态。 */
@Service
public class AdminTicketService {

    private static final int SENDER_ADMIN = 3;

    private final TicketMapper mapper;
    private final TicketPresenter presenter;

    public AdminTicketService(TicketMapper mapper, TicketPresenter presenter) {
        this.mapper = mapper;
        this.presenter = presenter;
    }

    public PageResult<Map<String, Object>> tickets(Integer status, Integer page, Integer pageSize) {
        String region = region();
        int p = page == null ? 1 : Math.max(1, page);
        int s = pageSize == null ? 12 : Math.min(50, Math.max(1, pageSize));
        long total = mapper.countAdminTickets(region, status);
        List<Map<String, Object>> list = presenter.tickets(
                mapper.selectAdminTickets(region, status, s, (p - 1) * s));
        return new PageResult<>(list, total, p, s, (long) (p - 1) * s + list.size() < total);
    }

    public Map<String, Object> detail(Long id) {
        return presenter.ticket(requireTicket(id, region()), true);
    }

    @Transactional
    public Map<String, Object> reply(Long id, TicketMessageRequest req) {
        String region = region();
        SupportTicketRow row = requireTicket(id, region);
        AdminSession admin = requireAdmin();
        TicketMessageRow message = new TicketMessageRow();
        message.setTicketId(id);
        message.setSenderType(SENDER_ADMIN);
        message.setSenderId(admin.adminId());
        message.setContent(req.content().trim());
        mapper.insertMessage(message);
        if (row.getStatus() != null && row.getStatus() == 1) {
            mapper.updateStatus(id, region, 2);
        } else {
            mapper.touch(id, region);
        }
        return presenter.ticket(requireTicket(id, region), true);
    }

    @Transactional
    public Map<String, Object> updateStatus(Long id, TicketStatusRequest req) {
        String region = region();
        int status = req.status();
        if (status != 2 && status != 3 && status != 4) {
            throw new IllegalArgumentException("工单状态只能改为处理中、已解决或已关闭");
        }
        requireTicket(id, region);
        if (mapper.updateStatus(id, region, status) == 0) {
            throw new NotFoundException("工单不存在");
        }
        return presenter.ticket(requireTicket(id, region), true);
    }

    private SupportTicketRow requireTicket(Long id, String region) {
        SupportTicketRow row = mapper.selectById(id, region);
        if (row == null) {
            throw new NotFoundException("工单不存在");
        }
        return row;
    }

    private AdminSession requireAdmin() {
        AdminSession admin = AdminSessionContext.get();
        if (admin == null || admin.adminId() == null) {
            throw new UnauthorizedException("管理员登录状态不存在");
        }
        return admin;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
