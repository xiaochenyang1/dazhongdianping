# M3a Elasticsearch 商户搜索设计

## 目标

把当前 MySQL 模糊匹配升级为真实 Elasticsearch 商户搜索，补齐 `/search/shops`、多字段匹配、拼音字段、模糊纠错、筛选排序和距离计算，同时保持 MySQL 为权威源。

## 架构

- `ShopSearchGateway` 定义搜索、联想、索引写入、删除和全量重建接口。
- `MysqlShopSearchGateway` 保留当前 fallback，供本地无 ES 环境与故障降级使用。
- `ElasticsearchShopSearchGateway` 使用 Spring `RestClient` 调用 ES REST API，不把 ES SDK 类型渗入业务层。
- `SearchIndexMapper` 从 MySQL 读取完整索引文档；应用层双写负责门店 CRUD、导入和点评审核后的增量同步。
- 管理端增加重建索引接口，解决首次初始化和增量同步失败后的恢复。

## 查询能力

- 关键词匹配 `name/categoryName/address/tags/dishNames/namePinyin`。
- 中文正文使用标准分词兼容配置，拼音由应用层生成，模糊纠错使用 `fuzziness=AUTO`。
- 过滤 `region/cityId/areaId/categoryId/minPrice/maxPrice/minScore/hasDeal/openNow`。
- 排序支持 `smart/score/popular/distance`；距离排序要求 `lat/lng`，无坐标时返回参数错误。
- 响应沿用商户列表结构并增加可空 `distanceMeters`，降低前端迁移成本。

## 数据模型

`shop` 增加 `latitude/longitude`，种子数据补坐标。索引文档包含评分、点评数、价格、区域、分类、城市、商圈、标签、团购标记、营业状态与 `geo_point`。

## 故障策略

- 默认 provider 仍为 `mysql`，显式配置 `APP_SEARCH_PROVIDER=elasticsearch` 才启用 ES。
- ES 查询失败时是否自动降级由配置控制；默认开启并记录告警，避免搜索页面直接瘫痪。
- 增量写失败不回滚 MySQL 主事务；记录失败并允许管理员重建索引。

## 测试

- 单元测试验证 ES DSL、响应映射、拼音生成、降级行为和索引写入。
- Controller 测试验证 `/search/shops` 参数、区域隔离与 MySQL fallback。
- 脚本 smoke 使用真实 Elasticsearch 容器完成建索引、重建、搜索和距离排序。

## 自审

无占位项。同步边界、降级口径、坐标字段和验收命令均已明确；Canal 作为未来替换实现，不阻塞当前真实 ES 能力。
