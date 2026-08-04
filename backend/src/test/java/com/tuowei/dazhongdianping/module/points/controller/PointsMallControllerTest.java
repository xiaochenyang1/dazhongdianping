package com.tuowei.dazhongdianping.module.points.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.startsWith;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
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
class PointsMallControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    void shouldRequireLoginForExchangeButNotForBrowsing() throws Exception {
        mockMvc.perform(get("/api/c/v1/points/products"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.code").value(0))
                .andExpect(jsonPath("$.data.list[0].fulfillTypeText").value("自动发放"));

        long productId = autoFulfillProductId();
        mockMvc.perform(post("/api/c/v1/points/products/{id}/exchange", productId))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.code").value(401));

        mockMvc.perform(get("/api/c/v1/points/exchanges"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void shouldExposeRedeemCodeOnlyAfterFulfilment() throws Exception {
        String token = registerUser("points-redeem@example.com", "兑换码用户");
        grantPoints("points-redeem@example.com", 2000);

        long manualProductId = manualFulfillProductId();
        MvcResult manual = mockMvc.perform(post("/api/c/v1/points/products/{id}/exchange", manualProductId)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(0))
                .andExpect(jsonPath("$.data.statusText").value("待发放"))
                // 人工发放单在运营真正备货前不能把兑换码给用户。
                .andExpect(jsonPath("$.data.redeemCode").value(""))
                .andReturn();
        long manualExchangeId = readLong(manual, "/data/id");

        mockMvc.perform(get("/api/c/v1/points/exchanges").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].redeemCode").value(""));

        String adminToken = loginAdmin();
        mockMvc.perform(post("/api/admin/v1/points/exchanges/{id}/fulfill", manualExchangeId)
                        .header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"redeemCode\":\"PTMANUALCODE0001\",\"remark\":\"线下已备货\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1));

        mockMvc.perform(post("/api/admin/v1/points/exchanges/{id}/fulfill", manualExchangeId)
                        .header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"redeemCode\":\"PTDUPLICATE\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("兑换单已处理"));

        mockMvc.perform(get("/api/c/v1/points/exchanges").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].redeemCode").value("PTMANUALCODE0001"))
                .andExpect(jsonPath("$.data.list[0].statusText").value("已发放"));
    }

    @Test
    void shouldFulfilAutomaticExchangeImmediatelyAndDeductPoints() throws Exception {
        String account = "points-auto@example.com";
        String token = registerUser(account, "自动发放用户");
        grantPoints(account, 500);
        long productId = autoFulfillProductId();
        int price = jdbcTemplate.queryForObject(
                "SELECT points_price FROM points_product WHERE id = ?", Integer.class, productId);
        int stockBefore = stockOf(productId);

        mockMvc.perform(post("/api/c/v1/points/products/{id}/exchange", productId)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1))
                .andExpect(jsonPath("$.data.statusText").value("已发放"))
                .andExpect(jsonPath("$.data.redeemCode").value(startsWith("PT")));

        assertPoints(account, 500 - price);
        assertThat(stockOf(productId)).isEqualTo(stockBefore - 1);
    }

    @Test
    void shouldRejectExchangeWhenPointsAreInsufficient() throws Exception {
        String account = "points-broke@example.com";
        String token = registerUser(account, "积分不足用户");
        long productId = autoFulfillProductId();

        mockMvc.perform(post("/api/c/v1/points/products/{id}/exchange", productId)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("积分不足"));

        assertPoints(account, 0);
        // 库存回滚不在这里断言：本类是 @Transactional，exchange() 只是加入测试事务，
        // 抛错时事务被标记 rollback-only，要等最外层（测试）事务结束才真正回滚，
        // 同一事务内读到的仍是已扣减值。生产环境 exchange() 是最外层事务，会真回滚。
    }

    @Test
    void shouldEnforcePerUserExchangeLimit() throws Exception {
        String account = "points-limit@example.com";
        String token = registerUser(account, "限购用户");
        grantPoints(account, 5000);
        Long productId = jdbcTemplate.queryForObject(
                "SELECT id FROM points_product WHERE region = 'CN' AND status = 1 AND is_deleted = FALSE "
                        + "AND exchange_limit_per_user = 1 AND fulfill_type = 1 ORDER BY id LIMIT 1",
                Long.class);

        mockMvc.perform(post("/api/c/v1/points/products/{id}/exchange", productId)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/c/v1/points/products/{id}/exchange", productId)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("已达到该商品的兑换上限"));
    }

    @Test
    void shouldRefundPointsAndRestoreStockWhenAdminCancels() throws Exception {
        String account = "points-cancel@example.com";
        String token = registerUser(account, "取消兑换用户");
        grantPoints(account, 2000);
        long manualProductId = manualFulfillProductId();
        int price = jdbcTemplate.queryForObject(
                "SELECT points_price FROM points_product WHERE id = ?", Integer.class, manualProductId);
        int stockBefore = stockOf(manualProductId);

        MvcResult exchange = mockMvc.perform(post("/api/c/v1/points/products/{id}/exchange", manualProductId)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andReturn();
        long exchangeId = readLong(exchange, "/data/id");
        assertPoints(account, 2000 - price);

        String adminToken = loginAdmin();
        mockMvc.perform(post("/api/admin/v1/points/exchanges/{id}/cancel", exchangeId)
                        .header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"remark\":\"库存对不上，退回\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(2));

        assertPoints(account, 2000);
        assertThat(stockOf(manualProductId)).isEqualTo(stockBefore);

        mockMvc.perform(get("/api/c/v1/points/exchanges").header("Authorization", bearer(token)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[0].statusText").value("已取消"))
                .andExpect(jsonPath("$.data.list[0].redeemCode").value(""));

        mockMvc.perform(post("/api/admin/v1/points/exchanges/{id}/cancel", exchangeId)
                        .header("Authorization", bearer(adminToken))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"remark\":\"重复取消\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("兑换单已处理"));
    }

    @Test
    void shouldRejectExchangeForOfflineProduct() throws Exception {
        String account = "points-offline@example.com";
        String token = registerUser(account, "下架商品用户");
        grantPoints(account, 2000);
        long productId = autoFulfillProductId();
        jdbcTemplate.update("UPDATE points_product SET status = 0 WHERE id = ?", productId);

        mockMvc.perform(post("/api/c/v1/points/products/{id}/exchange", productId)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("商品不存在或已下架"));

        mockMvc.perform(get("/api/c/v1/points/products/{id}", productId))
                .andExpect(status().isNotFound());
    }

    @Test
    void shouldRejectExchangeWhenStockIsExhausted() throws Exception {
        String account = "points-soldout@example.com";
        String token = registerUser(account, "兑完用户");
        grantPoints(account, 2000);
        long productId = autoFulfillProductId();
        jdbcTemplate.update("UPDATE points_product SET stock = 0 WHERE id = ?", productId);

        mockMvc.perform(post("/api/c/v1/points/products/{id}/exchange", productId)
                        .header("Authorization", bearer(token)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("商品已兑完"));

        assertPoints(account, 2000);
    }

    @Test
    void shouldIsolateProductsByRegion() throws Exception {
        MvcResult cn = mockMvc.perform(get("/api/c/v1/points/products").header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andReturn();
        MvcResult eu = mockMvc.perform(get("/api/c/v1/points/products").header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode cnList = objectMapper.readTree(cn.getResponse().getContentAsString()).at("/data/list");
        JsonNode euList = objectMapper.readTree(eu.getResponse().getContentAsString()).at("/data/list");
        assertThat(cnList).isNotEmpty();
        assertThat(euList).isNotEmpty();
        cnList.forEach(node ->
                assertThat(node.get("region").asText()).isEqualTo("CN"));
        euList.forEach(node ->
                assertThat(node.get("region").asText()).isEqualTo("EU"));
    }

    @Test
    void shouldRejectAdminExchangeListWithInvalidStatus() throws Exception {
        String adminToken = loginAdmin();
        mockMvc.perform(get("/api/admin/v1/points/exchanges")
                        .header("Authorization", bearer(adminToken))
                        .param("status", "9"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("status 仅支持 0/1/2"));
    }

    @Test
    void shouldValidateProductStatusAndProtectRegionScopedMutations() throws Exception {
        String adminToken = loginAdmin();
        long cnProductId = autoFulfillProductId();

        mockMvc.perform(put("/api/admin/v1/points/products/{id}/status", cnProductId)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":2}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("status 仅支持 0/1"));

        MvcResult euProduct = mockMvc.perform(post("/api/admin/v1/points/products")
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name":"跨区校验商品",
                                  "coverImage":"",
                                  "description":"",
                                  "pointsPrice":100,
                                  "stock":1,
                                  "exchangeLimitPerUser":0,
                                  "fulfillType":1,
                                  "sort":99
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();
        long euProductId = readLong(euProduct, "/data/id");

        mockMvc.perform(put("/api/admin/v1/points/products/{id}", euProductId)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name":"不应更新",
                                  "pointsPrice":100,
                                  "stock":1,
                                  "exchangeLimitPerUser":0,
                                  "fulfillType":1,
                                  "sort":99
                                }
                                """))
                .andExpect(status().isNotFound());

        mockMvc.perform(get("/api/admin/v1/points/products")
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.list[*].region").value(org.hamcrest.Matchers.everyItem(org.hamcrest.Matchers.is("CN"))));
    }

    @Test
    void shouldCreateUpdateDisableAndDeleteProduct() throws Exception {
        String adminToken = loginAdmin();
        MvcResult created = mockMvc.perform(post("/api/admin/v1/points/products")
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name":"生命周期测试商品",
                                  "coverImage":"https://example.com/points.png",
                                  "description":"初始说明",
                                  "pointsPrice":120,
                                  "stock":3,
                                  "exchangeLimitPerUser":2,
                                  "fulfillType":2,
                                  "sort":8
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(1))
                .andExpect(jsonPath("$.data.fulfillType").value(2))
                .andReturn();
        long productId = readLong(created, "/data/id");

        mockMvc.perform(put("/api/admin/v1/points/products/{id}", productId)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name":"生命周期测试商品（更新）",
                                  "coverImage":"",
                                  "description":"更新说明",
                                  "pointsPrice":150,
                                  "stock":4,
                                  "exchangeLimitPerUser":0,
                                  "fulfillType":1,
                                  "sort":9
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("生命周期测试商品（更新）"))
                .andExpect(jsonPath("$.data.pointsPrice").value(150));

        mockMvc.perform(put("/api/admin/v1/points/products/{id}/status", productId)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":0}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value(0));

        mockMvc.perform(delete("/api/admin/v1/points/products/{id}", productId)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN"))
                .andExpect(status().isOk());
        assertThat(jdbcTemplate.queryForObject(
                "SELECT is_deleted FROM points_product WHERE id = ?", Boolean.class, productId)).isTrue();
    }

    @Test
    void shouldEnforceReadOnlyPointsPermission() throws Exception {
        String readerToken = createReadOnlyAdminAndLogin();
        mockMvc.perform(get("/api/admin/v1/points/products")
                        .header("Authorization", bearer(readerToken))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/admin/v1/points/products")
                        .header("Authorization", bearer(readerToken))
                        .header("X-Region", "EU")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"只读不应创建\",\"pointsPrice\":10,\"stock\":1}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void shouldRejectAdminExchangeMutationAcrossRegions() throws Exception {
        String account = "points-cross-region@example.com";
        String token = registerUser(account, "跨区域兑换用户");
        grantPoints(account, 2000);
        long euProductId = manualFulfillProductId("EU");
        MvcResult exchange = mockMvc.perform(post("/api/c/v1/points/products/{id}/exchange", euProductId)
                        .header("Authorization", bearer(token))
                        .header("X-Region", "EU"))
                .andExpect(status().isOk())
                .andReturn();
        long exchangeId = readLong(exchange, "/data/id");

        String adminToken = loginAdmin();
        mockMvc.perform(post("/api/admin/v1/points/exchanges/{id}/fulfill", exchangeId)
                        .header("Authorization", bearer(adminToken))
                        .header("X-Region", "CN")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"redeemCode\":\"PTCROSSREGION\"}"))
                .andExpect(status().isNotFound());
    }

    private long autoFulfillProductId() {
        return jdbcTemplate.queryForObject(
                "SELECT id FROM points_product WHERE region = 'CN' AND status = 1 AND is_deleted = FALSE "
                        + "AND fulfill_type = 1 AND exchange_limit_per_user <> 1 ORDER BY id LIMIT 1",
                Long.class);
    }

    private long manualFulfillProductId() {
        return manualFulfillProductId("CN");
    }

    private long manualFulfillProductId(String region) {
        return jdbcTemplate.queryForObject(
                "SELECT id FROM points_product WHERE region = ? AND status = 1 AND is_deleted = FALSE "
                        + "AND fulfill_type = 2 ORDER BY id LIMIT 1",
                Long.class, region);
    }

    private int stockOf(long productId) {
        return jdbcTemplate.queryForObject(
                "SELECT stock FROM points_product WHERE id = ?", Integer.class, productId);
    }

    private void grantPoints(String account, int points) {
        jdbcTemplate.update("UPDATE app_user SET points = ? WHERE email = ?", points, account);
    }

    private void assertPoints(String account, int expected) {
        Integer actual = jdbcTemplate.queryForObject(
                "SELECT points FROM app_user WHERE email = ?", Integer.class, account);
        assertThat(actual).isEqualTo(expected);
    }

    private String registerUser(String account, String nickname) throws Exception {
        String deviceId = "points-" + account.replaceAll("[^a-zA-Z0-9]", "-");
        mockMvc.perform(post("/api/c/v1/auth/send-code")
                        .with(request -> {
                            request.setRemoteAddr(testIpFor(account));
                            return request;
                        })
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "scene": "register",
                                  "type": "email",
                                  "account": "%s",
                                  "deviceId": "%s"
                                }
                                """.formatted(account, deviceId)))
                .andExpect(status().isOk());

        MvcResult registerResult = mockMvc.perform(post("/api/c/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "type": "email",
                                  "account": "%s",
                                  "code": "123456",
                                  "password": "Passw0rd!",
                                  "nickname": "%s",
                                  "preferredRegion": "CN"
                                }
                                """.formatted(account, nickname)))
                .andExpect(status().isOk())
                .andReturn();
        return readText(registerResult, "/data/accessToken");
    }

    private String loginAdmin() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "account": "admin",
                                  "password": "admin123456"
                                }
                                """))
                .andExpect(status().isOk())
                .andReturn();
        return readText(result, "/data/accessToken");
    }

    private String createReadOnlyAdminAndLogin() throws Exception {
        jdbcTemplate.update("""
                INSERT INTO admin_role(code, name, description, status, built_in)
                VALUES('points_reader_test', '积分只读测试', '', 1, FALSE)
                """);
        Long roleId = jdbcTemplate.queryForObject(
                "SELECT id FROM admin_role WHERE code='points_reader_test'", Long.class);
        jdbcTemplate.update("""
                INSERT INTO admin_user(account, password_hash, name, status)
                SELECT 'points-reader-test', password_hash, '积分只读测试', 1
                FROM admin_user WHERE id=1
                """);
        Long adminId = jdbcTemplate.queryForObject(
                "SELECT id FROM admin_user WHERE account='points-reader-test'", Long.class);
        jdbcTemplate.update("INSERT INTO admin_user_role(admin_id, role_id) VALUES(?,?)", adminId, roleId);
        jdbcTemplate.update("""
                INSERT INTO admin_role_permission(role_id, permission_id)
                SELECT ?, id FROM admin_permission WHERE code='operations:points:read'
                """, roleId);
        jdbcTemplate.update("INSERT INTO admin_region_scope(admin_id, region) VALUES(?, 'EU')", adminId);
        return login("points-reader-test");
    }

    private String login(String account) throws Exception {
        MvcResult result = mockMvc.perform(post("/api/admin/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"account\":\"" + account + "\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andReturn();
        return readText(result, "/data/accessToken");
    }

    private String testIpFor(String account) {
        int hash = account.hashCode();
        return "10.%d.%d.%d".formatted(
                Math.floorMod(hash, 223) + 1,
                Math.floorMod(hash / 223, 223) + 1,
                Math.floorMod(hash / (223 * 223), 223) + 1
        );
    }

    private String bearer(String accessToken) {
        return "Bearer " + accessToken;
    }

    private String readText(MvcResult result, String pointer) throws Exception {
        return objectMapper.readTree(result.getResponse().getContentAsString()).at(pointer).asText();
    }

    private long readLong(MvcResult result, String pointer) throws Exception {
        return objectMapper.readTree(result.getResponse().getContentAsString()).at(pointer).asLong();
    }
}
