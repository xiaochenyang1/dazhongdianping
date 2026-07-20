package com.tuowei.dazhongdianping.module.admin.management.controller;

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
        assertTrue(errorFileContent.contains("分类不存在或不属于当前区域"), "导入失败明细文件应该写入失败原因");

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

    private String loginToken() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "admin",
                                  "password": "admin123456"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.data.profile.account").value("admin"))
                .andExpect(jsonPath("$.data.profile.name").value("系统管理员"))
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
