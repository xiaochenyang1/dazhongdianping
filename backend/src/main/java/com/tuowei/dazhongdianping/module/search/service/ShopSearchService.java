package com.tuowei.dazhongdianping.module.search.service;

import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.config.SearchProperties;
import com.tuowei.dazhongdianping.module.browse.model.response.ShopListItemResponse;
import com.tuowei.dazhongdianping.module.search.gateway.ShopSearchGateway;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchQuery;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;

@Service
public class ShopSearchService {

    private static final Logger LOGGER = LoggerFactory.getLogger(ShopSearchService.class);

    private final SearchProperties searchProperties;
    private final ShopSearchGateway mysqlGateway;
    private final ShopSearchGateway elasticsearchGateway;

    public ShopSearchService(SearchProperties searchProperties,
                             @Qualifier("mysqlShopSearchGateway") ShopSearchGateway mysqlGateway,
                             @Qualifier("elasticsearchShopSearchGateway") ShopSearchGateway elasticsearchGateway) {
        this.searchProperties = searchProperties;
        this.mysqlGateway = mysqlGateway;
        this.elasticsearchGateway = elasticsearchGateway;
    }

    public PageResult<ShopListItemResponse> search(Region region, ShopSearchQuery query) {
        query.normalize();
        if (searchProperties.getProvider() == SearchProperties.Provider.MYSQL) {
            return mysqlGateway.search(region, query);
        }
        try {
            return elasticsearchGateway.search(region, query);
        } catch (RuntimeException exception) {
            if (!searchProperties.isFallbackOnError()) {
                throw exception;
            }
            LOGGER.warn("Elasticsearch shop search failed, falling back to MySQL: {}", exception.getMessage());
            LOGGER.debug("Elasticsearch shop search failure details", exception);
            return mysqlGateway.search(region, query);
        }
    }
}
