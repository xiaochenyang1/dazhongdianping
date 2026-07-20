# 分类、城市、商圈基础数据治理 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为分类、城市和商圈提供受 RBAC 与区域范围保护的完整管理闭环，并保证停用、删除和既有业务引用不会破坏 C 端与门店写入链路。

**Architecture:** 在现有 `category/city/area` 基础表上直接增加可生成 ID、状态、唯一约束和排序索引；新增独立 `module/admin/geodata` 负责管理端写入与引用保护。公共浏览只读取启用数据，既有门店继续保留历史名称；所有会新建或落地基础数据引用的既有链路在写入前重新校验启用状态。

**Tech Stack:** Java 17、Spring Boot MVC、MyBatis、H2/MySQL、Vue 3、TypeScript、Vue Router、Vitest/jsdom、Playwright、PowerShell。

---

> 当前目录没有可用 Git 元数据，不能创建 worktree 或提交。每个任务以 RED/GREEN 测试与计划勾选作为检查点；不要运行 `git reset`、`git checkout` 或其他会覆盖用户工作区的命令。

## 文件结构

| 路径 | 职责 |
|---|---|
| `backend/src/main/resources/schema.sql` | H2 初始化中的基础数据字段、约束和索引。 |
| `sql/mysql/01_schema.sql` | MySQL 初始化中的同构基础数据表定义。 |
| `backend/src/main/resources/data.sql`、`sql/mysql/02_seed_data.sql` | 新 `data:geo:*` 权限和 `data_operator` 授权。 |
| `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/geodata/**` | 管理端分类、城市、商圈 CRUD、状态和引用保护。 |
| `backend/src/main/resources/mapper/AdminGeoDataMapper.xml` | 管理端基础数据 SQL。 |
| `backend/src/main/java/com/tuowei/dazhongdianping/module/browse/**` | C 端只读取启用的基础数据和停用筛选保护。 |
| `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/management/**` | 管理端门店、导入引用启用校验。 |
| `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/shop/**` | 商户门店变更保存和审核落库的启用校验。 |
| `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/audit/service/AdminAuditService.java` | 审核通过门店变更前的再次校验。 |
| `backend/src/main/java/com/tuowei/dazhongdianping/module/rank/**` | 榜单草稿和发布前的启用校验。 |
| `admin-web/src/services/geodata.ts` | 管理端基础数据 HTTP 契约。 |
| `admin-web/src/views/BasicDataManagementView.vue` | 三页签基础数据治理页面。 |
| `admin-web/src/router/index.ts`、`AdminMenuService.java` | 动态菜单和前端路由权限接入。 |
| `web/e2e/browser-smoke.spec.ts`、`web/e2e/real-backend-flow.spec.ts` | 模拟前端与真实后端浏览器验收。 |

## 固定契约

- 权限名和路由严格使用已获批准的 `data:geo:read`、`data:geo:write` 与 `/data/meta`；不要擅自替换为 `data:base_data:*` 或 `/data/base-data`。
- 管理 API 使用 `/api/admin/v1/categories`、`/cities`、`/areas`，不接受 body 中的 `region`，区域由 `X-Region` 与现有管理员范围决定。
- 状态统一为 `1=启用`、`0=停用`；删除为受保护的物理删除，任何引用存在时返回 `409 Conflict`。
- 分类根节点 `parentId=0`；城市编码 trim 后大写；所有名称 trim；排序一律为 `sortNo ASC, id ASC`。
- 已有门店不会因基础数据停用被自动下线。C 端元数据和带停用基础数据 ID 的门店筛选不暴露停用项；未带该筛选条件的历史门店详情仍可显示原名称。

### Task 1: 用双 schema 和种子测试固定基础数据契约

**Files:**
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/geodata/AdminGeoDataSeedTest.java`
- Modify: `backend/src/main/resources/schema.sql`
- Modify: `sql/mysql/01_schema.sql`
- Modify: `backend/src/main/resources/data.sql`
- Modify: `sql/mysql/02_seed_data.sql`

- [ ] **Step 1: 先写失败的 H2 schema/种子测试**

在 `AdminGeoDataSeedTest` 使用 `@SpringBootTest`、`@Transactional` 和 `JdbcTemplate`，约束 ID 可生成、默认状态、唯一规则及权限种子。测试最小骨架：

```java
@Test
void shouldSeedActiveGeoDataAndGeoPermissions() {
    assertEquals(1, jdbc.queryForObject(
            "SELECT status FROM category WHERE id=100", Integer.class));
    jdbc.update("INSERT INTO city(code, region, name, sort_no, status) VALUES(?,?,?,?,?)",
            "PLAN", "EU", "Plan City", 99, 1);
    Long cityId = jdbc.queryForObject(
            "SELECT id FROM city WHERE region='EU' AND code='PLAN'", Long.class);
    assertNotNull(cityId);
    assertEquals(1, jdbc.queryForObject(
            "SELECT COUNT(1) FROM admin_permission WHERE code='data:geo:read' AND status=1", Integer.class));
    assertEquals(1, jdbc.queryForObject(
            "SELECT COUNT(1) FROM admin_role_permission arp JOIN admin_role ar ON ar.id=arp.role_id "
                    + "JOIN admin_permission ap ON ap.id=arp.permission_id "
                    + "WHERE ar.code='data_operator' AND ap.code='data:geo:write'", Integer.class));
}
```

- [ ] **Step 2: 运行测试确认 RED**

```powershell
Set-Location backend
.\mvnw.cmd -q -Dtest=AdminGeoDataSeedTest test
```

预期：失败，当前表缺少 `status` 且 `city.id` 不是自动生成；新权限尚不存在。

- [ ] **Step 3: 同步实现 H2/MySQL 表变更与权限种子**

在两份 schema 中将三张表改为可生成 ID，并添加状态、唯一约束和读列表索引：

```sql
-- H2 语义，MySQL 使用 BIGINT NOT NULL AUTO_INCREMENT 并把 UNIQUE/KEY 写入表定义
CREATE TABLE IF NOT EXISTS category (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    parent_id BIGINT NOT NULL,
    region VARCHAR(8) NOT NULL,
    name VARCHAR(64) NOT NULL,
    sort_no INT NOT NULL DEFAULT 0,
    status TINYINT NOT NULL DEFAULT 1
);
CREATE UNIQUE INDEX IF NOT EXISTS uk_category_region_parent_name
    ON category(region, parent_id, name);
CREATE INDEX IF NOT EXISTS idx_category_region_status_parent_sort
    ON category(region, status, parent_id, sort_no, id);
```

同样为 `city` 添加 `status`、`uk_city_region_code`、`uk_city_region_name`、`idx_city_region_status_sort`；为 `area` 添加 `status`、`uk_area_region_city_name`、`idx_area_region_city_status_sort`。保留种子中显式 ID 和 `parent_id=0` 根语义，不添加自引用外键或跨业务表外键。

在两个种子文件追加：

```sql
(32, 'data:geo:read', '查看基础数据', 'data', 1, 1),
(33, 'data:geo:write', '维护基础数据', 'data', 2, 1)
```

并在 `admin_role_permission` 中给 `data_operator` 增加 `(5, 32), (5, 33)`；`super_admin` 的 `SELECT 1, id FROM admin_permission` 保持自动获得新权限。更新 `data_operator` 描述为包含基础数据维护。

- [ ] **Step 4: 运行种子测试确认 GREEN**

```powershell
Set-Location backend
.\mvnw.cmd -q -Dtest=AdminGeoDataSeedTest test
```

预期：PASS；现有显式种子 ID、自动新增 ID、默认状态和两项权限均可查到。

### Task 2: 建立管理端基础数据 CRUD、状态和引用保护

**Files:**
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/geodata/AdminGeoDataController.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/geodata/AdminGeoDataService.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/geodata/mapper/AdminGeoDataMapper.java`
- Create: `backend/src/main/resources/mapper/AdminGeoDataMapper.xml`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/geodata/model/AdminCategoryRow.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/geodata/model/AdminCityRow.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/geodata/model/AdminAreaRow.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/geodata/model/request/CategorySaveRequest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/geodata/model/request/CitySaveRequest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/geodata/model/request/AreaSaveRequest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/geodata/model/request/GeoStatusRequest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/geodata/model/response/AdminCategoryResponse.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/geodata/model/response/AdminCityResponse.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/geodata/model/response/AdminAreaResponse.java`
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/geodata/AdminGeoDataControllerTest.java`

- [ ] **Step 1: 编写管理端 CRUD 的失败集成测试**

使用 `AdminCircleControllerTest` 的 `MockMvc + loginToken + X-Region` 形状。测试必须覆盖以下独立断言，不只断言 `200`：

```java
mockMvc.perform(post("/api/admin/v1/categories")
        .header("Authorization", bearer(token)).header("X-Region", "EU")
        .contentType(MediaType.APPLICATION_JSON)
        .content("{\"parentId\":200,\"name\":\"Plan Noodles\",\"sortNo\":7}"))
    .andExpect(status().isOk())
    .andExpect(jsonPath("$.data.parentId").value(200))
    .andExpect(jsonPath("$.data.status").value(1));

mockMvc.perform(delete("/api/admin/v1/categories/{id}", 200L)
        .header("Authorization", bearer(token)).header("X-Region", "EU"))
    .andExpect(status().isConflict());
```

同一测试类增加：无 token `401`；只含 `data:geo:read` 的临时管理员可 GET、POST 返回 `403`；CN/EU 跨区 ID 返回 `404`；分类同父重名 `409`、自指/后代父级 `409`；城市 `code/name` 重复 `409`；商圈跨区城市或停用城市 `409`；状态、排序和管理列表的持久化复查；分类有子项、城市有商圈、三类有 `shop`/`merchant_shop_change`/榜单/运营位引用时删除 `409`；无引用记录删除成功。

为引用保护在测试内使用 `JdbcTemplate` 插入最小 `merchant_shop_change`、`rank_config`、`rank`、`home_banner`、`home_feed` 行，验证每种引用源都能阻断对应资源删除。

- [ ] **Step 2: 运行新测试确认 RED**

```powershell
Set-Location backend
.\mvnw.cmd -q -Dtest=AdminGeoDataControllerTest test
```

预期：FAIL，路由和 `geodata` 模块尚不存在。

- [ ] **Step 3: 定义请求、响应、Controller 和权限边界**

请求对象使用 Bean Validation，保持字段职责独立：

```java
public record CategorySaveRequest(
        @NotNull @PositiveOrZero Long parentId,
        @NotBlank @Size(max = 64) String name,
        @NotNull @Min(0) @Max(999999) Integer sortNo) {}

public record CitySaveRequest(
        @NotBlank @Size(max = 32) String code,
        @NotBlank @Size(max = 64) String name,
        @NotNull @Min(0) @Max(999999) Integer sortNo) {}

public record GeoStatusRequest(@NotNull @Min(0) @Max(1) Integer status) {}
```

`AdminGeoDataController` 保持一个 `/api/admin/v1` 根路径；每个方法显式标注现有 `@AdminPermission`：

```java
@GetMapping("/categories")
@AdminPermission("data:geo:read")
public ApiResponse<List<AdminCategoryResponse>> categories() {
    return ApiResponse.success(service.listCategories());
}

@PostMapping("/categories")
@AdminPermission("data:geo:write")
public ApiResponse<AdminCategoryResponse> createCategory(@Valid @RequestBody CategorySaveRequest request) {
    return ApiResponse.success(service.createCategory(request));
}

@PutMapping("/categories/{id}/status")
@AdminPermission("data:geo:write")
public ApiResponse<AdminCategoryResponse> updateCategoryStatus(
        @PathVariable Long id, @Valid @RequestBody GeoStatusRequest request) {
    return ApiResponse.success(service.updateCategoryStatus(id, request.status()));
}
```

为 `cities` 和 `areas` 提供同构的 GET/POST/PUT/DELETE/status 路由；`GET /areas?cityId={cityId}` 允许管理员查看停用城市的商圈，但所有写入要求城市启用。不要为这些端点添加认证白名单，`AdminPermissionCoverageTest` 应自动覆盖它们。

- [ ] **Step 4: 实现 mapper 和事务服务的最小规则**

`AdminGeoDataMapper` 必须提供当前区域列表、按 ID 查询、冲突计数、插入、更新、状态更新、删除和逐项引用计数。关键 SQL 形状：

```xml
<select id="countCategoryNameConflict" resultType="int">
  SELECT COUNT(1) FROM category
  WHERE region = #{region} AND parent_id = #{parentId} AND name = #{name}
    AND (#{excludeId} IS NULL OR id != #{excludeId})
</select>

<select id="countAreaReferences" resultType="int">
  SELECT (SELECT COUNT(1) FROM shop WHERE area_id = #{areaId} AND region = #{region})
       + (SELECT COUNT(1) FROM merchant_shop_change WHERE area_id = #{areaId} AND region = #{region})
</select>
```

`AdminGeoDataService` 从 `RegionContext.getRegion().name()` 获取区域，并在 `@Transactional` 中按下列顺序执行：trim/标准化、`require*` 当前区域记录、唯一性/父子校验、写入、再次读取并转 response。错误使用现有 `NotFoundException` 和 `ConflictException`，不要用 `IllegalArgumentException` 代替删除/重复/状态冲突。

分类启停和删除规则必须显式实现：

```java
private void assertCategoryCanDisable(Long categoryId, String region) {
    if (mapper.countEnabledCategoryChildren(categoryId, region) > 0) {
        throw new ConflictException("分类仍有启用子分类，不能停用");
    }
}

private void assertCategoryCanDelete(Long categoryId, String region) {
    if (mapper.countAnyCategoryChildren(categoryId, region) > 0
            || mapper.countCategoryBusinessReferences(categoryId, region) > 0) {
        throw new ConflictException("分类仍被子分类或业务数据引用，不能删除");
    }
}
```

城市删除先检查任意商圈再检查 `shop`、`merchant_shop_change`、`home_banner`、`home_feed`、`rank_config`、`rank`；商圈删除检查 `shop` 和 `merchant_shop_change`；分类删除检查子分类、`shop`、`merchant_shop_change`、`rank_config`、`rank`。不级联删除或重写历史引用。

- [ ] **Step 5: 运行 CRUD、RBAC 和引用保护测试确认 GREEN**

```powershell
Set-Location backend
.\mvnw.cmd -q -Dtest=AdminGeoDataSeedTest,AdminGeoDataControllerTest,AdminPermissionCoverageTest test
```

预期：PASS；任一漏注解管理接口会由 `AdminPermissionCoverageTest` 直接失败。

### Task 3: 接入菜单、RBAC 种子与前端路由守卫

**Files:**
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/auth/service/AdminMenuService.java`
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/geodata/AdminGeoDataControllerTest.java`
- Modify: `admin-web/src/router/index.ts`
- Modify: `admin-web/src/router/index.test.ts`

- [ ] **Step 1: 先补菜单和无权限路由的失败断言**

在后端测试断言 `data:geo:read` 授予后的 `/menus` 数据管理组包含：

```java
.andExpect(jsonPath("$.data[2].children[2].path").value("/data/meta"));
```

索引会随项目菜单顺序变化，若实际数据管理组不在 `$.data[2]`，先按 `code == 'data'` 定位再断言路径，禁止为了测试稳定性改菜单顺序。

在 `router/index.test.ts` 设置一个仅有 `audit:review:read` 的会话，断言 `/data/meta` 回到 `/dashboard`；再把 `data:geo:read` 加入权限集，断言可以直达。

- [ ] **Step 2: 运行测试确认 RED**

```powershell
Set-Location admin-web
npm test -- src/router/index.test.ts
```

预期：FAIL，路由尚不存在；后端菜单断言同样应失败。

- [ ] **Step 3: 实现菜单和路由**

在 `AdminMenuService` 的 `data` 分组加入，不改动其他菜单：

```java
leaf("data.meta", "基础数据", "/data/meta", "data:geo:read"),
```

在路由子项中新增：

```ts
{
  path: 'data/meta',
  name: 'basic-data-management',
  component: () => import('@/views/BasicDataManagementView.vue'),
  meta: {
    requiresAuth: true,
    title: '基础数据',
    requiredPermission: 'data:geo:read',
  },
},
```

不修改 `AdminLayout.vue` 的菜单加载时序，也不让前端菜单取代后端 `@AdminPermission`。

- [ ] **Step 4: 运行菜单与路由测试确认 GREEN**

```powershell
Set-Location backend
.\mvnw.cmd -q -Dtest=AdminGeoDataControllerTest,AdminPermissionCoverageTest test
Set-Location ..\admin-web
npm test -- src/router/index.test.ts
```

预期：PASS；无读权限不能通过直接 URL 绕过，拥有读权限时动态菜单和路由一致。

### Task 4: 让 C 端只读取启用基础数据并保护停用筛选绕过

**Files:**
- Modify: `backend/src/main/resources/mapper/BrowseQueryMapper.xml`
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/browse/controller/PublicBrowseControllerTest.java`

- [ ] **Step 1: 为公开元数据与停用筛选写失败测试**

在 `PublicBrowseControllerTest` 使用 `JdbcTemplate` 将 EU 分类、城市、商圈分别更新为 `status=0`，断言：

```java
mockMvc.perform(get("/api/c/v1/categories").header("X-Region", "EU"))
    .andExpect(status().isOk())
    .andExpect(jsonPath("$.data[?(@.id == 202)]").doesNotExist());

mockMvc.perform(get("/api/c/v1/cities/{cityId}/areas", 101L).header("X-Region", "EU"))
    .andExpect(status().isOk())
    .andExpect(jsonPath("$.data").isEmpty());

mockMvc.perform(get("/api/c/v1/shops").header("X-Region", "EU").param("categoryId", "202"))
    .andExpect(status().isOk())
    .andExpect(jsonPath("$.data.total").value(0));
```

另加分类搜索联想和热门搜索不包含停用分类；不带 `categoryId/cityId/areaId` 的历史门店详情仍显示已有名称。

- [ ] **Step 2: 运行公开测试确认 RED**

```powershell
Set-Location backend
.\mvnw.cmd -q -Dtest=PublicBrowseControllerTest test
```

预期：FAIL，当前公开查询未过滤 `status`。

- [ ] **Step 3: 在 BrowseQueryMapper 中加入最小状态过滤**

三个元数据查询的条件必须至少包含：

```xml
WHERE region = #{region} AND status = 1
```

商圈查询需连接城市，防止通过已停用城市 ID 直接读取启用商圈：

```xml
FROM area a
JOIN city c ON c.id = a.city_id AND c.region = a.region AND c.status = 1
WHERE a.region = #{region} AND a.city_id = #{cityId} AND a.status = 1
ORDER BY a.sort_no ASC, a.id ASC
```

`selectCategorySuggestions` 与 `selectCategoryNamesByRegion` 同样加入 `c.status = 1`。在 `shopQueryWhere` 的每个非空元数据筛选分支用 `EXISTS` 限定当前筛选 ID 仍启用，而不要给无筛选的门店主查询加全局 metadata join：

```xml
<if test="categoryId != null">
  AND s.category_id = #{categoryId}
  AND EXISTS (SELECT 1 FROM category c
              WHERE c.id = s.category_id AND c.region = s.region AND c.status = 1)
</if>
```

对城市和商圈使用同构 `EXISTS`，商圈额外要求其城市启用。保留详情查询已有 `LEFT JOIN`，确保历史门店仍显示名称。

- [ ] **Step 4: 运行公开测试确认 GREEN**

```powershell
Set-Location backend
.\mvnw.cmd -q -Dtest=PublicBrowseControllerTest test
```

预期：PASS；停用项从公开元数据、搜索相关分类数据和定向筛选中消失，历史门店不被自动下线。

### Task 5: 阻止管理端门店、导入、商户草稿及审核写入停用引用

**Files:**
- Modify: `backend/src/main/resources/mapper/AdminManagementMapper.xml`
- Modify: `backend/src/main/resources/mapper/MerchantShopChangeMapper.xml`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/shop/service/MerchantShopChangeService.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/audit/service/AdminAuditService.java`
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/management/controller/AdminManagementControllerTest.java`
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/merchant/controller/MerchantShopChangeControllerTest.java`
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/audit/AdminShopChangeAuditControllerTest.java`

- [ ] **Step 1: 写入三个失败回归测试组**

1. 在 `AdminManagementControllerTest` 先把一条种子分类/城市/商圈设为 `status=0`，分别断言门店创建、更新和导入记录失败，且导入失败明细保留“不可用”的明确原因。
2. 在 `MerchantShopChangeControllerTest` 断言商户保存草稿时不能选择停用项，城市与商圈不匹配仍返回现有归属错误。
3. 在 `AdminShopChangeAuditControllerTest` 创建有效门店变更草稿，随后用 JDBC 停用它的分类、城市或商圈；审核通过返回业务错误，审核事务回滚，`shop` 不新增/不更新，审核任务也不能被错误标记为已通过。

至少包含下面的管理员门店断言：

```java
jdbcTemplate.update("UPDATE category SET status=0 WHERE id=202");
createShop(token, "EU", 202L, 101L, 1011L)
    .andExpect(status().isBadRequest())
    .andExpect(jsonPath("$.message").value("分类不存在、不启用或不属于当前区域"));
```

- [ ] **Step 2: 运行相关测试确认 RED**

```powershell
Set-Location backend
.\mvnw.cmd -q -Dtest=AdminManagementControllerTest,MerchantShopChangeControllerTest,AdminShopChangeAuditControllerTest test
```

预期：FAIL，现有计数查询只检查存在性。

- [ ] **Step 3: 将现有引用计数改为“启用且归属正确”**

在 `AdminManagementMapper.xml` 的 `countCategoryByRegion`、`countCityByRegion`、`countAreaByRegionAndCity` 加入 `status = 1`；城市/商圈计数仍按同一 `region` 和 `city_id` 约束。服务签名保持不变，只把异常文本更新为准确的“不存在、不启用或不属于当前区域/城市”。

在 `MerchantShopChangeMapper.xml` 的三个 `count*` 查询加同样的 `status = 1` 条件。把 `MerchantShopChangeService` 中目前只接受 request 的私有校验抽为可复用的值校验：

```java
public void requireActiveReferences(Long categoryId, Long cityId, Long areaId) {
    if (mapper.countCategory(region(), categoryId) != 1) {
        throw new IllegalArgumentException("分类不存在、不启用或不属于当前区域");
    }
    if (mapper.countCity(region(), cityId) != 1) {
        throw new IllegalArgumentException("城市不存在、不启用或不属于当前区域");
    }
    if (mapper.countArea(region(), cityId, areaId) != 1) {
        throw new IllegalArgumentException("商圈不存在、不启用或不属于当前城市");
    }
}
```

草稿 `save` 调用它；`AdminAuditService.passShopChangeTask` 在 `updateAuditTaskDecision(...)` 前调用它，传入 `ShopChangeRow` 的三个 ID。这样校验失败会使外层审核事务回滚，不能先把任务写成通过再发现数据失效。

- [ ] **Step 4: 运行写入链路测试确认 GREEN**

```powershell
Set-Location backend
.\mvnw.cmd -q -Dtest=AdminManagementControllerTest,MerchantShopChangeControllerTest,AdminShopChangeAuditControllerTest test
```

预期：PASS；四种写入时点均不能产生新的停用基础数据引用。

### Task 6: 在榜单草稿和发布窗口重新校验分类、城市启用状态

**Files:**
- Modify: `backend/src/main/resources/mapper/RankMapper.xml`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/rank/service/AdminRankService.java`
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/rank/controller/AdminRankControllerTest.java`

- [ ] **Step 1: 写榜单停用和发布竞争的失败测试**

补三个用例：

```java
disableCategory(202L);
createDraft(token, "EU", 101L, 202L).andExpect(status().isBadRequest());

long draftId = createDraft(token, "EU", 101L, 201L);
disableCity(101L);
mockMvc.perform(post("/api/admin/v1/ranks/config/{id}/publish", draftId)
        .header("Authorization", bearer(token)).header("X-Region", "EU"))
    .andExpect(status().isBadRequest());
assertThat(count("SELECT COUNT(1) FROM rank WHERE config_id=?", draftId)).isZero();
```

再断言发布失败不会归档其他已发布配置或禁用旧快照。

- [ ] **Step 2: 运行榜单测试确认 RED**

```powershell
Set-Location backend
.\mvnw.cmd -q -Dtest=AdminRankControllerTest test
```

预期：FAIL，当前 `selectCityName/selectCategoryName` 不过滤状态，`publish` 没有调用 `requireScope`。

- [ ] **Step 3: 最小化改动榜单校验**

在 `RankMapper.xml` 中让 `selectCityName` 和 `selectCategoryName` 都包含 `status = 1`；在 `AdminRankService.publish` 的权重校验之后、读取候选与修改任何榜单状态之前重验：

```java
RankConfigRow config = requireConfig(configId);
Map<String, BigDecimal> weight = readWeight(config.getWeightJson());
validateWeight(weight);
requireScope(Region.valueOf(config.getRegion()), config.getCityId(), config.getCategoryId());
List<RankCandidateRow> candidates = rankMapper.selectRankCandidates(config);
```

`createDraft`、`updateDraft` 已调用 `requireScope`，因此不新增并行校验分支；`rollback` 经由 `createDraft` 和 `publish` 自动覆盖。

- [ ] **Step 4: 运行榜单测试确认 GREEN**

```powershell
Set-Location backend
.\mvnw.cmd -q -Dtest=AdminRankControllerTest test
```

预期：PASS；停用前后都不能绕过创建、编辑、回滚或发布窗口。

### Task 7: 增加管理端基础数据 TypeScript HTTP 契约与类型

**Files:**
- Create: `admin-web/src/services/geodata.ts`
- Create: `admin-web/src/services/geodata.test.ts`
- Modify: `admin-web/src/types/admin.ts`

- [ ] **Step 1: 先写失败的 service 契约测试**

mock `apiGet/apiPost/apiPut/apiDelete`，精确断言路径和 payload：

```ts
await createGeoCategory({ parentId: 0, name: '美食', sortNo: 1 })
expect(apiPost).toHaveBeenCalledWith('/api/admin/v1/categories', {
  parentId: 0, name: '美食', sortNo: 1,
})

await listGeoAreas(101)
expect(apiGet).toHaveBeenCalledWith('/api/admin/v1/areas', { cityId: 101 })

await removeGeoArea(1011)
expect(apiDelete).toHaveBeenCalledWith('/api/admin/v1/areas/1011')
```

- [ ] **Step 2: 运行 service 测试确认 RED**

```powershell
Set-Location admin-web
npm test -- src/services/geodata.test.ts
```

预期：FAIL，`geodata.ts` 尚不存在。

- [ ] **Step 3: 定义独立管理端类型和请求函数**

在 `types/admin.ts` 新增，不能复用当前只服务公开下拉的 `CategoryNode/City/Area`：

```ts
export interface AdminGeoCategory { id: number; parentId: number; name: string; sortNo: number; status: number }
export interface AdminGeoCity { id: number; code: string; name: string; sortNo: number; status: number }
export interface AdminGeoArea { id: number; cityId: number; name: string; sortNo: number; status: number }
export interface GeoCategoryPayload { parentId: number; name: string; sortNo: number }
export interface GeoCityPayload { code: string; name: string; sortNo: number }
export interface GeoAreaPayload { cityId: number; name: string; sortNo: number }
```

`geodata.ts` 仅调用管理 API：

```ts
export const listGeoCategories = () => apiGet<AdminGeoCategory[]>('/api/admin/v1/categories')
export const updateGeoCategoryStatus = (id: number, status: number) =>
  apiPut<AdminGeoCategory>(`/api/admin/v1/categories/${id}/status`, { status })
export const removeGeoCategory = (id: number) => apiDelete<void>(`/api/admin/v1/categories/${id}`)
```

为 city/area 提供同构函数。不要修改 `services/meta.ts`，它只读取 C 端 `/api/c/v1` 元数据。

- [ ] **Step 4: 运行 service 测试确认 GREEN**

```powershell
Set-Location admin-web
npm test -- src/services/geodata.test.ts
```

预期：PASS；每个操作都指向管理端路径且城市筛选以 query 参数传递。

### Task 8: 构建具备读写门控的基础数据管理页面

**Files:**
- Create: `admin-web/src/views/BasicDataManagementView.vue`
- Create: `admin-web/src/views/BasicDataManagementView.test.ts`
- Modify: `admin-web/src/style.css`

- [ ] **Step 1: 先写失败的组件测试**

沿用 `createApp + nextTick + vi.mock`，mock `geodata.ts` 与 `useAdminSession`。必须覆盖：

```ts
expect(listGeoCategories).toHaveBeenCalledTimes(1)
expect(listGeoCities).toHaveBeenCalledTimes(1)
expect(host.textContent).toContain('分类')

// 仅读权限不渲染新增、编辑、启停、删除命令
expect(host.querySelector('[data-testid="create-category"]')).toBeNull()

// 切换城市必须清空旧商圈并按新 cityId 加载
citySelect.value = '101'
citySelect.dispatchEvent(new Event('change'))
await flush()
expect(listGeoAreas).toHaveBeenLastCalledWith(101)
```

另加写权限场景：创建/编辑 payload、启停调用、删除 `409` 原样显示且不清空表单或列表、区域变化重新加载并清空旧区域数据。

- [ ] **Step 2: 运行组件测试确认 RED**

```powershell
Set-Location admin-web
npm test -- src/views/BasicDataManagementView.test.ts
```

预期：FAIL，视图尚不存在。

- [ ] **Step 3: 实现紧凑、可用的三页签工作区**

页面使用固定高度页签（分类、城市、商圈），而不是嵌套卡片；分类展示按 `parentId` 组织的紧凑树表，城市展示 `code/name/sort/status`，商圈在已选城市下展示列表。按钮使用现有图标库可用的图标，并用 `title`/tooltip 描述；二元状态使用明确启停按钮，排序用数字输入。

从实时会话权限计算：

```ts
const canWrite = computed(() => session.state.permissions.includes('data:geo:write'))
```

路由允许 `data:geo:read` 查看；所有会改变数据的控件必须同时满足 `canWrite`，包括表单提交、启停和删除。删除调用前使用确认交互；请求失败时显示服务端 `Error.message`，不要吞掉 `409` 原因。所有 reload 在 `finally` 中恢复 loading，避免按钮重复点击或区域切换残留旧列表。

在 `style.css` 添加页面级网格、表格、状态标记和移动端堆叠规则，沿用管理端现有色板和间距；不新增装饰性大卡片、渐变或悬浮说明文本。

- [ ] **Step 4: 运行组件测试和构建确认 GREEN**

```powershell
Set-Location admin-web
npm test -- src/views/BasicDataManagementView.test.ts src/services/geodata.test.ts src/router/index.test.ts
npm run build
```

预期：PASS；构建无 TypeScript 错误，读写权限和城市-商圈联动稳定。

### Task 9: 补浏览器验收、文档与全量验证

**Files:**
- Modify: `web/e2e/browser-smoke.spec.ts`
- Modify: `web/e2e/real-backend-flow.spec.ts`
- Modify: `README.md`
- Modify: `docs/当前已完成功能与SQL导入说明.md`
- Modify: `docs/接口设计.md`
- Modify: `docs/数据库设计.md`
- Modify: `docs/权限矩阵.md`
- Modify: `docs/测试清单与验收用例.md`

- [ ] **Step 1: 先新增失败的浏览器验收场景**

在 `browser-smoke.spec.ts` 为 mock 管理端补 `auth/me`、`menus`、`/categories`、`/cities`、`/areas` 响应，验证登录后进入 `/data/meta`、显示当前区域数据、切换城市更新商圈、只有 read 权限时无写命令。

在 `real-backend-flow.spec.ts` 扩展真后端流程：管理员登录 EU，创建城市/商圈/分类，访问 C 端元数据确认出现；停用后确认 C 端隐藏且带该 ID 的门店筛选为空；尝试删除被门店引用的记录确认 `409`；恢复启用后 C 端重新可见。不要只断言页面文案，至少断言实际响应状态和 JSON 数据。

- [ ] **Step 2: 运行浏览器场景确认 RED**

```powershell
.\scripts\ci\browser-smoke.ps1
.\scripts\ci\browser-e2e.ps1
```

预期：在实现前至少有基础数据路由/API 不存在导致的失败；若本机缺少浏览器或依赖，记录环境原因而非伪报通过。

- [ ] **Step 3: 使浏览器场景通过并同步事实性文档**

只在真实代码和测试通过后更新文档：

- `README.md` 和当前完成说明：将分类/城市/商圈治理从待补项改为已实现，并保留“真实支付、地图、推送、目标环境未验收”的边界。
- `接口设计.md`：补全管理端三类资源的 CRUD/status/delete、`data:geo:*`、区域和 `409` 语义；更新 C 端隐藏规则。
- `数据库设计.md`：同步三张表的状态、唯一约束、自增 ID、引用保护和无外键理由。
- `权限矩阵.md`：把基础数据治理从待补项移到 `data:geo:read/write` 的已实现能力，说明仍无城市/门店细粒度管理员范围。
- `测试清单与验收用例.md`：加入启停、历史门店、删除引用阻断、跨区/RBAC、榜单发布窗口和浏览器回归案例。

不要把未建设的运营位管理、审计日志查询、用户治理、支付、地图、推送或生产环境联调写成已完成。

- [ ] **Step 4: 运行最终验证并记录结果**

```powershell
Set-Location backend
.\mvnw.cmd -q test

Set-Location ..\admin-web
npm test
npm run build

Set-Location ..
.\scripts\ci\browser-smoke.ps1
.\scripts\ci\browser-e2e.ps1
.\scripts\ci\test-verify-all.ps1
```

预期：后端全量测试、管理端单测/构建、浏览器 smoke/E2E 和聚合验证全部通过。若 MySQL smoke 已覆盖 `sql/mysql/01_schema.sql` 与 `02_seed_data.sql`，同时运行：

```powershell
.\scripts\ci\mysql-smoke.ps1
```

仅在命令实际通过后记录测试数量和通过结果；不能沿用旧轮次数字。
