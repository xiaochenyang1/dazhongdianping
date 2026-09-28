package com.tuowei.dazhongdianping.module.waitlist.service;

import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.waitlist.mapper.WaitlistMapper;
import com.tuowei.dazhongdianping.module.waitlist.model.WaitlistEntryRow;
import com.tuowei.dazhongdianping.module.waitlist.model.request.WaitlistJoinRequest;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** C端排队候位：取号、我的排队、取消。 */
@Service
public class WaitlistService {

    private final WaitlistMapper mapper;
    private final WaitlistPresenter presenter;

    public WaitlistService(WaitlistMapper mapper, WaitlistPresenter presenter) {
        this.mapper = mapper;
        this.presenter = presenter;
    }

    @Transactional
    public Map<String, Object> join(Long shopId, WaitlistJoinRequest req) {
        UserSession u = requireUser();
        String region = region();
        Long merchantId = mapper.selectShopMerchantId(shopId, region);
        if (merchantId == null) {
            throw new NotFoundException("门店不存在");
        }
        if (mapper.countActiveForUserShop(u.userId(), shopId, region) > 0) {
            throw new ConflictException("你在该门店已有排队号");
        }
        WaitlistEntryRow row = new WaitlistEntryRow();
        row.setRegion(region);
        row.setShopId(shopId);
        row.setMerchantId(merchantId);
        row.setUserId(u.userId());
        row.setTableType(req.tableType());
        row.setPartySize(req.partySize());
        row.setQueueNo(mapper.nextQueueNo(shopId, req.tableType()));
        mapper.insertEntry(row);
        return withAhead(mapper.selectUserEntry(row.getId(), u.userId(), region));
    }

    public List<Map<String, Object>> myEntries() {
        UserSession u = requireUser();
        return mapper.selectUserActiveEntries(u.userId(), region()).stream()
                .map(this::withAhead).toList();
    }

    @Transactional
    public Map<String, Object> cancel(Long id) {
        UserSession u = requireUser();
        String region = region();
        WaitlistEntryRow entry = mapper.selectUserEntry(id, u.userId(), region);
        if (entry == null) {
            throw new NotFoundException("排队号不存在");
        }
        if (mapper.cancel(id, u.userId()) == 0) {
            throw new ConflictException("当前状态不可取消");
        }
        return presenter.entry(mapper.selectUserEntry(id, u.userId(), region));
    }

    private Map<String, Object> withAhead(WaitlistEntryRow row) {
        if (row != null && row.getStatus() != null && row.getStatus() == 1) {
            row.setAheadCount(mapper.aheadCount(row.getShopId(), row.getTableType(), row.getQueueNo()));
        }
        return presenter.entry(row);
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
