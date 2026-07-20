# M7 Direct Messaging Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成 APP 端 1v1 文本私信、举报、拉黑、实时通知与隐私治理。

**Architecture:** 新增独立 `message` 模块维护全局会话和消息；使用数据库用户对唯一键保证会话幂等，复用现有 WebSocket 注册表做事务提交后实时事件，REST 负责离线补拉。

**Tech Stack:** Java 17、Spring Boot、MyBatis、H2/MySQL、Flutter、Dart、JUnit 5。

---

### Task 1: 会话、消息、拉黑与举报后端闭环

- [x] 写失败的 MockMvc 集成测试，覆盖发送、会话列表、消息分页、已读、自发消息、目标不存在、拉黑和举报。
- [x] 运行定向测试确认因 API/表不存在而失败。
- [x] 添加 H2/MySQL 表、message 模块 Controller/Service/Mapper/模型与鉴权路径。
- [x] 重跑定向测试直到通过。

### Task 2: WebSocket 与隐私治理

- [x] 写失败测试，覆盖事务提交后 `message.new`、`messages` 导出和注销治理。
- [x] 实现全区域实时事件、隐私导出与注销匿名化。
- [x] 重跑通知/隐私测试直到通过。

### Task 3: Flutter 私信 UI

- [x] 写失败仓储和 Widget 测试，覆盖会话列表、聊天、发送、已读、举报、拉黑和公开主页入口。
- [x] 实现仓储、会话列表、聊天页和路由集成。
- [x] 运行定向 Flutter 测试与 analyze。

### Task 4: 文档与全量验证

- [x] 更新 README、需求、接口、数据库和完成状态文档。
- [x] 运行 `.\\scripts\\ci\\verify-all.ps1 -IncludeFlutter`。
- [x] 修复全部回归，逐项审计本设计验收范围。
