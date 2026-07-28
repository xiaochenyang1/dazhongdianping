package com.tuowei.dazhongdianping.module.admin.management.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

@Transactional
@SpringBootTest
@AutoConfigureMockMvc
class AdminManagementControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void shouldRejectAdminRequestWithoutToken() throws Exception {
        mockMvc.perform(get("/api/admin/v1/shops"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));
    }

    @Test
    void shouldCreateUpdateAndDeleteShop() throws Exception {
        String token = loginToken();

        MvcResult createResult = mockMvc.perform(post("/api/admin/v1/shops")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.ofEntries(
                                Map.entry("merchantId", 1001),
                                Map.entry("region", "CN"),
                                Map.entry("categoryId", 102),
                                Map.entry("cityId", 1),
                                Map.entry("areaId", 11),
                                Map.entry("name", "后台新建测试门店"),
                                Map.entry("coverUrl", "https://placehold.co/1200x720/334155/ffffff?text=Admin+Create"),
                                Map.entry("phone", "021-69998888"),
                                Map.entry("pricePerCapita", 96),
                                Map.entry("currency", "CNY"),
                                Map.entry("address", "上海市徐汇区测试路99号"),
                                Map.entry("latitude", 31.18345),
                                Map.entry("longitude", 121.43678),
                                Map.entry("businessHours", "10:00-21:00"),
                                Map.entry("summary", "后台新建门店最小链路验证。"),
                                Map.entry("score", 4.2),
                                Map.entry("tasteScore", 4.1),
                                Map.entry("envScore", 4.2),
                                Map.entry("serviceScore", 4.3),
                                Map.entry("hasDeal", true),
                                Map.entry("openNow", true),
                                Map.entry("status", 1),
                                Map.entry("tags", new String[]{"测试", "后台"})
                        ))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("后台新建测试门店"))
                .andExpect(jsonPath("$.data.latitude").value(31.18345))
                .andExpect(jsonPath("$.data.longitude").value(121.43678))
                .andReturn();

        long shopId = readId(createResult, "/data/id");

        mockMvc.perform(put("/api/admin/v1/shops/{shopId}", shopId)
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.ofEntries(
                                Map.entry("merchantId", 1001),
                                Map.entry("region", "CN"),
                                Map.entry("categoryId", 102),
                                Map.entry("cityId", 1),
                                Map.entry("areaId", 11),
                                Map.entry("name", "后台更新后的测试门店"),
                                Map.entry("coverUrl", "https://placehold.co/1200x720/475569/ffffff?text=Admin+Update"),
                                Map.entry("phone", "021-69997777"),
                                Map.entry("pricePerCapita", 108),
                                Map.entry("currency", "CNY"),
                                Map.entry("address", "上海市徐汇区更新路88号"),
                                Map.entry("latitude", 31.19456),
                                Map.entry("longitude", 121.44789),
                                Map.entry("businessHours", "11:00-22:00"),
                                Map.entry("summary", "后台更新门店链路验证。"),
                                Map.entry("score", 4.4),
                                Map.entry("tasteScore", 4.5),
                                Map.entry("envScore", 4.3),
                                Map.entry("serviceScore", 4.4),
                                Map.entry("hasDeal", false),
                                Map.entry("openNow", false),
                                Map.entry("status", 2),
                                Map.entry("tags", new String[]{"更新", "停业"})
                        ))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("后台更新后的测试门店"))
                .andExpect(jsonPath("$.data.latitude").value(31.19456))
                .andExpect(jsonPath("$.data.longitude").value(121.44789))
                .andExpect(jsonPath("$.data.status").value(2));

        mockMvc.perform(get("/api/admin/v1/shops/{shopId}", shopId)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("后台更新后的测试门店"))
                .andExpect(jsonPath("$.data.latitude").value(31.19456))
                .andExpect(jsonPath("$.data.longitude").value(121.44789))
                .andExpect(jsonPath("$.data.tags[0]").value("更新"));

        mockMvc.perform(delete("/api/admin/v1/shops/{shopId}", shopId)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0));

        mockMvc.perform(get("/api/admin/v1/shops/{shopId}", shopId)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value(404));
    }

    @Test
    void shouldRejectCrossRegionShopIdOperations() throws Exception {
        String token = loginToken();

        mockMvc.perform(get("/api/admin/v1/shops/20001")
                        .header("X-Region", "CN")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value(404));

        mockMvc.perform(put("/api/admin/v1/shops/20001")
                        .header("X-Region", "CN")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.ofEntries(
                                Map.entry("merchantId", 2001),
                                Map.entry("region", "EU"),
                                Map.entry("categoryId", 201),
                                Map.entry("cityId", 101),
                                Map.entry("areaId", 1011),
                                Map.entry("name", "不应被跨区修改的门店"),
                                Map.entry("coverUrl", "https://placehold.co/1200x720/7c3aed/ffffff?text=EU+Sichuan"),
                                Map.entry("phone", "+33142345678"),
                                Map.entry("pricePerCapita", 36),
                                Map.entry("currency", "EUR"),
                                Map.entry("address", "12 Rue du Temple, Paris"),
                                Map.entry("businessHours", "11:30-22:30"),
                                Map.entry("summary", "中国区请求不得修改欧洲区门店。"),
                                Map.entry("score", 4.6),
                                Map.entry("tasteScore", 4.7),
                                Map.entry("envScore", 4.4),
                                Map.entry("serviceScore", 4.5),
                                Map.entry("hasDeal", true),
                                Map.entry("openNow", true),
                                Map.entry("status", 1),
                                Map.entry("tags", new String[]{"Chinese", "Spicy"})
                        ))))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value(404));

        mockMvc.perform(delete("/api/admin/v1/shops/20001")
                        .header("X-Region", "CN")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value(404));

        mockMvc.perform(get("/api/admin/v1/shops/20001")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Maison Sichuan Paris"));
    }

    @Test
    void shouldUseRequestRegionInsteadOfShopQueryParameter() throws Exception {
        mockMvc.perform(get("/api/admin/v1/shops")
                        .header("X-Region", "CN")
                        .header("Authorization", bearer(loginToken()))
                        .param("region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(2))
                .andExpect(jsonPath("$.data.list[0].region").value("CN"))
                .andExpect(jsonPath("$.data.list[1].region").value("CN"));
    }

    @Test
    void shouldLimitShopReadsToTheAuthorizedCitiesAndKeepAllCitiesBehavior() throws Exception {
        String parisToken = cityScopedAdminToken("shop_reader_paris", false, 101L);

        mockMvc.perform(get("/api/admin/v1/shops")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(parisToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(20001));

        mockMvc.perform(get("/api/admin/v1/shops")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(parisToken))
                        .param("cityId", "102"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(0))
                .andExpect(jsonPath("$.data.list").isEmpty());

        mockMvc.perform(get("/api/admin/v1/shops/20001")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(parisToken)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.cityId").value(101));

        mockMvc.perform(get("/api/admin/v1/shops/20002")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(parisToken)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value(404));

        mockMvc.perform(get("/api/admin/v1/shops")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(loginToken())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(2))
                .andExpect(jsonPath("$.data.list[0].id").value(20002))
                .andExpect(jsonPath("$.data.list[1].id").value(20001));
    }

    @Test
    void shouldConcealOutOfScopeShopsAndRejectMovingAnAuthorizedShopToAnotherCity() throws Exception {
        String token = cityScopedAdminToken("shop_writer_paris", false, 101L);
        String berlinName = jdbcTemplate.queryForObject(
                "SELECT name FROM shop WHERE id=20002", String.class);

        mockMvc.perform(put("/api/admin/v1/shops/20002")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(euShopBody("Berlin scope violation", 102L)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value(404));

        mockMvc.perform(delete("/api/admin/v1/shops/20002")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value(404));

        assertEquals(berlinName, jdbcTemplate.queryForObject(
                "SELECT name FROM shop WHERE id=20002", String.class));
        assertEquals(Boolean.FALSE, jdbcTemplate.queryForObject(
                "SELECT is_deleted FROM shop WHERE id=20002", Boolean.class));

        mockMvc.perform(put("/api/admin/v1/shops/20001")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(euShopBody("Paris shop moved to Berlin", 102L)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value(403))
                .andExpect(jsonPath("$.message").value("当前管理员无权操作该城市"));

        assertEquals(101L, jdbcTemplate.queryForObject(
                "SELECT city_id FROM shop WHERE id=20001", Long.class));
        assertEquals("Maison Sichuan Paris", jdbcTemplate.queryForObject(
                "SELECT name FROM shop WHERE id=20001", String.class));
    }

    @Test
    void shouldEnforceTheTargetCityWhenCreatingShops() throws Exception {
        String token = cityScopedAdminToken("shop_creator_paris", false, 101L);

        mockMvc.perform(post("/api/admin/v1/shops")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(euShopBody("Unauthorized Berlin creation", 102L)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value(403))
                .andExpect(jsonPath("$.message").value("当前管理员无权操作该城市"));
        assertEquals(0, jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM shop WHERE name='Unauthorized Berlin creation'", Integer.class));

        mockMvc.perform(post("/api/admin/v1/shops")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(euShopBody("Authorized Paris creation", 101L)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Authorized Paris creation"))
                .andExpect(jsonPath("$.data.cityId").value(101));
        assertEquals(1, jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM shop WHERE name='Authorized Paris creation' AND city_id=101", Integer.class));
    }

    @Test
    void shouldPreflightEveryImportCityBeforeCreatingAnyBatchMerchantOrShop() throws Exception {
        String token = cityScopedAdminToken("shop_importer_paris", false, 101L);
        String mixedFileName = "mixed-city-scope-import.json";

        mockMvc.perform(post("/api/admin/v1/import/shops")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "fileName", mixedFileName,
                                "region", "EU",
                                "records", new Object[]{
                                        euImportRecord(
                                                "city-scope-mixed-paris@example.com",
                                                "Mixed Paris Merchant",
                                                "Mixed Paris Shop",
                                                101L),
                                        euImportRecord(
                                                "city-scope-mixed-berlin@example.com",
                                                "Mixed Berlin Merchant",
                                                "Mixed Berlin Shop",
                                                102L)
                                }
                        ))))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value(403))
                .andExpect(jsonPath("$.message").value("当前管理员无权操作该城市"));

        assertEquals(0, jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM import_batch WHERE file_name=?", Integer.class, mixedFileName));
        assertEquals(0, jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM merchant WHERE account IN "
                        + "('city-scope-mixed-paris@example.com','city-scope-mixed-berlin@example.com')",
                Integer.class));
        assertEquals(0, jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM shop WHERE name IN ('Mixed Paris Shop','Mixed Berlin Shop')",
                Integer.class));

        String parisFileName = "paris-city-scope-import.json";
        mockMvc.perform(post("/api/admin/v1/import/shops")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "fileName", parisFileName,
                                "region", "EU",
                                "records", new Object[]{
                                        euImportRecord(
                                                "city-scope-paris-only@example.com",
                                                "Paris Only Merchant",
                                                "Paris Only Shop",
                                                101L)
                                }
                        ))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.success").value(1))
                .andExpect(jsonPath("$.data.failed").value(0));

        assertEquals(1, jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM import_batch WHERE file_name=?", Integer.class, parisFileName));
        assertEquals(1, jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM merchant WHERE account='city-scope-paris-only@example.com'", Integer.class));
        assertEquals(1, jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM shop WHERE name='Paris Only Shop' AND city_id=101", Integer.class));
    }

    @Test
    void shouldFailClosedWhenNoCitiesAreGrantedForTheRegion() throws Exception {
        String token = cityScopedAdminToken("shop_scope_empty", false);

        mockMvc.perform(get("/api/admin/v1/shops")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(0));
        mockMvc.perform(get("/api/admin/v1/shops/20001")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isNotFound());
        mockMvc.perform(post("/api/admin/v1/shops")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(euShopBody("No city scope creation", 101L)))
                .andExpect(status().isForbidden());
    }

    @Test
    void shouldEnforceSelectedShopWhitelist() throws Exception {
        String token = shopScopedAdminToken("shop_scope_whitelist", 20001L);

        mockMvc.perform(get("/api/admin/v1/shops")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].id").value(20001));

        mockMvc.perform(get("/api/admin/v1/shops/20002")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isNotFound());

        mockMvc.perform(put("/api/admin/v1/shops/20001")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(euShopBody("Paris whitelist update", 101L)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Paris whitelist update"));

        mockMvc.perform(post("/api/admin/v1/shops")
                        .header("X-Region", "EU")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(euShopBody("Whitelist cannot create", 101L)))
                .andExpect(status().isForbidden());
    }

    @Test
    void shouldRejectCreateShopWhenBodyRegionDiffersFromRequestRegion() throws Exception {
        mockMvc.perform(post("/api/admin/v1/shops")
                        .header("X-Region", "CN")
                        .header("Authorization", bearer(loginToken()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.ofEntries(
                                Map.entry("merchantId", 2001),
                                Map.entry("region", "EU"),
                                Map.entry("categoryId", 201),
                                Map.entry("cityId", 101),
                                Map.entry("areaId", 1011),
                                Map.entry("name", "不该跨区创建的门店"),
                                Map.entry("coverUrl", "https://placehold.co/1200x720/0f172a/ffffff?text=Cross+Region+Create"),
                                Map.entry("phone", "+33142345678"),
                                Map.entry("score", 4.6),
                                Map.entry("tasteScore", 4.7),
                                Map.entry("envScore", 4.4),
                                Map.entry("serviceScore", 4.5),
                                Map.entry("pricePerCapita", 36),
                                Map.entry("currency", "EUR"),
                                Map.entry("address", "12 Rue du Temple, Paris"),
                                Map.entry("businessHours", "11:30-22:30"),
                                Map.entry("summary", "这条请求要是能跨区创建成功，那权限设计就真成摆设了。"),
                                Map.entry("hasDeal", true),
                                Map.entry("openNow", true),
                                Map.entry("status", 1),
                                Map.entry("tags", new String[]{"Cross", "Region"})
                        ))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").value("region 必须与请求头 X-Region 一致"));
    }

    @Test
    void shouldRejectUpdateShopWhenBodyRegionDiffersFromRequestRegion() throws Exception {
        mockMvc.perform(put("/api/admin/v1/shops/10001")
                        .header("X-Region", "CN")
                        .header("Authorization", bearer(loginToken()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.ofEntries(
                                Map.entry("merchantId", 2001),
                                Map.entry("region", "EU"),
                                Map.entry("categoryId", 201),
                                Map.entry("cityId", 101),
                                Map.entry("areaId", 1011),
                                Map.entry("name", "不该跨区更新的门店"),
                                Map.entry("coverUrl", "https://placehold.co/1200x720/1d4ed8/ffffff?text=Cross+Region+Update"),
                                Map.entry("phone", "+33142345678"),
                                Map.entry("score", 4.5),
                                Map.entry("tasteScore", 4.6),
                                Map.entry("envScore", 4.4),
                                Map.entry("serviceScore", 4.5),
                                Map.entry("pricePerCapita", 35),
                                Map.entry("currency", "EUR"),
                                Map.entry("address", "12 Rue du Temple, Paris"),
                                Map.entry("businessHours", "11:30-22:30"),
                                Map.entry("summary", "更新接口也别想钻区域空子。"),
                                Map.entry("hasDeal", true),
                                Map.entry("openNow", true),
                                Map.entry("status", 1),
                                Map.entry("tags", new String[]{"Cross", "Update"})
                        ))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").value("region 必须与请求头 X-Region 一致"));
    }

    @Test
    void shouldRejectImportShopsWhenBodyRegionDiffersFromRequestRegion() throws Exception {
        mockMvc.perform(post("/api/admin/v1/import/shops")
                        .header("X-Region", "CN")
                        .header("Authorization", bearer(loginToken()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "fileName", "seed-cross-region-eu-shops.xlsx",
                                "region", "EU",
                                "records", new Object[]{
                                        Map.ofEntries(
                                                Map.entry("merchantAccount", "seed-cross-region-eu-001@example.com"),
                                                Map.entry("companyName", "跨区导入商户"),
                                                Map.entry("contactName", "导入员"),
                                                Map.entry("contactPhone", "+33123456789"),
                                                Map.entry("shopName", "不该跨区导入的门店"),
                                                Map.entry("categoryId", 201),
                                                Map.entry("cityId", 101),
                                                Map.entry("areaId", 1011),
                                                Map.entry("address", "12 Rue du Temple, Paris"),
                                                Map.entry("phone", "+33142345678"),
                                                Map.entry("businessHours", "11:30-22:30"),
                                                Map.entry("pricePerCapita", 36),
                                                Map.entry("coverUrl", "https://placehold.co/1200x720/059669/ffffff?text=Cross+Region+Import"),
                                                Map.entry("summary", "导入接口更不能偷摸跨区写数据。"),
                                                Map.entry("score", 4.6),
                                                Map.entry("tasteScore", 4.7),
                                                Map.entry("envScore", 4.4),
                                                Map.entry("serviceScore", 4.5),
                                                Map.entry("currency", "EUR"),
                                                Map.entry("hasDeal", true),
                                                Map.entry("openNow", true),
                                                Map.entry("tags", new String[]{"Cross", "Import"})
                                        )
                                }
                        ))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(400))
                .andExpect(jsonPath("$.message").value("region 必须与请求头 X-Region 一致"));
    }

    @Test
    void shouldImportShopsAndQueryBatches() throws Exception {
        String token = loginToken();

        MvcResult importResult = mockMvc.perform(post("/api/admin/v1/import/shops")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "fileName", "seed-cn-shops.xlsx",
                                "region", "CN",
                                "records", new Object[]{
                                        Map.ofEntries(
                                                Map.entry("merchantAccount", "seed-import-cn-001@example.com"),
                                                Map.entry("companyName", "导入测试商户一号"),
                                                Map.entry("contactName", "导入员"),
                                                Map.entry("contactPhone", "13812345678"),
                                                Map.entry("shopName", "导入测试火锅店"),
                                                Map.entry("categoryId", 102),
                                                Map.entry("cityId", 1),
                                                Map.entry("areaId", 11),
                                                Map.entry("address", "上海市测试导入路18号"),
                                                Map.entry("latitude", 31.17654),
                                                Map.entry("longitude", 121.42567),
                                                Map.entry("phone", "021-12345678"),
                                                Map.entry("businessHours", "09:00-22:00"),
                                                Map.entry("pricePerCapita", 118),
                                                Map.entry("coverUrl", "https://placehold.co/1200x720/ef4444/ffffff?text=Import+OK"),
                                                Map.entry("summary", "导入成功样例"),
                                                Map.entry("score", 4.1),
                                                Map.entry("tasteScore", 4.2),
                                                Map.entry("envScore", 4.0),
                                                Map.entry("serviceScore", 4.1),
                                                Map.entry("hasDeal", true),
                                                Map.entry("openNow", true),
                                                Map.entry("tags", new String[]{"导入", "火锅"})
                                        ),
                                        Map.ofEntries(
                                                Map.entry("merchantAccount", "seed-import-cn-002@example.com"),
                                                Map.entry("companyName", "导入测试商户二号"),
                                                Map.entry("contactName", "导入员"),
                                                Map.entry("contactPhone", "13812349999"),
                                                Map.entry("shopName", "导入失败样例店"),
                                                Map.entry("categoryId", 99999),
                                                Map.entry("cityId", 1),
                                                Map.entry("areaId", 11),
                                                Map.entry("address", "上海市错误路88号"),
                                                Map.entry("phone", "021-00000000"),
                                                Map.entry("businessHours", "10:00-20:00"),
                                                Map.entry("pricePerCapita", 68),
                                                Map.entry("coverUrl", "https://placehold.co/1200x720/64748b/ffffff?text=Import+Fail"),
                                                Map.entry("summary", "导入失败样例"),
                                                Map.entry("score", 3.8),
                                                Map.entry("tasteScore", 3.7),
                                                Map.entry("envScore", 3.8),
                                                Map.entry("serviceScore", 3.9),
                                                Map.entry("hasDeal", false),
                                                Map.entry("openNow", true),
                                                Map.entry("tags", new String[]{"失败"})
                                        )
                                }
                        ))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(2))
                .andExpect(jsonPath("$.data.success").value(1))
                .andExpect(jsonPath("$.data.failed").value(1))
                .andExpect(jsonPath("$.data.errorMessages.length()").value(1))
                .andExpect(jsonPath("$.data.errorFile").isNotEmpty())
                .andReturn();

        String errorFile = readText(importResult, "/data/errorFile");
        Path errorFilePath = Path.of(errorFile);
        assertTrue(Files.isRegularFile(errorFilePath), "导入失败明细文件应该真实落盘");
        String errorFileContent = Files.readString(errorFilePath);
        assertTrue(errorFileContent.contains("分类不存在、不启用或不属于当前区域"), "导入失败明细文件应该写入失败原因");

        mockMvc.perform(get("/api/admin/v1/import/batches")
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].fileName").value("seed-cn-shops.xlsx"))
                .andExpect(jsonPath("$.data.list[0].success").value(1))
                .andExpect(jsonPath("$.data.list[0].failed").value(1))
                .andExpect(jsonPath("$.data.list[0].errorFile").value(errorFile));

        MvcResult importedShopResult = mockMvc.perform(get("/api/admin/v1/shops")
                        .header("Authorization", bearer(token))
                        .param("keyword", "导入测试火锅店"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].name").value("导入测试火锅店"))
                .andReturn();

        long importedShopId = readId(importedShopResult, "/data/list/0/id");
        mockMvc.perform(get("/api/admin/v1/shops/{shopId}", importedShopId)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.latitude").value(31.17654))
                .andExpect(jsonPath("$.data.longitude").value(121.42567));
    }

    @Test
    void shouldLimitRestrictedAdminsToTheirOwnImportBatches() throws Exception {
        String suffix = "import_batch_scope";
        String token = cityScopedAdminToken(suffix, false, 101L);
        Long adminId = jdbcTemplate.queryForObject(
                "SELECT id FROM admin_user WHERE account=?", Long.class, suffix + "@example.com");
        jdbcTemplate.update(
                "INSERT INTO import_batch(admin_id,region,file_name,total,success,failed,status,error_file) "
                        + "VALUES (?,'EU','own-eu-import.xlsx',1,1,0,1,'')",
                adminId
        );
        jdbcTemplate.update(
                "INSERT INTO import_batch(admin_id,region,file_name,total,success,failed,status,error_file) "
                        + "VALUES (1,'EU','other-admin-import.xlsx',1,0,1,2,'local-storage/import-errors/private.json')"
        );

        mockMvc.perform(get("/api/admin/v1/import/batches")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].fileName").value("own-eu-import.xlsx"))
                .andExpect(jsonPath("$.data.list[0].errorFile").value(""));

        mockMvc.perform(get("/api/admin/v1/import/batches")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .param("status", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(0))
                .andExpect(jsonPath("$.data.list").isEmpty());

        mockMvc.perform(get("/api/admin/v1/import/batches")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .param("status", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].fileName").value("own-eu-import.xlsx"));
    }

    @Test
    void shouldAllowUnrestrictedAdminsToReadOtherAdminsImportBatches() throws Exception {
        String token = cityScopedAdminToken("import_batch_all_cities", true);
        jdbcTemplate.update("DELETE FROM import_batch WHERE region='EU'");
        jdbcTemplate.update(
                "INSERT INTO import_batch(admin_id,region,file_name,total,success,failed,status,error_file) "
                        + "VALUES (1,'EU','regional-import.xlsx',1,0,1,2,'regional-errors.json')"
        );

        mockMvc.perform(get("/api/admin/v1/import/batches")
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU")
                        .param("status", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.total").value(1))
                .andExpect(jsonPath("$.data.list[0].fileName").value("regional-import.xlsx"));
    }

    @Test
    void shouldRejectDisabledCategoryForShopCreate() throws Exception {
        String token = loginToken();
        jdbcTemplate.update("UPDATE category SET status=0 WHERE id=102");
        mockMvc.perform(post("/api/admin/v1/shops")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validShopBody("停用分类创建测试")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message")
                        .value("分类不存在、不启用或不属于当前区域"));
    }

    @Test
    void shouldRejectDisabledCityForShopUpdate() throws Exception {
        String token = loginToken();
        jdbcTemplate.update("UPDATE city SET status=0 WHERE id=1");
        mockMvc.perform(put("/api/admin/v1/shops/{shopId}", 10001L)
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validShopBody("停用城市更新测试")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message")
                        .value("城市不存在、不启用或不属于当前区域"));
    }

    @Test
    void shouldKeepDisabledAreaImportFailureDetail() throws Exception {
        String token = loginToken();
        jdbcTemplate.update("UPDATE area SET status=0 WHERE id=11");
        mockMvc.perform(post("/api/admin/v1/import/shops")
                        .header("Authorization", bearer(token))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "fileName":"disabled-area.json",
                                  "region":"CN",
                                  "records":[{
                                    "merchantAccount":"disabled-area@example.com",
                                    "companyName":"停用商圈导入商户",
                                    "contactName":"测试员",
                                    "contactPhone":"13800000009",
                                    "shopName":"停用商圈导入门店",
                                    "categoryId":102,"cityId":1,"areaId":11,
                                    "address":"上海测试路1号","phone":"021-10000000",
                                    "businessHours":"10:00-22:00","pricePerCapita":88,
                                    "coverUrl":"https://example.com/disabled-area.jpg",
                                    "summary":"停用商圈导入回归","score":4.0,
                                    "tasteScore":4.0,"envScore":4.0,"serviceScore":4.0,
                                    "currency":"CNY","hasDeal":false,"openNow":true,"tags":[]
                                  }]
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.success").value(0))
                .andExpect(jsonPath("$.data.failed").value(1))
                .andExpect(jsonPath("$.data.errorMessages[0]")
                        .value("第 1 条失败: 商圈不存在、不启用或不属于当前城市"));
        assertEquals(0, jdbcTemplate.queryForObject(
                "SELECT COUNT(1) FROM merchant WHERE account='disabled-area@example.com'",
                Integer.class));
    }

    private String validShopBody(String name) throws Exception {
        return objectMapper.writeValueAsString(Map.ofEntries(
                Map.entry("merchantId", 1001),
                Map.entry("region", "CN"),
                Map.entry("categoryId", 102),
                Map.entry("cityId", 1),
                Map.entry("areaId", 11),
                Map.entry("name", name),
                Map.entry("coverUrl", "https://example.com/admin-geo.jpg"),
                Map.entry("phone", "021-10000000"),
                Map.entry("pricePerCapita", 88),
                Map.entry("currency", "CNY"),
                Map.entry("address", "上海市测试路1号"),
                Map.entry("businessHours", "10:00-22:00"),
                Map.entry("summary", "基础数据启用状态回归"),
                Map.entry("score", 4.0),
                Map.entry("tasteScore", 4.0),
                Map.entry("envScore", 4.0),
                Map.entry("serviceScore", 4.0),
                Map.entry("hasDeal", false),
                Map.entry("openNow", true),
                Map.entry("status", 1),
                Map.entry("tags", new String[]{"测试"})
        ));
    }

    private String euShopBody(String name, long cityId) throws Exception {
        boolean paris = cityId == 101L;
        return objectMapper.writeValueAsString(Map.ofEntries(
                Map.entry("merchantId", paris ? 2001 : 2002),
                Map.entry("region", "EU"),
                Map.entry("categoryId", paris ? 201 : 202),
                Map.entry("cityId", cityId),
                Map.entry("areaId", paris ? 1011 : 1021),
                Map.entry("name", name),
                Map.entry("coverUrl", "https://example.com/city-scope-shop.jpg"),
                Map.entry("phone", paris ? "+33100000000" : "+49300000000"),
                Map.entry("pricePerCapita", 40),
                Map.entry("currency", "EUR"),
                Map.entry("address", paris ? "1 Rue de Test, Paris" : "1 Teststrasse, Berlin"),
                Map.entry("businessHours", "10:00-22:00"),
                Map.entry("summary", "城市数据范围集成测试门店。"),
                Map.entry("score", 4.2),
                Map.entry("tasteScore", 4.2),
                Map.entry("envScore", 4.2),
                Map.entry("serviceScore", 4.2),
                Map.entry("hasDeal", false),
                Map.entry("openNow", true),
                Map.entry("status", 1),
                Map.entry("tags", new String[]{"Scope"})
        ));
    }

    private Map<String, Object> euImportRecord(String merchantAccount,
                                                String companyName,
                                                String shopName,
                                                long cityId) {
        boolean paris = cityId == 101L;
        return Map.ofEntries(
                Map.entry("merchantAccount", merchantAccount),
                Map.entry("companyName", companyName),
                Map.entry("contactName", "Scope Tester"),
                Map.entry("contactPhone", paris ? "+33100000001" : "+49300000001"),
                Map.entry("shopName", shopName),
                Map.entry("categoryId", paris ? 201 : 202),
                Map.entry("cityId", cityId),
                Map.entry("areaId", paris ? 1011 : 1021),
                Map.entry("address", paris ? "2 Rue de Test, Paris" : "2 Teststrasse, Berlin"),
                Map.entry("phone", paris ? "+33100000002" : "+49300000002"),
                Map.entry("businessHours", "10:00-22:00"),
                Map.entry("pricePerCapita", 30),
                Map.entry("coverUrl", "https://example.com/city-scope-import.jpg"),
                Map.entry("summary", "城市数据范围导入测试门店。"),
                Map.entry("score", 4.1),
                Map.entry("tasteScore", 4.1),
                Map.entry("envScore", 4.1),
                Map.entry("serviceScore", 4.1),
                Map.entry("currency", "EUR"),
                Map.entry("hasDeal", false),
                Map.entry("openNow", true),
                Map.entry("tags", new String[]{"Scope", "Import"})
        );
    }

    private String cityScopedAdminToken(String suffix, boolean allCities, Long... cityIds) throws Exception {
        String account = suffix + "@example.com";
        String roleCode = suffix + "_role";
        String passwordHash = jdbcTemplate.queryForObject(
                "SELECT password_hash FROM admin_user WHERE id=1", String.class);
        jdbcTemplate.update(
                "INSERT INTO admin_user(account,password_hash,name,status) VALUES(?,?,?,1)",
                account, passwordHash, "城市范围测试管理员");
        Long adminId = jdbcTemplate.queryForObject(
                "SELECT id FROM admin_user WHERE account=?", Long.class, account);
        jdbcTemplate.update(
                "INSERT INTO admin_role(code,name,description,status,built_in) VALUES(?,?,?,1,FALSE)",
                roleCode, "城市范围测试角色", "门店城市范围集成测试");
        Long roleId = jdbcTemplate.queryForObject(
                "SELECT id FROM admin_role WHERE code=?", Long.class, roleCode);
        jdbcTemplate.update("INSERT INTO admin_user_role(admin_id,role_id) VALUES(?,?)", adminId, roleId);
        jdbcTemplate.update("""
                INSERT INTO admin_role_permission(role_id,permission_id)
                SELECT ?,id FROM admin_permission
                WHERE code IN ('data:shop:read','data:shop:write','data:shop:import','data:import_batch:read')
                """, roleId);
        jdbcTemplate.update(
                "INSERT INTO admin_region_scope(admin_id,region,all_cities) VALUES(?,'EU',?)",
                adminId, allCities);
        for (Long cityId : cityIds) {
            jdbcTemplate.update(
                    "INSERT INTO admin_city_scope(admin_id,region,city_id) VALUES(?,'EU',?)",
                    adminId, cityId);
        }
        return loginToken(account, "城市范围测试管理员");
    }

    private String shopScopedAdminToken(String suffix, Long... shopIds) throws Exception {
        String account = suffix + "@example.com";
        String roleCode = suffix + "_role";
        String passwordHash = jdbcTemplate.queryForObject(
                "SELECT password_hash FROM admin_user WHERE id=1", String.class);
        jdbcTemplate.update(
                "INSERT INTO admin_user(account,password_hash,name,status) VALUES(?,?,?,1)",
                account, passwordHash, "门店白名单测试管理员");
        Long adminId = jdbcTemplate.queryForObject(
                "SELECT id FROM admin_user WHERE account=?", Long.class, account);
        jdbcTemplate.update(
                "INSERT INTO admin_role(code,name,description,status,built_in) VALUES(?,?,?,1,FALSE)",
                roleCode, "门店白名单测试角色", "门店白名单集成测试");
        Long roleId = jdbcTemplate.queryForObject(
                "SELECT id FROM admin_role WHERE code=?", Long.class, roleCode);
        jdbcTemplate.update("INSERT INTO admin_user_role(admin_id,role_id) VALUES(?,?)", adminId, roleId);
        jdbcTemplate.update("""
                INSERT INTO admin_role_permission(role_id,permission_id)
                SELECT ?,id FROM admin_permission
                WHERE code IN ('data:shop:read','data:shop:write')
                """, roleId);
        jdbcTemplate.update(
                "INSERT INTO admin_region_scope(admin_id,region,all_cities) VALUES(?,'EU',FALSE)", adminId);
        for (Long shopId : shopIds) {
            jdbcTemplate.update(
                    "INSERT INTO admin_shop_scope(admin_id,region,shop_id) VALUES(?,'EU',?)",
                    adminId, shopId);
        }
        return loginToken(account, "门店白名单测试管理员");
    }

    private String loginToken() throws Exception {
        return loginToken("admin", "系统管理员");
    }

    private String loginToken(String account, String expectedName) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "account", account,
                                "password", "admin123456"
                        ))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.data.profile.account").value(account))
                .andExpect(jsonPath("$.data.profile.name").value(expectedName))
                .andReturn();
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsString());
        return root.path("data").path("accessToken").asText();
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }

    private long readId(MvcResult result, String pointer) throws Exception {
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsString());
        return root.at(pointer).asLong();
    }

    private String readText(MvcResult result, String pointer) throws Exception {
        JsonNode root = objectMapper.readTree(result.getResponse().getContentAsString());
        return root.at(pointer).asText();
    }
}
