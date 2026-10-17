package com.tuowei.dazhongdianping.module.launch;

import com.tuowei.dazhongdianping.common.api.ForbiddenException;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.config.LaunchProperties;
import org.springframework.stereotype.Service;

@Service
public class LaunchPolicy {
    public enum Feature { CREATOR_REWARDS, SECKILL, GROUP_BUY }
    public record Capabilities(String region, boolean creatorRewards, boolean seckill, boolean groupBuy) {}

    private final LaunchProperties properties;

    public LaunchPolicy(LaunchProperties properties) {
        this.properties = properties;
    }

    public Capabilities capabilities(Region region) {
        // Points are shared across regions. A request header must not reopen
        // deferred rewards or campaigns on a deployment that has disabled them.
        if (!properties.isDeferredFeaturesEnabled()) {
            return new Capabilities(region.name(), false, false, false);
        }
        boolean cn = region == Region.CN;
        LaunchProperties.Eu eu = properties.getEu();
        return new Capabilities(region.name(), cn || eu.isCreatorRewardsEnabled(),
                cn || eu.isSeckillEnabled(), cn || eu.isGroupBuyEnabled());
    }

    public void require(Feature feature) {
        Capabilities available = capabilities(RegionContext.getRegion());
        boolean enabled = switch (feature) {
            case CREATOR_REWARDS -> available.creatorRewards();
            case SECKILL -> available.seckill();
            case GROUP_BUY -> available.groupBuy();
        };
        if (!enabled) throw new ForbiddenException("该功能暂未在当前区域开放");
    }
}
