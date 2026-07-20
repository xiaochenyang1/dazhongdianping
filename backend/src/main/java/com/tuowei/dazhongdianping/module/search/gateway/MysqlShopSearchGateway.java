package com.tuowei.dazhongdianping.module.search.gateway;

import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.module.browse.model.ShopListQuery;
import com.tuowei.dazhongdianping.module.browse.model.response.ShopListItemResponse;
import com.tuowei.dazhongdianping.module.browse.service.BrowseQueryService;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchQuery;
import org.springframework.stereotype.Component;

@Component("mysqlShopSearchGateway")
public class MysqlShopSearchGateway implements ShopSearchGateway {

    private final BrowseQueryService browseQueryService;

    public MysqlShopSearchGateway(BrowseQueryService browseQueryService) {
        this.browseQueryService = browseQueryService;
    }

    @Override
    public PageResult<ShopListItemResponse> search(Region region, ShopSearchQuery query) {
        ShopListQuery fallbackQuery = new ShopListQuery();
        fallbackQuery.setCategoryId(query.getCategoryId());
        fallbackQuery.setCityId(query.getCityId());
        fallbackQuery.setAreaId(query.getAreaId());
        fallbackQuery.setKeyword(query.getKeyword());
        fallbackQuery.setMinPrice(query.getMinPrice());
        fallbackQuery.setMaxPrice(query.getMaxPrice());
        fallbackQuery.setMinScore(query.getMinScore());
        fallbackQuery.setHasDeal(query.getHasDeal());
        fallbackQuery.setOpenNow(query.getOpenNow());
        fallbackQuery.setSort(query.getSort());
        fallbackQuery.setPage(query.getPage());
        fallbackQuery.setPageSize(query.getPageSize());
        return browseQueryService.listShops(region, fallbackQuery);
    }
}
