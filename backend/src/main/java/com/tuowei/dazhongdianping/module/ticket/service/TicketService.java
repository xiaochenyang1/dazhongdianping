package com.tuowei.dazhongdianping.module.ticket.service;

import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.ticket.mapper.TicketMapper;
import com.tuowei.dazhongdianping.module.ticket.model.SupportTicketRow;
import com.tuowei.dazhongdianping.module.ticket.model.TicketMessageRow;
import com.tuowei.dazhongdianping.module.ticket.model.request.TicketCreateRequest;
import com.tuowei.dazhongdianping.module.ticket.model.request.TicketMessageRequest;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** C 端客服工单：发起、查看自己的工单、在待处理/处理中时补充说明。 */
@Service
public class TicketService {

    private static final int REQUESTER_USER = 1;
    private static final int SENDER_USER = 1;

    private final TicketMapper mapper;
    private final TicketPresenter presenter;

    public TicketService(TicketMapper mapper, TicketPresenter presenter) {
        this.mapper = mapper;
        this.presenter = presenter;
    }

    @Transactional
    public Map<String, Object> create(TicketCreateRequest req) {
        UserSession user = requireUser();
        String region = region();
        long shopId = req.shopId() == null ? 0L : req.shopId();
        if (shopId > 0 && mapper.countShop(shopId, region) == 0) {
            throw new NotFoundException("门店不存在");
        }
        SupportTicketRow row = new SupportTicketRow();
        row.setRegion(region);
        row.setRequesterType(REQUESTER_USER);
        row.setRequesterId(user.userId());
        row.setShopId(shopId);
        row.setSubject(req.subject().trim());
        row.setContent(req.content().trim());
        mapper.insertTicket(row);
        addMessage(row.getId(), SENDER_USER, user.userId(), row.getContent());
        return presenter.ticket(requireOwned(row.getId(), user.userId(), region), true);
    }

    public PageResult<Map<String, Object>> mine(Integer page, Integer pageSize) {
        UserSession user = requireUser();
        String region = region();
        int p = page == null ? 1 : Math.max(1, page);
        int s = pageSize == null ? 12 : Math.min(50, Math.max(1, pageSize));
        long total = mapper.countOwnedTickets(region, REQUESTER_USER, user.userId());
        List<Map<String, Object>> list = presenter.tickets(
                mapper.selectOwnedTickets(region, REQUESTER_USER, user.userId(), s, (p - 1) * s));
        return new PageResult<>(list, total, p, s, (long) (p - 1) * s + list.size() < total);
    }

    public Map<String, Object> detail(Long id) {
        UserSession user = requireUser();
        return presenter.ticket(requireOwned(id, user.userId(), region()), true);
    }

    @Transactional
    public Map<String, Object> reply(Long id, TicketMessageRequest req) {
        UserSession user = requireUser();
        String region = region();
        SupportTicketRow row = requireOwned(id, user.userId(), region);
        if (row.getStatus() == null || (row.getStatus() != 1 && row.getStatus() != 2)) {
            throw new ConflictException("工单当前状态不可回复");
        }
        addMessage(id, SENDER_USER, user.userId(), req.content().trim());
        mapper.touch(id, region);
        return presenter.ticket(requireOwned(id, user.userId(), region), true);
    }

    private SupportTicketRow requireOwned(Long id, Long userId, String region) {
        SupportTicketRow row = mapper.selectOwned(id, region, REQUESTER_USER, userId);
        if (row == null) {
            throw new NotFoundException("工单不存在");
        }
        return row;
    }

    private void addMessage(Long ticketId, int senderType, long senderId, String content) {
        TicketMessageRow message = new TicketMessageRow();
        message.setTicketId(ticketId);
        message.setSenderType(senderType);
        message.setSenderId(senderId);
        message.setContent(content);
        mapper.insertMessage(message);
    }

    private UserSession requireUser() {
        UserSession user = UserSessionContext.get();
        if (user == null) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        return user;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
