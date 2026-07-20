package com.tuowei.dazhongdianping.module.search.gateway;

import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.module.browse.model.response.ShopListItemResponse;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchQuery;

public interface ShopSearchGateway {

    PageResult<ShopListItemResponse> search(Region region, ShopSearchQuery query);
}
