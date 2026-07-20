package com.tuowei.dazhongdianping.module.search.service;

import com.tuowei.dazhongdianping.config.SearchProperties;
import com.tuowei.dazhongdianping.module.search.gateway.ShopSearchIndexGateway;
import com.tuowei.dazhongdianping.module.search.mapper.SearchIndexMapper;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchDocument;
import com.tuowei.dazhongdianping.module.search.model.ShopSearchDocumentRow;
import java.util.List;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
public class ShopSearchIndexService {
    private final SearchProperties searchProperties;
    private final SearchIndexMapper searchIndexMapper;
    private final ShopSearchIndexGateway indexGateway;
    private final ShopNamePinyinConverter pinyinConverter;

    public ShopSearchIndexService(SearchProperties searchProperties,
                                  SearchIndexMapper searchIndexMapper,
                                  @Qualifier("elasticsearchShopSearchGateway") ShopSearchIndexGateway indexGateway,
                                  ShopNamePinyinConverter pinyinConverter) {
        this.searchProperties = searchProperties;
        this.searchIndexMapper = searchIndexMapper;
        this.indexGateway = indexGateway;
        this.pinyinConverter = pinyinConverter;
    }

    public int rebuildAll() {
        requireElasticsearchProvider();
        List<ShopSearchDocument> documents = searchIndexMapper.selectActiveShops().stream().map(this::toDocument).toList();
        indexGateway.rebuildIndex(documents);
        return documents.size();
    }

    public void syncShop(Long shopId) {
        if (searchProperties.getProvider() != SearchProperties.Provider.ELASTICSEARCH) {
            return;
        }
        ShopSearchDocumentRow row = searchIndexMapper.selectActiveShop(shopId);
        if (row == null) {
            indexGateway.deleteDocument(shopId);
            return;
        }
        indexGateway.indexDocument(toDocument(row));
    }

    private ShopSearchDocument toDocument(ShopSearchDocumentRow row) {
        return ShopSearchDocument.builder()
                .id(row.getId()).region(row.getRegion()).name(row.getName())
                .namePinyin(pinyinConverter.convert(row.getName()))
                .categoryId(row.getCategoryId()).categoryName(row.getCategoryName())
                .cityId(row.getCityId()).cityName(row.getCityName())
                .areaId(row.getAreaId()).areaName(row.getAreaName())
                .latitude(row.getLatitude()).longitude(row.getLongitude())
                .coverUrl(row.getCoverUrl()).score(row.getScore()).reviewCount(row.getReviewCount())
                .pricePerCapita(row.getPricePerCapita()).currency(row.getCurrency()).address(row.getAddress())
                .hasDeal(row.getHasDeal()).openNow(row.getOpenNow()).status(row.getStatus())
                .tags(splitTags(row.getTags())).dishNames(searchIndexMapper.selectDishNames(row.getId()))
                .build();
    }

    private List<String> splitTags(String tags) {
        if (!StringUtils.hasText(tags)) {
            return List.of();
        }
        return List.of(tags.split(",")).stream().map(String::trim).filter(StringUtils::hasText).toList();
    }

    private void requireElasticsearchProvider() {
        if (searchProperties.getProvider() != SearchProperties.Provider.ELASTICSEARCH) {
            throw new IllegalArgumentException("APP_SEARCH_PROVIDER 必须为 elasticsearch 才能重建索引");
        }
    }
}
