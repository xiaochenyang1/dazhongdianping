# M6 Flutter EU App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立默认 EU、可运行可测试的 Flutter APP，并复用现有后端核心业务。

**Architecture:** 核心基础设施与业务 feature 分层，HTTP 统一注入区域、语言与 token；第三方能力通过环境配置启用。

**Tech Stack:** Flutter、Dart、Material 3、package:http、flutter_secure_storage、intl。

---

### Task 1: Flutter 工程与核心配置

- [x] 创建 `app/` Flutter 工程。
- [x] 编写区域、语言、环境配置与 API envelope 测试并确认失败。
- [x] 实现核心配置、HTTP client；会话安全存储待认证任务继续补齐。
- [x] 运行 `flutter analyze`、`flutter test`。

### Task 2: 浏览与搜索

- [x] 实现首页、门店列表、门店详情、搜索页面与 service。
- [x] 所有请求默认 `X-Region=EU`，支持切换 CN/EU。
- [x] 增加加载、空状态和错误恢复。

### Task 3: 认证与用户中心

- [x] 实现邮箱/手机号密码登录和验证码登录入口。
- [x] 实现资料、点评、收藏、订单、券、预订、隐私中心入口。
- [x] 安全存储 token 并支持退出。

### Task 4: 区域化能力边界

- [x] 加入中简/中繁/英文本地化资源。
- [x] 加入货币格式化与时区展示。
- [x] 加入地图、支付、推送的环境配置和未配置保护。

### Task 5: 回归与文档

- [x] `flutter analyze` 通过。
- [x] `flutter test` 通过。
- [x] 更新 README、需求状态和 CI 验证入口。

> 本计划定义的 Flutter MVP 基线已完成。M6 总体仍未完成：点评发布/编辑与图片上传、业务化订单/券/预订详情操作、真实 Google Maps、Stripe/PayPal、FCM/APNs、协议留痕与设备管理仍需继续实施或等待外部凭证验收。
