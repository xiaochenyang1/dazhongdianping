package com.tuowei.dazhongdianping.module.admin.geodata;

import static java.util.concurrent.TimeUnit.MILLISECONDS;
import static java.util.concurrent.TimeUnit.SECONDS;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doAnswer;

import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.geodata.mapper.AdminGeoDataMapper;
import com.tuowei.dazhongdianping.module.admin.management.mapper.AdminManagementMapper;
import com.tuowei.dazhongdianping.module.admin.management.model.AdminShopRow;
import com.tuowei.dazhongdianping.module.admin.management.model.request.AdminShopSaveRequest;
import com.tuowei.dazhongdianping.module.admin.management.model.response.AdminShopDetailResponse;
import com.tuowei.dazhongdianping.module.admin.management.service.AdminManagementService;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeoutException;
import org.junit.jupiter.api.Test;
import org.mybatis.spring.SqlSessionTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.jdbc.core.JdbcTemplate;

@SpringBootTest
class AdminGeoDataConcurrencyTest {

    @Autowired
    private AdminGeoDataService geoDataService;

    @Autowired
    private AdminManagementService managementService;

    @Autowired
    private JdbcTemplate jdbc;

    @Autowired
    private SqlSessionTemplate sqlSessionTemplate;

    @SpyBean
    private AdminManagementMapper managementMapper;

    @SpyBean
    private AdminGeoDataMapper geoDataMapper;

    @Test
    void shouldSerializeCategoryDeleteWithConcurrentShopWrite() throws Exception {
        String suffix = UUID.randomUUID().toString();
        String categoryName = "Concurrent Category " + suffix;
        String shopName = "Concurrent Shop " + suffix;
        jdbc.update("INSERT INTO category(parent_id,region,name,sort_no,status) VALUES(0,'CN',?,999,1)",
                categoryName);
        long categoryId = jdbc.queryForObject(
                "SELECT id FROM category WHERE region='CN' AND name=?", Long.class, categoryName);

        CountDownLatch insertReached = new CountDownLatch(1);
        CountDownLatch releaseInsert = new CountDownLatch(1);
        CountDownLatch deleteLockAttempted = new CountDownLatch(1);
        AdminManagementMapper realMapper = sqlSessionTemplate.getMapper(AdminManagementMapper.class);
        AdminGeoDataMapper realGeoDataMapper = sqlSessionTemplate.getMapper(AdminGeoDataMapper.class);
        doAnswer(invocation -> {
            insertReached.countDown();
            if (!releaseInsert.await(5, SECONDS)) {
                throw new IllegalStateException("等待并发删除超时");
            }
            realMapper.insertShop(invocation.getArgument(0, AdminShopRow.class));
            return null;
        }).when(managementMapper).insertShop(any());
        doAnswer(invocation -> {
            deleteLockAttempted.countDown();
            return realGeoDataMapper.selectCategoryForUpdate(
                    invocation.getArgument(0, String.class), invocation.getArgument(1, Long.class));
        }).when(geoDataMapper).selectCategoryForUpdate(anyString(), anyLong());

        ExecutorService executor = Executors.newFixedThreadPool(2);
        try {
            Future<Object> writeFuture = executor.submit(() -> createShop(categoryId, shopName));
            assertTrue(insertReached.await(5, SECONDS), "门店写入未进入插入阶段");
            Future<Object> deleteFuture = executor.submit(() -> deleteCategory(categoryId));
            assertTrue(deleteLockAttempted.await(5, SECONDS), "分类删除未进入行锁查询");
            boolean deleteWasBlocked;
            try {
                deleteFuture.get(300, MILLISECONDS);
                deleteWasBlocked = false;
            } catch (TimeoutException expected) {
                deleteWasBlocked = true;
            } finally {
                releaseInsert.countDown();
            }
            Object writeResult = writeFuture.get(5, SECONDS);
            Object deleteResult = deleteFuture.get(5, SECONDS);
            assertTrue(deleteWasBlocked, "删除必须等待持有分类行锁的门店写入事务");
            assertInstanceOf(AdminShopDetailResponse.class, writeResult);
            ConflictException conflict = assertInstanceOf(ConflictException.class, deleteResult);
            assertEquals("分类仍被子分类或业务数据引用，不能删除", conflict.getMessage());
            assertEquals(1, jdbc.queryForObject(
                    "SELECT COUNT(1) FROM category WHERE id=?", Integer.class, categoryId));
            assertEquals(1, jdbc.queryForObject(
                    "SELECT COUNT(1) FROM shop WHERE category_id=? AND name=?",
                    Integer.class, categoryId, shopName));
        } finally {
            releaseInsert.countDown();
            executor.shutdownNow();
            executor.awaitTermination(5, SECONDS);
            jdbc.update("DELETE FROM shop WHERE name=?", shopName);
            jdbc.update("DELETE FROM category WHERE id=?", categoryId);
        }
    }

    private Object createShop(long categoryId, String shopName) {
        RegionContext.setRegion(Region.CN);
        try {
            AdminShopSaveRequest request = new AdminShopSaveRequest();
            request.setMerchantId(1001L);
            request.setRegion("CN");
            request.setCategoryId(categoryId);
            request.setCityId(1L);
            request.setAreaId(11L);
            request.setName(shopName);
            request.setCoverUrl("https://example.com/concurrent.jpg");
            request.setPhone("021-10000000");
            request.setPricePerCapita(BigDecimal.valueOf(88));
            request.setCurrency("CNY");
            request.setAddress("上海市并发测试路1号");
            request.setBusinessHours("10:00-22:00");
            request.setSummary("基础数据并发引用保护测试");
            request.setTags(List.of("并发测试"));
            return managementService.createShop(request);
        } catch (RuntimeException exception) {
            return exception;
        } finally {
            RegionContext.clear();
        }
    }

    private Object deleteCategory(long categoryId) {
        RegionContext.setRegion(Region.CN);
        try {
            geoDataService.deleteCategory(categoryId);
            return Boolean.TRUE;
        } catch (RuntimeException exception) {
            return exception;
        } finally {
            RegionContext.clear();
        }
    }
}
