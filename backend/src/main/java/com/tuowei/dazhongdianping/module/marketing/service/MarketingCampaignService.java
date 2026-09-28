package com.tuowei.dazhongdianping.module.marketing.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.marketing.mapper.MarketingCampaignMapper;
import com.tuowei.dazhongdianping.module.marketing.model.GroupBuyCampaignRow;
import com.tuowei.dazhongdianping.module.marketing.model.GroupBuyTeamRow;
import com.tuowei.dazhongdianping.module.marketing.model.SeckillClaimRow;
import com.tuowei.dazhongdianping.module.marketing.model.SeckillEventRow;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** C 端秒杀与拼团：只展示已过审且处于活动时间内的场次。 */
@Service
public class MarketingCampaignService {

    private final MarketingCampaignMapper mapper;

    public MarketingCampaignService(MarketingCampaignMapper mapper) {
        this.mapper = mapper;
    }

    public List<Map<String, Object>> seckills() {
        return mapper.selectActiveSeckills(region(), LocalDateTime.now()).stream().map(this::seckillMap).toList();
    }

    @Transactional
    public Map<String, Object> claimSeckill(Long id) {
        UserSession user = requireUser();
        String region = region();
        LocalDateTime now = LocalDateTime.now();
        SeckillEventRow event = mapper.selectSeckill(id, region);
        if (event == null || event.getAuditStatus() == null || event.getAuditStatus() != 2
                || event.getStatus() == null || event.getStatus() != 1) {
            throw new NotFoundException("秒杀活动不存在");
        }
        if (event.getStartAt() != null && now.isBefore(event.getStartAt())
                || event.getEndAt() != null && now.isAfter(event.getEndAt())) {
            throw new IllegalArgumentException("不在秒杀活动时间内");
        }
        if (mapper.countSeckillClaim(id, user.userId()) > 0) {
            throw new IllegalArgumentException("已参与过该秒杀");
        }
        if (event.getSold() != null && event.getStock() != null && event.getSold() >= event.getStock()) {
            throw new IllegalArgumentException("秒杀已售罄");
        }
        if (mapper.incrementSeckillSold(id, region, now) == 0) {
            throw new IllegalArgumentException("秒杀已售罄");
        }
        SeckillClaimRow claim = new SeckillClaimRow();
        claim.setEventId(id);
        claim.setUserId(user.userId());
        claim.setRegion(region);
        try {
            mapper.insertSeckillClaim(claim);
        } catch (DuplicateKeyException duplicate) {
            throw new IllegalArgumentException("已参与过该秒杀");
        }
        SeckillEventRow saved = mapper.selectSeckill(id, region);
        Map<String, Object> body = seckillMap(saved);
        body.put("claimId", claim.getId());
        return body;
    }

    public List<Map<String, Object>> groupBuys() {
        return mapper.selectActiveGroups(region(), LocalDateTime.now()).stream().map(this::groupMap).toList();
    }

    @Transactional
    public Map<String, Object> openTeam(Long campaignId) {
        UserSession user = requireUser();
        String region = region();
        LocalDateTime now = LocalDateTime.now();
        GroupBuyCampaignRow campaign = requireOpenCampaign(campaignId, region, now);
        GroupBuyTeamRow team = new GroupBuyTeamRow();
        team.setCampaignId(campaign.getId());
        team.setRegion(region);
        team.setLeaderUserId(user.userId());
        team.setExpireAt(now.plusHours(24));
        mapper.insertTeam(team);
        mapper.insertMember(team.getId(), user.userId());
        return teamMap(mapper.selectTeam(team.getId()));
    }

    @Transactional
    public Map<String, Object> joinTeam(Long teamId) {
        UserSession user = requireUser();
        String region = region();
        LocalDateTime now = LocalDateTime.now();
        GroupBuyTeamRow team = mapper.selectTeam(teamId);
        if (team == null || team.getRegion() == null || !team.getRegion().equals(region)) {
            throw new NotFoundException("拼团不存在");
        }
        GroupBuyCampaignRow campaign = mapper.selectGroup(team.getCampaignId(), region);
        if (campaign == null) {
            throw new NotFoundException("拼团不存在");
        }
        if (mapper.countTeamMember(teamId, user.userId()) > 0) {
            throw new IllegalArgumentException("已参加该拼团");
        }
        if (team.getStatus() == null || team.getStatus() != 1) {
            throw new IllegalArgumentException("拼团已结束");
        }
        if (team.getExpireAt() != null && !team.getExpireAt().isAfter(now)) {
            throw new IllegalArgumentException("拼团已过期");
        }
        int groupSize = campaign.getGroupSize() == null ? 2 : campaign.getGroupSize();
        if (team.getMemberCount() != null && team.getMemberCount() >= groupSize) {
            throw new IllegalArgumentException("拼团已满员");
        }
        if (mapper.joinTeam(teamId, region, groupSize, now) == 0) {
            GroupBuyTeamRow latest = mapper.selectTeam(teamId);
            if (latest != null && latest.getExpireAt() != null && !latest.getExpireAt().isAfter(now)) {
                throw new IllegalArgumentException("拼团已过期");
            }
            if (latest != null && latest.getStatus() != null && latest.getStatus() != 1) {
                throw new IllegalArgumentException("拼团已结束");
            }
            throw new IllegalArgumentException("拼团已满员");
        }
        try {
            mapper.insertMember(teamId, user.userId());
        } catch (DuplicateKeyException duplicate) {
            throw new IllegalArgumentException("已参加该拼团");
        }
        return teamMap(mapper.selectTeam(teamId));
    }

    private GroupBuyCampaignRow requireOpenCampaign(Long id, String region, LocalDateTime now) {
        GroupBuyCampaignRow campaign = mapper.selectGroup(id, region);
        if (campaign == null || campaign.getAuditStatus() == null || campaign.getAuditStatus() != 2
                || campaign.getStatus() == null || campaign.getStatus() != 1) {
            throw new NotFoundException("拼团活动不存在");
        }
        if (campaign.getStartAt() != null && now.isBefore(campaign.getStartAt())
                || campaign.getEndAt() != null && now.isAfter(campaign.getEndAt())) {
            throw new IllegalArgumentException("不在拼团活动时间内");
        }
        return campaign;
    }

    private Map<String, Object> seckillMap(SeckillEventRow row) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("id", row.getId());
        body.put("shopId", row.getShopId());
        body.put("dealId", row.getDealId());
        body.put("title", row.getTitle());
        body.put("seckillPrice", row.getSeckillPrice());
        body.put("currency", row.getCurrency());
        body.put("stock", row.getStock());
        body.put("sold", row.getSold());
        body.put("startAt", row.getStartAt());
        body.put("endAt", row.getEndAt());
        return body;
    }

    private Map<String, Object> groupMap(GroupBuyCampaignRow row) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("id", row.getId());
        body.put("shopId", row.getShopId());
        body.put("dealId", row.getDealId());
        body.put("title", row.getTitle());
        body.put("groupPrice", row.getGroupPrice());
        body.put("currency", row.getCurrency());
        body.put("groupSize", row.getGroupSize());
        body.put("startAt", row.getStartAt());
        body.put("endAt", row.getEndAt());
        return body;
    }

    private Map<String, Object> teamMap(GroupBuyTeamRow row) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("id", row.getId());
        body.put("campaignId", row.getCampaignId());
        body.put("leaderUserId", row.getLeaderUserId());
        body.put("status", row.getStatus());
        body.put("memberCount", row.getMemberCount());
        body.put("expireAt", row.getExpireAt());
        return body;
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
