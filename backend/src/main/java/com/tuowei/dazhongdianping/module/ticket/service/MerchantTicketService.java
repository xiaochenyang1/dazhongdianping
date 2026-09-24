package com.tuowei.dazhongdianping.module.ticket.service;

import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSessionContext;
import com.tuowei.dazhongdianping.module.merchant.identity.service.MerchantAuthorizationService;
import com.tuowei.dazhongdianping.module.ticket.mapper.TicketMapper;
import com.tuowei.dazhongdianping.module.ticket.model.SupportTicketRow;
import com.tuowei.dazhongdianping.module.ticket.model.TicketMessageRow;
import com.tuowei.dazhongdianping.module.ticket.model.request.MerchantTicketCreateRequest;
import com.tuowei.dazhongdianping.module.ticket.model.request.TicketMessageRequest;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** 商家向平台发起客服工单。请求方记商户 id，不记操作员 id。 */
@Service
public class MerchantTicketService {

    private static final int REQUESTER_MERCHANT = 2;
    private static final int SENDER_MERCHANT = 2;

    private final TicketMapper mapper;
    private final TicketPresenter presenter;
    private final MerchantAuthorizationService authorizationService;

    public MerchantTicketService(TicketMapper mapper, TicketPresenter presenter,
                                 MerchantAuthorizationService authorizationService) {
        this.mapper = mapper;
        this.presenter = presenter;
        this.authorizationService = authorizationService;
    }

    @Transactional
    public Map<String, Object> create(MerchantTicketCreateRequest req) {
        MerchantSession session = requireSession();
        authorizationService.requirePermission(session, "ticket:reply");
        String region = region();
        Long ownerId = mapper.selectShopMerchantId(req.shopId(), region);
        if (ownerId == null || !ownerId.equals(session.merchantId())) {
            throw new NotFoundException("门店不存在");
        }
        SupportTicketRow row = new SupportTicketRow();
        row.setRegion(region);
        row.setRequesterType(REQUESTER_MERCHANT);
        row.setRequesterId(session.merchantId());
        row.setShopId(req.shopId());
        row.setSubject(req.subject().trim());
        row.setContent(req.content().trim());
        mapper.insertTicket(row);
        addMessage(row.getId(), session.merchantId(), row.getContent());
        return presenter.ticket(requireOwned(row.getId(), session.merchantId(), region), true);
    }

    public PageResult<Map<String, Object>> tickets(Integer page, Integer pageSize) {
        MerchantSession session = requireSession();
        authorizationService.requirePermission(session, "ticket:view");
        String region = region();
        int p = page == null ? 1 : Math.max(1, page);
        int s = pageSize == null ? 12 : Math.min(50, Math.max(1, pageSize));
        long total = mapper.countOwnedTickets(region, REQUESTER_MERCHANT, session.merchantId());
        List<Map<String, Object>> list = presenter.tickets(
                mapper.selectOwnedTickets(region, REQUESTER_MERCHANT, session.merchantId(), s, (p - 1) * s));
        return new PageResult<>(list, total, p, s, (long) (p - 1) * s + list.size() < total);
    }

    @Transactional
    public Map<String, Object> reply(Long id, TicketMessageRequest req) {
        MerchantSession session = requireSession();
        authorizationService.requirePermission(session, "ticket:reply");
        String region = region();
        SupportTicketRow row = requireOwned(id, session.merchantId(), region);
        if (row.getStatus() == null || (row.getStatus() != 1 && row.getStatus() != 2)) {
            throw new ConflictException("工单当前状态不可回复");
        }
        addMessage(id, session.merchantId(), req.content().trim());
        mapper.touch(id, region);
        return presenter.ticket(requireOwned(id, session.merchantId(), region), true);
    }

    private SupportTicketRow requireOwned(Long id, Long merchantId, String region) {
        SupportTicketRow row = mapper.selectOwned(id, region, REQUESTER_MERCHANT, merchantId);
        if (row == null) {
            throw new NotFoundException("工单不存在");
        }
        return row;
    }

    private void addMessage(Long ticketId, long merchantId, String content) {
        TicketMessageRow message = new TicketMessageRow();
        message.setTicketId(ticketId);
        message.setSenderType(SENDER_MERCHANT);
        message.setSenderId(merchantId);
        message.setContent(content);
        mapper.insertMessage(message);
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
