# M3a Elasticsearch Shop Search Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 落地真实 Elasticsearch 商户搜索、索引同步、距离排序和可回退的 MySQL 搜索。

**Architecture:** MySQL 是权威源，搜索业务依赖统一 gateway；ES 通过 REST API 接入，应用双写 + 管理端重建保证索引可恢复。

**Tech Stack:** Spring Boot 3、MyBatis、Spring RestClient、Elasticsearch 8、Vue 3、Vitest、PowerShell smoke

---

### Task 1: 搜索配置与查询契约

**Files:**
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/config/SearchProperties.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/search/model/ShopSearchQuery.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/search/gateway/ShopSearchGateway.java`
- Test: `backend/src/test/java/com/tuowei/dazhongdianping/module/search/service/ShopSearchServiceTest.java`

- [ ] 写失败测试，定义 provider、筛选、排序、分页与 distance 参数校验。
- [ ] 运行测试确认因类型和服务缺失而失败。
- [ ] 写最小配置、查询模型和 gateway 接口。

### Task 2: MySQL fallback 与公开接口

**Files:**
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/search/service/ShopSearchService.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/search/controller/PublicSearchController.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/browse/service/BrowseQueryService.java`
- Test: `backend/src/test/java/com/tuowei/dazhongdianping/module/search/controller/PublicSearchControllerTest.java`

- [ ] 先写 `/api/c/v1/search/shops` 失败测试。
- [ ] 复用 MySQL 查询实现 fallback 并记录搜索历史。
- [ ] 验证区域、筛选、分页和错误响应。

### Task 3: ES gateway 与索引文档

**Files:**
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/search/gateway/ElasticsearchShopSearchGateway.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/search/model/ShopSearchDocument.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/search/mapper/SearchIndexMapper.java`
- Create: `backend/src/main/resources/mapper/SearchIndexMapper.xml`
- Modify: `backend/pom.xml`
- Test: `backend/src/test/java/com/tuowei/dazhongdianping/module/search/gateway/ElasticsearchShopSearchGatewayTest.java`

- [ ] 写失败测试验证查询 DSL、fuzziness、拼音字段、过滤、geo sort 与响应映射。
- [ ] 实现 RestClient gateway、索引 mapping 和拼音生成。
- [ ] 验证 gateway 测试与后端全测。

### Task 4: 坐标、增量同步与重建

**Files:**
- Modify: `backend/src/main/resources/schema.sql`
- Modify: `sql/mysql/01_schema.sql`
- Modify: `backend/src/main/resources/data.sql`
- Modify: `sql/mysql/02_seed_data.sql`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/management/service/AdminManagementService.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/audit/service/AdminAuditService.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/management/controller/AdminManagementController.java`

- [ ] 写失败测试覆盖门店增删改、导入、评分变更后的索引动作。
- [ ] 增加经纬度字段、种子坐标、增量同步和管理员重建接口。
- [ ] 验证 H2/MySQL schema 一致性。

### Task 5: Web 搜索接入

**Files:**
- Modify: `web/src/services/browse.ts`
- Modify: `web/src/types/browse.ts`
- Modify: `web/src/views/ShopListView.vue`
- Test: `web/src/services/browse.test.ts`
- Test: `web/src/views/ShopListView.test.ts`

- [ ] 写失败测试验证关键词请求改走 `/search/shops`，距离字段正确展示。
- [ ] 接入新接口并保留无关键词普通列表。
- [ ] 验证 Web 全测与构建。

### Task 6: Elasticsearch smoke 与文档

**Files:**
- Create: `scripts/ci/elasticsearch-smoke.ps1`
- Create: `scripts/ci/test-elasticsearch-smoke.ps1`
- Modify: `scripts/ci/verify-all.ps1`
- Modify: `.github/workflows/ci.yml`
- Modify: `.github/workflows/nightly.yml`
- Modify: `README.md`
- Modify: `docs/接口设计.md`
- Modify: `docs/数据库设计.md`
- Modify: `docs/当前已完成功能与SQL导入说明.md`

- [ ] 先写脚本契约失败测试。
- [ ] 用真实 ES 完成建索引、重建、关键词、纠错、筛选和距离搜索 smoke。
- [ ] 运行 `verify-all.ps1`、ES smoke、浏览器 smoke 和真实 E2E。
