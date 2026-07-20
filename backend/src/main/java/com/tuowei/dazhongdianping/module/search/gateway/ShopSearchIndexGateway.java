package com.tuowei.dazhongdianping.module.search.gateway;

import com.tuowei.dazhongdianping.module.search.model.ShopSearchDocument;
import java.util.List;

public interface ShopSearchIndexGateway {

    void rebuildIndex(List<ShopSearchDocument> documents);

    void indexDocument(ShopSearchDocument document);

    void deleteDocument(Long shopId);
}
