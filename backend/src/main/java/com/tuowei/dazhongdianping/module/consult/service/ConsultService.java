package com.tuowei.dazhongdianping.module.consult.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.consult.mapper.ConsultMapper;
import com.tuowei.dazhongdianping.module.consult.model.ConsultMessageRow;
import com.tuowei.dazhongdianping.module.consult.model.ConsultSessionRow;
import com.tuowei.dazhongdianping.module.consult.model.request.ConsultMessageRequest;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** C端在线咨询：发起会话、我的会话、消息收发。 */
@Service
public class ConsultService {

    private final ConsultMapper mapper;
    private final ConsultPresenter presenter;

    public ConsultService(ConsultMapper mapper, ConsultPresenter presenter) {
        this.mapper = mapper;
        this.presenter = presenter;
    }

    /** 发起或复用与门店的会话。 */
    @Transactional
    public Map<String, Object> startSession(Long shopId) {
        UserSession u = requireUser();
        String region = region();
        ConsultSessionRow existing = mapper.selectSessionByUserShop(u.userId(), shopId, region);
        if (existing != null) {
            return presenter.session(existing, 1);
        }
        Long merchantId = mapper.selectShopMerchantId(shopId, region);
        if (merchantId == null) {
            throw new NotFoundException("门店不存在");
        }
        ConsultSessionRow row = new ConsultSessionRow();
        row.setRegion(region);
        row.setUserId(u.userId());
        row.setShopId(shopId);
        row.setMerchantId(merchantId);
        mapper.insertSession(row);
        return presenter.session(mapper.selectUserSession(row.getId(), u.userId(), region), 1);
    }

    public List<Map<String, Object>> mySessions() {
        UserSession u = requireUser();
        return presenter.sessions(mapper.selectUserSessions(u.userId(), region()), 1);
    }

    /** 读取会话消息并把用户侧未读清零。 */
    @Transactional
    public Map<String, Object> messages(Long sessionId) {
        UserSession u = requireUser();
        ConsultSessionRow s = mapper.selectUserSession(sessionId, u.userId(), region());
        if (s == null) {
            throw new NotFoundException("会话不存在");
        }
        mapper.markUserRead(sessionId);
        s.setUserUnread(0);
        return Map.of(
                "session", presenter.session(s, 1),
                "messages", presenter.messages(mapper.selectMessages(sessionId)));
    }

    @Transactional
    public Map<String, Object> send(Long sessionId, ConsultMessageRequest req) {
        UserSession u = requireUser();
        String region = region();
        ConsultSessionRow s = mapper.selectUserSession(sessionId, u.userId(), region);
        if (s == null) {
            throw new NotFoundException("会话不存在");
        }
        ConsultMessageRow msg = new ConsultMessageRow();
        msg.setSessionId(sessionId);
        msg.setRegion(region);
        msg.setSenderType(1);
        msg.setSenderId(u.userId());
        msg.setContent(req.content().trim());
        mapper.insertMessage(msg);
        // 用户发言：商家侧未读 +1。
        mapper.updateSessionOnMessage(sessionId, req.content().trim(), LocalDateTime.now(), 0, 1);
        return presenter.message(msg);
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
