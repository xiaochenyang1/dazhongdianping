package com.tuowei.dazhongdianping.module.search.service;

import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.config.SearchProperties;
import com.tuowei.dazhongdianping.module.browse.model.response.ShopListItemResponse;
import com.tuowei.dazhongdianping.module.browse.service.BrowseQueryService;
import com.tuowei.dazhongdianping.module.search.gateway.ShopSearchGateway;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchQuery;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;

@Service
public class ShopSearchService {

    private static final Logger LOGGER = LoggerFactory.getLogger(ShopSearchService.class);

    private final SearchProperties searchProperties;
    private final ShopSearchGateway mysqlGateway;
    private final ShopSearchGateway elasticsearchGateway;
    private final BrowseQueryService browseQueryService;

    public ShopSearchService(SearchProperties searchProperties,
                             @Qualifier("mysqlShopSearchGateway") ShopSearchGateway mysqlGateway,
                             @Qualifier("elasticsearchShopSearchGateway") ShopSearchGateway elasticsearchGateway,
                             @Lazy BrowseQueryService browseQueryService) {
        this.searchProperties = searchProperties;
        this.mysqlGateway = mysqlGateway;
        this.elasticsearchGateway = elasticsearchGateway;
        this.browseQueryService = browseQueryService;
    }

    public PageResult<ShopListItemResponse> search(Region region, ShopSearchQuery query) {
        query.normalize();
        // Record before provider fan-out so ES path also keeps search history.
        browseQueryService.recordSearchHistoryIfNeeded(region, query.getKeyword());
        PageResult<ShopListItemResponse> page;
        if (searchProperties.getProvider() == SearchProperties.Provider.MYSQL) {
            page = mysqlGateway.search(region, query);
        } else {
            try {
                page = elasticsearchGateway.search(region, query);
            } catch (RuntimeException exception) {
                if (!searchProperties.isFallbackOnError()) {
                    throw exception;
                }
                LOGGER.warn("Elasticsearch shop search failed, falling back to MySQL: {}", exception.getMessage());
                LOGGER.debug("Elasticsearch shop search failure details", exception);
                page = mysqlGateway.search(region, query);
            }
        }
        return new PageResult<>(
                browseQueryService.attachMerchantCertifications(page.list(), region.name()),
                page.total(),
                page.page(),
                page.pageSize(),
                page.hasMore()
        );
    }
}
