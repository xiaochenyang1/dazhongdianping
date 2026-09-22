package com.tuowei.dazhongdianping.module.complaint.service;

import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.complaint.mapper.ComplaintMapper;
import com.tuowei.dazhongdianping.module.complaint.model.ComplaintLogRow;
import com.tuowei.dazhongdianping.module.complaint.model.ComplaintTicketRow;
import com.tuowei.dazhongdianping.module.complaint.model.request.ComplaintReplyRequest;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSessionContext;
import com.tuowei.dazhongdianping.module.merchant.identity.service.MerchantAuthorizationService;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** 商家端投诉：查看派发给本商户的投诉、提交申辩。 */
@Service
public class MerchantComplaintService {

    private final ComplaintMapper mapper;
    private final ComplaintPresenter presenter;
    private final MerchantAuthorizationService authorizationService;

    public MerchantComplaintService(ComplaintMapper mapper, ComplaintPresenter presenter,
                                    MerchantAuthorizationService authorizationService) {
        this.mapper = mapper;
        this.presenter = presenter;
        this.authorizationService = authorizationService;
    }

    public PageResult<Map<String, Object>> complaints(Integer status, Integer page, Integer pageSize) {
        MerchantSession session = requireSession();
        authorizationService.requirePermission(session, "complaint:view");
        String region = region();
        int p = page == null ? 1 : Math.max(1, page);
        int s = pageSize == null ? 12 : Math.min(50, Math.max(1, pageSize));
        long total = mapper.countMerchantTickets(session.merchantId(), region, status);
        List<Map<String, Object>> list = presenter.tickets(
                mapper.selectMerchantTickets(session.merchantId(), region, status, s, (p - 1) * s));
        return new PageResult<>(list, total, p, s, (p - 1) * s + list.size() < total);
    }

    public Map<String, Object> detail(Long id) {
        MerchantSession session = requireSession();
        authorizationService.requirePermission(session, "complaint:view");
        ComplaintTicketRow row = mapper.selectMerchantTicket(id, session.merchantId(), region());
        if (row == null) {
            throw new NotFoundException("投诉工单不存在");
        }
        return presenter.ticket(row, true);
    }

    @Transactional
    public Map<String, Object> reply(Long id, ComplaintReplyRequest req) {
        MerchantSession session = requireSession();
        authorizationService.requirePermission(session, "complaint:reply");
        String region = region();
        ComplaintTicketRow row = mapper.selectMerchantTicket(id, session.merchantId(), region);
        if (row == null) {
            throw new NotFoundException("投诉工单不存在");
        }
        String reply = req.reply().trim();
        if (mapper.updateMerchantReply(id, session.merchantId(), reply, LocalDateTime.now()) == 0) {
            throw new ConflictException("投诉当前状态不可申辩");
        }
        addLog(id, session.operatorId(), reply);
        return presenter.ticket(mapper.selectMerchantTicket(id, session.merchantId(), region), true);
    }

    private void addLog(Long ticketId, long operatorId, String remark) {
        ComplaintLogRow log = new ComplaintLogRow();
        log.setTicketId(ticketId);
        log.setActorType(2);
        log.setActorId(operatorId);
        log.setAction(2);
        log.setRemark(remark);
        mapper.insertLog(log);
    }

    private MerchantSession requireSession() {
        MerchantSession session = MerchantSessionContext.get();
        if (session == null) {
            throw new UnauthorizedException("商户登录状态不存在");
        }
        return session;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
