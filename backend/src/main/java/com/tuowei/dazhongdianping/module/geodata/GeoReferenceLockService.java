package com.tuowei.dazhongdianping.module.geodata;

import com.tuowei.dazhongdianping.module.geodata.mapper.GeoReferenceLockMapper;
import java.util.Collection;
import java.util.List;
import java.util.Objects;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class GeoReferenceLockService {

    private final GeoReferenceLockMapper mapper;

    public GeoReferenceLockService(GeoReferenceLockMapper mapper) {
        this.mapper = mapper;
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void requireActiveShopReferences(String region, Long categoryId, Long cityId, Long areaId) {
        if (mapper.lockActiveCategory(region, categoryId) == null) {
            throw new IllegalArgumentException("分类不存在、不启用或不属于当前区域");
        }
        if (mapper.lockActiveCity(region, cityId) == null) {
            throw new IllegalArgumentException("城市不存在、不启用或不属于当前区域");
        }
        if (mapper.lockActiveArea(region, cityId, areaId) == null) {
            throw new IllegalArgumentException("商圈不存在、不启用或不属于当前城市");
        }
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void lockInOrder(String region,
                            Collection<Long> categoryIds,
                            Collection<Long> cityIds,
                            Collection<Long> areaIds) {
        List<Long> categories = sortedDistinct(categoryIds);
        List<Long> cities = sortedDistinct(cityIds);
        List<Long> areas = sortedDistinct(areaIds);
        if (!categories.isEmpty()) {
            mapper.lockCategories(region, categories);
        }
        if (!cities.isEmpty()) {
            mapper.lockCities(region, cities);
        }
        if (!areas.isEmpty()) {
            mapper.lockAreas(region, areas);
        }
    }

    private List<Long> sortedDistinct(Collection<Long> ids) {
        return ids.stream()
                .filter(Objects::nonNull)
                .distinct()
                .sorted()
                .toList();
    }
}
