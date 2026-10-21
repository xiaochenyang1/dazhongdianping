package com.tuowei.dazhongdianping.module.community.service;

import com.tuowei.dazhongdianping.module.browse.mapper.BrowseQueryMapper;
import com.tuowei.dazhongdianping.module.browse.model.ShopDetailRow;
import com.tuowei.dazhongdianping.module.community.model.PostRow;
import com.tuowei.dazhongdianping.module.community.model.request.PostSaveRequest;
import com.tuowei.dazhongdianping.module.community.model.response.PostDealLinkResponse;
import com.tuowei.dazhongdianping.module.community.model.response.PostShopLinkResponse;
import com.tuowei.dazhongdianping.module.trade.mapper.TradeMapper;
import com.tuowei.dazhongdianping.module.trade.model.DealRow;
import java.util.Objects;
import org.springframework.stereotype.Service;

/** Public association previews must not reveal a hidden or cross-region business. */
@Service
public class PostCommerceLinkService {
    private final BrowseQueryMapper browseMapper;
    private final TradeMapper tradeMapper;

    public PostCommerceLinkService(BrowseQueryMapper browseMapper, TradeMapper tradeMapper) {
        this.browseMapper = browseMapper;
        this.tradeMapper = tradeMapper;
    }

    public void validate(PostSaveRequest request, String region, PostRow previous) {
        boolean shopChanged = previous == null || !Objects.equals(previous.getShopId(), request.shopId());
        boolean dealChanged = previous == null || !Objects.equals(previous.getDealId(), request.dealId());
        // Text-only edits may retain an old association that has since been taken offline.
        if (request.shopId() != null && shopChanged && publicShop(request.shopId(), region) == null) {
            throw new IllegalArgumentException("关联门店不存在或不可用");
        }
        if (request.dealId() != null && (shopChanged || dealChanged)) {
            DealRow deal = publicDeal(request.dealId(), region, request.shopId());
            if (deal == null) throw new IllegalArgumentException("关联团购不存在、不可用或不属于所选门店");
        }
    }

    public PostShopLinkResponse shop(Long id, String region) {
        if (id == null) return null;
        ShopDetailRow shop = publicShop(id, region);
        return shop == null
                ? new PostShopLinkResponse(id, false, "", "")
                : new PostShopLinkResponse(id, true, shop.getName(), shop.getCoverUrl());
    }

    public PostDealLinkResponse deal(Long id, String region, Long linkedShopId) {
        if (id == null) return null;
        DealRow deal = publicDeal(id, region, linkedShopId);
        return deal == null
                ? new PostDealLinkResponse(id, false, null, "", "", null, "")
                : new PostDealLinkResponse(id, true, deal.getShopId(), deal.getTitle(),
                        deal.getCoverImage(), deal.getPrice(), deal.getCurrency());
    }

    private ShopDetailRow publicShop(Long id, String region) {
        return id == null || id <= 0 ? null : browseMapper.selectShopDetail(region, id);
    }

    private DealRow publicDeal(Long id, String region, Long linkedShopId) {
        if (id == null || id <= 0) return null;
        DealRow deal = tradeMapper.selectDeal(id, region);
        if (deal == null || publicShop(deal.getShopId(), region) == null
                || (linkedShopId != null && !linkedShopId.equals(deal.getShopId()))) return null;
        return deal;
    }
}
