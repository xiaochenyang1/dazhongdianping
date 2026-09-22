package com.tuowei.dazhongdianping.module.complaint.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.complaint.mapper.ComplaintMapper;
import com.tuowei.dazhongdianping.module.complaint.model.ComplaintLogRow;
import com.tuowei.dazhongdianping.module.complaint.model.ComplaintTicketRow;
import com.tuowei.dazhongdianping.module.complaint.model.request.ComplaintCreateRequest;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** C端投诉：发起工单、查看我的投诉。 */
@Service
public class ComplaintService {

    private final ComplaintMapper mapper;
    private final ComplaintPresenter presenter;

    public ComplaintService(ComplaintMapper mapper, ComplaintPresenter presenter) {
        this.mapper = mapper;
        this.presenter = presenter;
    }

    @Transactional
    public Map<String, Object> create(ComplaintCreateRequest req) {
        UserSession u = requireUser();
        String region = region();
        Long merchantId = mapper.selectShopMerchantId(req.shopId(), region);
        if (merchantId == null) {
            throw new NotFoundException("门店不存在");
        }
        ComplaintTicketRow row = new ComplaintTicketRow();
        row.setRegion(region);
        row.setTicketNo("CT" + System.currentTimeMillis()
                + UUID.randomUUID().toString().substring(0, 4).toUpperCase());
        row.setUserId(u.userId());
        row.setShopId(req.shopId());
        row.setMerchantId(merchantId);
        row.setOrderId(req.orderId() == null ? 0L : req.orderId());
        row.setType(req.type());
        row.setTitle(req.title().trim());
        row.setContent(req.content().trim());
        mapper.insertTicket(row);
        addLog(row.getId(), 1, u.userId(), 1, req.content().trim());
        return presenter.ticket(mapper.selectUserTicket(row.getId(), u.userId(), region), true);
    }

    public PageResult<Map<String, Object>> myComplaints(Integer status, Integer page, Integer pageSize) {
        UserSession u = requireUser();
        String region = region();
        int p = page == null ? 1 : Math.max(1, page);
        int s = pageSize == null ? 12 : Math.min(50, Math.max(1, pageSize));
        long total = mapper.countUserTickets(u.userId(), region, status);
        List<Map<String, Object>> list = presenter.tickets(
                mapper.selectUserTickets(u.userId(), region, status, s, (p - 1) * s));
        return new PageResult<>(list, total, p, s, (p - 1) * s + list.size() < total);
    }

    public Map<String, Object> detail(Long id) {
        UserSession u = requireUser();
        ComplaintTicketRow row = mapper.selectUserTicket(id, u.userId(), region());
        if (row == null) {
            throw new NotFoundException("投诉工单不存在");
        }
        return presenter.ticket(row, true);
    }

    private void addLog(Long ticketId, int actorType, long actorId, int action, String remark) {
        ComplaintLogRow log = new ComplaintLogRow();
        log.setTicketId(ticketId);
        log.setActorType(actorType);
        log.setActorId(actorId);
        log.setAction(action);
        log.setRemark(remark == null ? "" : remark);
        mapper.insertLog(log);
    }

    private UserSession requireUser() {
        UserSession u = UserSessionContext.get();
        if (u == null) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        return u;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
