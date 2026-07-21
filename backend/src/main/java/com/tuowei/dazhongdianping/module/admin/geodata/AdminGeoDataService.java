package com.tuowei.dazhongdianping.module.admin.geodata;

import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.geodata.mapper.AdminGeoDataMapper;
import com.tuowei.dazhongdianping.module.admin.geodata.model.AdminAreaRow;
import com.tuowei.dazhongdianping.module.admin.geodata.model.AdminCategoryRow;
import com.tuowei.dazhongdianping.module.admin.geodata.model.AdminCityRow;
import com.tuowei.dazhongdianping.module.admin.geodata.model.request.AreaSaveRequest;
import com.tuowei.dazhongdianping.module.admin.geodata.model.request.CategorySaveRequest;
import com.tuowei.dazhongdianping.module.admin.geodata.model.request.CitySaveRequest;
import com.tuowei.dazhongdianping.module.admin.geodata.model.response.AdminAreaResponse;
import com.tuowei.dazhongdianping.module.admin.geodata.model.response.AdminCategoryResponse;
import com.tuowei.dazhongdianping.module.admin.geodata.model.response.AdminCityResponse;
import com.tuowei.dazhongdianping.module.search.event.ShopSearchIndexChangedEvent;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Objects;
import java.util.Set;
import java.util.function.IntSupplier;
import java.util.stream.Stream;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminGeoDataService {

    private final AdminGeoDataMapper mapper;
    private final ApplicationEventPublisher applicationEventPublisher;

    public AdminGeoDataService(AdminGeoDataMapper mapper,
                               ApplicationEventPublisher applicationEventPublisher) {
        this.mapper = mapper;
        this.applicationEventPublisher = applicationEventPublisher;
    }

    public List<AdminCategoryResponse> listCategories() {
        return mapper.selectCategories(region()).stream().map(this::toCategoryResponse).toList();
    }

    @Transactional
    public AdminCategoryResponse createCategory(CategorySaveRequest request) {
        String currentRegion = region();
        String name = request.name().trim();
        requireActiveCategoryParent(requireCategoryParent(null, request.parentId(), currentRegion));
        requireCategoryNameAvailable(request.parentId(), name, null, currentRegion);
        AdminCategoryRow row = new AdminCategoryRow();
        row.setParentId(request.parentId());
        row.setRegion(currentRegion);
        row.setName(name);
        row.setSortNo(request.sortNo());
        row.setStatus(1);
        runWithConflict(() -> mapper.insertCategory(row), "当前父分类下已存在同名分类");
        return toCategoryResponse(requireCategory(row.getId(), currentRegion));
    }

    @Transactional
    public AdminCategoryResponse updateCategory(Long id, CategorySaveRequest request) {
        String currentRegion = region();
        AdminCategoryRow row = lockCategoryUpdateScope(id, request.parentId(), currentRegion);
        String name = request.name().trim();
        boolean parentChanged = !Objects.equals(row.getParentId(), request.parentId());
        AdminCategoryRow parent = requireCategoryParent(id, request.parentId(), currentRegion);
        if (parentChanged) {
            requireActiveCategoryParent(parent);
        }
        requireCategoryNameAvailable(request.parentId(), name, id, currentRegion);
        row.setParentId(request.parentId());
        row.setName(name);
        row.setSortNo(request.sortNo());
        if (runWithConflict(() -> mapper.updateCategory(row), "当前父分类下已存在同名分类") != 1) {
            throw new NotFoundException("分类不存在");
        }
        return toCategoryResponse(requireCategory(id, currentRegion));
    }

    @Transactional
    public AdminCategoryResponse updateCategoryStatus(Long id, Integer status) {
        String currentRegion = region();
        AdminCategoryRow current = requireCategory(id, currentRegion);
        AdminCategoryRow row = lockCategoryUpdateScope(id, current.getParentId(), currentRegion);
        if (!Objects.equals(current.getParentId(), row.getParentId())) {
            throw new ConflictException("分类父级已变化，请刷新后重试");
        }
        if (status == 1) {
            requireActiveCategoryParent(requireCategoryParent(id, row.getParentId(), currentRegion));
        }
        if (row.getStatus().equals(status)) {
            return toCategoryResponse(row);
        }
        if (status == 0 && mapper.countEnabledCategoryChildren(currentRegion, id) > 0) {
            throw new ConflictException("分类仍有启用子分类，不能停用");
        }
        if (mapper.updateCategoryStatus(currentRegion, id, status) != 1) {
            throw new NotFoundException("分类不存在");
        }
        publishShopSearchIndexChanges(mapper.selectShopIdsByCategory(currentRegion, id));
        return toCategoryResponse(requireCategory(id, currentRegion));
    }

    @Transactional
    public void deleteCategory(Long id) {
        String currentRegion = region();
        requireCategoryForUpdate(id, currentRegion);
        if (mapper.countAnyCategoryChildren(currentRegion, id) > 0
                || mapper.countCategoryBusinessReferences(currentRegion, id) > 0) {
            throw new ConflictException("分类仍被子分类或业务数据引用，不能删除");
        }
        if (mapper.deleteCategory(currentRegion, id) != 1) {
            throw new NotFoundException("分类不存在");
        }
    }

    public List<AdminCityResponse> listCities() {
        return mapper.selectCities(region()).stream().map(this::toCityResponse).toList();
    }

    @Transactional
    public AdminCityResponse createCity(CitySaveRequest request) {
        String currentRegion = region();
        String code = normalizeCode(request.code());
        String name = request.name().trim();
        requireCityAvailable(code, name, null, currentRegion);
        AdminCityRow row = new AdminCityRow();
        row.setCode(code);
        row.setRegion(currentRegion);
        row.setName(name);
        row.setSortNo(request.sortNo());
        row.setStatus(1);
        runWithConflict(() -> mapper.insertCity(row), "当前区域已存在相同城市编码或名称");
        return toCityResponse(requireCity(row.getId(), currentRegion));
    }

    @Transactional
    public AdminCityResponse updateCity(Long id, CitySaveRequest request) {
        String currentRegion = region();
        AdminCityRow row = requireCityForUpdate(id, currentRegion);
        String code = normalizeCode(request.code());
        String name = request.name().trim();
        requireCityAvailable(code, name, id, currentRegion);
        row.setCode(code);
        row.setName(name);
        row.setSortNo(request.sortNo());
        if (runWithConflict(() -> mapper.updateCity(row), "当前区域已存在相同城市编码或名称") != 1) {
            throw new NotFoundException("城市不存在");
        }
        return toCityResponse(requireCity(id, currentRegion));
    }

    @Transactional
    public AdminCityResponse updateCityStatus(Long id, Integer status) {
        String currentRegion = region();
        AdminCityRow row = requireCityForUpdate(id, currentRegion);
        if (row.getStatus().equals(status)) {
            return toCityResponse(row);
        }
        if (mapper.updateCityStatus(currentRegion, id, status) != 1) {
            throw new NotFoundException("城市不存在");
        }
        publishShopSearchIndexChanges(mapper.selectShopIdsByCity(currentRegion, id));
        return toCityResponse(requireCity(id, currentRegion));
    }

    @Transactional
    public void deleteCity(Long id) {
        String currentRegion = region();
        requireCityForUpdate(id, currentRegion);
        if (mapper.countAreasByCity(currentRegion, id) > 0
                || mapper.countCityBusinessReferences(currentRegion, id) > 0) {
            throw new ConflictException("城市仍被商圈或业务数据引用，不能删除");
        }
        if (mapper.deleteCity(currentRegion, id) != 1) {
            throw new NotFoundException("城市不存在");
        }
    }

    public List<AdminAreaResponse> listAreas(Long cityId) {
        return mapper.selectAreas(region(), cityId).stream().map(this::toAreaResponse).toList();
    }

    @Transactional
    public AdminAreaResponse createArea(AreaSaveRequest request) {
        String currentRegion = region();
        requireActiveCityForUpdate(request.cityId(), currentRegion);
        String name = request.name().trim();
        requireAreaNameAvailable(request.cityId(), name, null, currentRegion);
        AdminAreaRow row = new AdminAreaRow();
        row.setCityId(request.cityId());
        row.setRegion(currentRegion);
        row.setName(name);
        row.setSortNo(request.sortNo());
        row.setStatus(1);
        runWithConflict(() -> mapper.insertArea(row), "当前城市已存在同名商圈");
        return toAreaResponse(requireArea(row.getId(), currentRegion));
    }

    @Transactional
    public AdminAreaResponse updateArea(Long id, AreaSaveRequest request) {
        String currentRegion = region();
        requireArea(id, currentRegion);
        requireActiveCityForUpdate(request.cityId(), currentRegion);
        AdminAreaRow row = requireAreaForUpdate(id, currentRegion);
        if (!row.getCityId().equals(request.cityId()) && hasAreaReferencesForUpdate(currentRegion, id)) {
            throw new ConflictException("商圈仍被业务数据引用，不能迁移到其他城市");
        }
        String name = request.name().trim();
        requireAreaNameAvailable(request.cityId(), name, id, currentRegion);
        row.setCityId(request.cityId());
        row.setName(name);
        row.setSortNo(request.sortNo());
        if (runWithConflict(() -> mapper.updateArea(row), "当前城市已存在同名商圈") != 1) {
            throw new NotFoundException("商圈不存在");
        }
        return toAreaResponse(requireArea(id, currentRegion));
    }

    @Transactional
    public AdminAreaResponse updateAreaStatus(Long id, Integer status) {
        String currentRegion = region();
        AdminAreaRow current = requireArea(id, currentRegion);
        if (status == 1) {
            requireActiveCityForUpdate(current.getCityId(), currentRegion);
        }
        AdminAreaRow row = requireAreaForUpdate(id, currentRegion);
        if (status == 1 && !current.getCityId().equals(row.getCityId())) {
            throw new ConflictException("商圈所属城市已变化，请刷新后重试");
        }
        if (row.getStatus().equals(status)) {
            return toAreaResponse(row);
        }
        if (mapper.updateAreaStatus(currentRegion, id, status) != 1) {
            throw new NotFoundException("商圈不存在");
        }
        publishShopSearchIndexChanges(mapper.selectShopIdsByArea(currentRegion, id));
        return toAreaResponse(requireArea(id, currentRegion));
    }

    @Transactional
    public void deleteArea(Long id) {
        String currentRegion = region();
        requireAreaForUpdate(id, currentRegion);
        if (mapper.countAreaReferences(currentRegion, id) > 0) {
            throw new ConflictException("商圈仍被业务数据引用，不能删除");
        }
        if (mapper.deleteArea(currentRegion, id) != 1) {
            throw new NotFoundException("商圈不存在");
        }
    }

    private AdminCategoryRow requireCategoryParent(Long categoryId, Long parentId, String currentRegion) {
        if (parentId == 0) {
            return null;
        }
        AdminCategoryRow directParent = requireCategoryForUpdate(parentId, currentRegion);
        if (categoryId == null) {
            return directParent;
        }
        Set<Long> visited = new HashSet<>();
        Long cursor = parentId;
        while (cursor != null && cursor != 0) {
            if (cursor.equals(categoryId) || !visited.add(cursor)) {
                throw new ConflictException("分类父级不能是自身或其后代分类");
            }
            AdminCategoryRow parent = mapper.selectCategory(currentRegion, cursor);
            if (parent == null) {
                break;
            }
            cursor = parent.getParentId();
        }
        return directParent;
    }

    private void requireActiveCategoryParent(AdminCategoryRow parent) {
        if (parent != null && parent.getStatus() != 1) {
            throw new ConflictException("父分类未启用，不能创建、迁移或启用子分类");
        }
    }

    private void requireCategoryNameAvailable(Long parentId, String name, Long excludeId, String currentRegion) {
        if (mapper.countCategoryNameConflict(currentRegion, parentId, name, excludeId) > 0) {
            throw new ConflictException("当前父分类下已存在同名分类");
        }
    }

    private void requireCityAvailable(String code, String name, Long excludeId, String currentRegion) {
        if (mapper.countCityCodeConflict(currentRegion, code, excludeId) > 0) {
            throw new ConflictException("当前区域已存在相同城市编码");
        }
        if (mapper.countCityNameConflict(currentRegion, name, excludeId) > 0) {
            throw new ConflictException("当前区域已存在同名城市");
        }
    }

    private void requireAreaNameAvailable(Long cityId, String name, Long excludeId, String currentRegion) {
        if (mapper.countAreaNameConflict(currentRegion, cityId, name, excludeId) > 0) {
            throw new ConflictException("当前城市已存在同名商圈");
        }
    }

    private AdminCategoryRow requireCategory(Long id, String currentRegion) {
        AdminCategoryRow row = mapper.selectCategory(currentRegion, id);
        if (row == null) {
            throw new NotFoundException("分类不存在");
        }
        return row;
    }

    private AdminCategoryRow requireCategoryForUpdate(Long id, String currentRegion) {
        AdminCategoryRow row = mapper.selectCategoryForUpdate(currentRegion, id);
        if (row == null) {
            throw new NotFoundException("分类不存在");
        }
        return row;
    }

    private AdminCategoryRow lockCategoryUpdateScope(Long id, Long parentId, String currentRegion) {
        AdminCategoryRow target = null;
        List<Long> ids = Stream.of(id, parentId)
                .filter(value -> value != null && value > 0)
                .distinct()
                .sorted()
                .toList();
        for (Long lockId : ids) {
            AdminCategoryRow row = requireCategoryForUpdate(lockId, currentRegion);
            if (lockId.equals(id)) {
                target = row;
            }
        }
        if (target == null) {
            throw new NotFoundException("分类不存在");
        }
        return target;
    }

    private AdminCityRow requireCity(Long id, String currentRegion) {
        AdminCityRow row = mapper.selectCity(currentRegion, id);
        if (row == null) {
            throw new NotFoundException("城市不存在");
        }
        return row;
    }

    private AdminCityRow requireCityForUpdate(Long id, String currentRegion) {
        AdminCityRow row = mapper.selectCityForUpdate(currentRegion, id);
        if (row == null) {
            throw new NotFoundException("城市不存在");
        }
        return row;
    }

    private void requireActiveCity(Long id, String currentRegion) {
        AdminCityRow city = mapper.selectCity(currentRegion, id);
        if (city == null || city.getStatus() != 1) {
            throw new ConflictException("城市不存在、不启用或不属于当前区域");
        }
    }

    private void requireActiveCityForUpdate(Long id, String currentRegion) {
        AdminCityRow city = mapper.selectCityForUpdate(currentRegion, id);
        if (city == null || city.getStatus() != 1) {
            throw new ConflictException("城市不存在、不启用或不属于当前区域");
        }
    }

    private AdminAreaRow requireArea(Long id, String currentRegion) {
        AdminAreaRow row = mapper.selectArea(currentRegion, id);
        if (row == null) {
            throw new NotFoundException("商圈不存在");
        }
        return row;
    }

    private AdminAreaRow requireAreaForUpdate(Long id, String currentRegion) {
        AdminAreaRow row = mapper.selectAreaForUpdate(currentRegion, id);
        if (row == null) {
            throw new NotFoundException("商圈不存在");
        }
        return row;
    }

    private boolean hasAreaReferencesForUpdate(String currentRegion, Long areaId) {
        return mapper.selectShopAreaReferenceForUpdate(currentRegion, areaId) != null
                || mapper.selectShopChangeAreaReferenceForUpdate(currentRegion, areaId) != null;
    }

    private void publishShopSearchIndexChanges(List<Long> shopIds) {
        shopIds.forEach(shopId -> applicationEventPublisher.publishEvent(new ShopSearchIndexChangedEvent(shopId)));
    }

    private void runWithConflict(Runnable operation, String message) {
        try {
            operation.run();
        } catch (DuplicateKeyException exception) {
            throw new ConflictException(message);
        }
    }

    private int runWithConflict(IntSupplier operation, String message) {
        try {
            return operation.getAsInt();
        } catch (DuplicateKeyException exception) {
            throw new ConflictException(message);
        }
    }

    private AdminCategoryResponse toCategoryResponse(AdminCategoryRow row) {
        return new AdminCategoryResponse(
                row.getId(), row.getParentId(), row.getName(), row.getSortNo(), row.getStatus());
    }

    private AdminCityResponse toCityResponse(AdminCityRow row) {
        return new AdminCityResponse(
                row.getId(), row.getCode(), row.getName(), row.getSortNo(), row.getStatus());
    }

    private AdminAreaResponse toAreaResponse(AdminAreaRow row) {
        return new AdminAreaResponse(
                row.getId(), row.getCityId(), row.getName(), row.getSortNo(), row.getStatus());
    }

    private String normalizeCode(String code) {
        return code.trim().toUpperCase(Locale.ROOT);
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
