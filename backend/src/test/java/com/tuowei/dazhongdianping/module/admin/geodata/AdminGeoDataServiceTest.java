package com.tuowei.dazhongdianping.module.admin.geodata;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.module.admin.geodata.mapper.AdminGeoDataMapper;
import com.tuowei.dazhongdianping.module.admin.geodata.model.AdminAreaRow;
import com.tuowei.dazhongdianping.module.admin.geodata.model.AdminCategoryRow;
import com.tuowei.dazhongdianping.module.admin.geodata.model.AdminCityRow;
import com.tuowei.dazhongdianping.module.admin.geodata.model.request.AreaSaveRequest;
import com.tuowei.dazhongdianping.module.admin.geodata.model.request.CategorySaveRequest;
import com.tuowei.dazhongdianping.module.admin.geodata.model.request.CitySaveRequest;
import com.tuowei.dazhongdianping.module.search.event.ShopSearchIndexChangedEvent;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.mockito.InOrder;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.dao.DuplicateKeyException;

class AdminGeoDataServiceTest {

    @Test
    void shouldTranslateCategoryDuplicateKeyToConflict() {
        AdminGeoDataMapper mapper = mock(AdminGeoDataMapper.class);
        AdminGeoDataService service = new AdminGeoDataService(mapper, mock(ApplicationEventPublisher.class));
        doThrow(new DuplicateKeyException("duplicate category")).when(mapper).insertCategory(any());

        ConflictException exception = assertThrows(ConflictException.class,
                () -> service.createCategory(new CategorySaveRequest(0L, "Dining", 1)));

        assertEquals("当前父分类下已存在同名分类", exception.getMessage());
    }

    @Test
    void shouldTranslateCityDuplicateKeyToConflict() {
        AdminGeoDataMapper mapper = mock(AdminGeoDataMapper.class);
        AdminGeoDataService service = new AdminGeoDataService(mapper, mock(ApplicationEventPublisher.class));
        doThrow(new DuplicateKeyException("duplicate city")).when(mapper).insertCity(any());

        ConflictException exception = assertThrows(ConflictException.class,
                () -> service.createCity(new CitySaveRequest("PAR", "Paris", 1)));

        assertEquals("当前区域已存在相同城市编码或名称", exception.getMessage());
    }

    @Test
    void shouldTranslateAreaDuplicateKeyToConflict() {
        AdminGeoDataMapper mapper = mock(AdminGeoDataMapper.class);
        AdminGeoDataService service = new AdminGeoDataService(mapper, mock(ApplicationEventPublisher.class));
        AdminCityRow city = new AdminCityRow();
        city.setId(1L);
        city.setRegion("CN");
        city.setStatus(1);
        when(mapper.selectCityForUpdate("CN", 1L)).thenReturn(city);
        doThrow(new DuplicateKeyException("duplicate area")).when(mapper).insertArea(any());

        ConflictException exception = assertThrows(ConflictException.class,
                () -> service.createArea(new AreaSaveRequest(1L, "Downtown", 1)));

        assertEquals("当前城市已存在同名商圈", exception.getMessage());
    }

    @Test
    void shouldLockActiveCityBeforeEnablingArea() {
        AdminGeoDataMapper mapper = mock(AdminGeoDataMapper.class);
        AdminGeoDataService service = new AdminGeoDataService(mapper, mock(ApplicationEventPublisher.class));
        AdminAreaRow area = new AdminAreaRow();
        area.setId(10L);
        area.setCityId(1L);
        area.setRegion("CN");
        area.setStatus(0);
        AdminCityRow city = new AdminCityRow();
        city.setId(1L);
        city.setRegion("CN");
        city.setStatus(1);
        when(mapper.selectArea("CN", 10L)).thenReturn(area);
        when(mapper.selectAreaForUpdate("CN", 10L)).thenReturn(area);
        when(mapper.selectCity("CN", 1L)).thenReturn(city);
        when(mapper.selectCityForUpdate("CN", 1L)).thenReturn(city);
        when(mapper.updateAreaStatus("CN", 10L, 1)).thenReturn(1);

        service.updateAreaStatus(10L, 1);

        InOrder order = inOrder(mapper);
        order.verify(mapper).selectArea("CN", 10L);
        order.verify(mapper).selectCityForUpdate("CN", 1L);
        order.verify(mapper).selectAreaForUpdate("CN", 10L);
        order.verify(mapper).updateAreaStatus("CN", 10L, 1);
    }

    @Test
    void shouldPublishAffectedShopEventsAfterCategoryStatusChanges() {
        AdminGeoDataMapper mapper = mock(AdminGeoDataMapper.class);
        ApplicationEventPublisher publisher = mock(ApplicationEventPublisher.class);
        AdminGeoDataService service = new AdminGeoDataService(mapper, publisher);
        AdminCategoryRow category = category(10L, 0L, 1);
        when(mapper.selectCategory("CN", 10L)).thenReturn(category);
        when(mapper.selectCategoryForUpdate("CN", 10L)).thenReturn(category);
        when(mapper.updateCategoryStatus("CN", 10L, 0)).thenReturn(1);
        when(mapper.selectShopIdsByCategory("CN", 10L)).thenReturn(List.of(10001L, 10002L));

        service.updateCategoryStatus(10L, 0);

        verify(publisher).publishEvent(new ShopSearchIndexChangedEvent(10001L));
        verify(publisher).publishEvent(new ShopSearchIndexChangedEvent(10002L));
    }

    @Test
    void shouldNotPublishShopEventsWhenCategoryStatusDoesNotChange() {
        AdminGeoDataMapper mapper = mock(AdminGeoDataMapper.class);
        ApplicationEventPublisher publisher = mock(ApplicationEventPublisher.class);
        AdminGeoDataService service = new AdminGeoDataService(mapper, publisher);
        AdminCategoryRow category = category(10L, 0L, 1);
        when(mapper.selectCategory("CN", 10L)).thenReturn(category);
        when(mapper.selectCategoryForUpdate("CN", 10L)).thenReturn(category);

        service.updateCategoryStatus(10L, 1);

        verify(mapper, never()).selectShopIdsByCategory("CN", 10L);
        verify(publisher, never()).publishEvent(org.mockito.ArgumentMatchers.any());
    }

    private AdminCategoryRow category(Long id, Long parentId, Integer status) {
        AdminCategoryRow row = new AdminCategoryRow();
        row.setId(id);
        row.setParentId(parentId);
        row.setRegion("CN");
        row.setName("Category " + id);
        row.setSortNo(1);
        row.setStatus(status);
        return row;
    }
}
