package com.tuowei.dazhongdianping.module.search.mapper;

import com.tuowei.dazhongdianping.module.search.model.ShopSearchDocumentRow;
import java.util.List;
import org.apache.ibatis.annotations.Param;

public interface SearchIndexMapper {
    List<ShopSearchDocumentRow> selectActiveShops();
    ShopSearchDocumentRow selectActiveShop(@Param("shopId") Long shopId);
    List<String> selectDishNames(@Param("shopId") Long shopId);
}
