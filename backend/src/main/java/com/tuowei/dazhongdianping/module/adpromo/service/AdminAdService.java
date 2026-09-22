package com.tuowei.dazhongdianping.module.adpromo.service;

import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.adpromo.mapper.AdMapper;
import com.tuowei.dazhongdianping.module.adpromo.model.AdCampaignRow;
import com.tuowei.dazhongdianping.module.adpromo.model.request.AdAuditRequest;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** 平台侧广告审核：查看投放、通过/驳回。 */
@Service
public class AdminAdService {

    private final AdMapper mapper;
    private final AdPresenter presenter;

    public AdminAdService(AdMapper mapper, AdPresenter presenter) {
        this.mapper = mapper;
        this.presenter = presenter;
    }

    public PageResult<Map<String, Object>> campaigns(Integer auditStatus, Integer page, Integer pageSize) {
        String region = region();
        int p = page == null ? 1 : Math.max(1, page);
        int s = pageSize == null ? 12 : Math.min(50, Math.max(1, pageSize));
        long total = mapper.countAdminCampaigns(region, auditStatus);
        List<Map<String, Object>> list = presenter.campaigns(
                mapper.selectAdminCampaigns(region, auditStatus, s, (p - 1) * s));
        return new PageResult<>(list, total, p, s, (p - 1) * s + list.size() < total);
    }

    @Transactional
    public Map<String, Object> audit(Long id, AdAuditRequest req) {
        String region = region();
        AdCampaignRow existing = mapper.selectCampaign(id, region);
        if (existing == null) {
            throw new NotFoundException("广告投放不存在");
        }
        int auditStatus = req.approved() ? 2 : 3;
        String reason = "";
        if (!req.approved()) {
            if (req.rejectReason() == null || req.rejectReason().isBlank()) {
                throw new IllegalArgumentException("驳回需填写原因");
            }
            reason = req.rejectReason().trim();
        }
        if (mapper.updateAudit(id, region, auditStatus, reason) == 0) {
            throw new ConflictException("广告投放当前状态不可审核");
        }
        return presenter.campaign(mapper.selectCampaign(id, region));
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
