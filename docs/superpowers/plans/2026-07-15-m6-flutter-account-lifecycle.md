# M6 Flutter Account Lifecycle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 Flutter 补齐注册、找回密码、资料编辑、账号绑定和密码更新的真实账户生命周期。

**Architecture:** 游客流程保留在 `features/auth`，登录后账户维护放在独立 `features/user/account_settings_screen.dart`；Repository 负责 API，Controller 负责会话与全局用户摘要。`PUT` 通过独立 `JsonMutationApi` 扩展，避免破坏现有只实现 `JsonApi` 的测试替身。

**Tech Stack:** Flutter、Dart、Material 3、package:http、flutter_secure_storage、flutter_test。

> 当前工作区 `.git` 为空，无法创建 worktree 或提交；计划中的每个验证点仍严格执行，但不伪造 commit 步骤。

---

### Task 1: PUT JSON 基础能力

**Files:**
- Modify: `app/lib/core/api_client.dart`
- Modify: `app/test/core/api_client_test.dart`

- [ ] 在 `api_client_test.dart` 增加失败测试：`putJson('/api/c/v1/user/profile')` 必须携带 token、区域、语言、`Content-Type` 和 `Idempotency-Key`，并解析 envelope。
- [ ] 运行 `flutter test test/core/api_client_test.dart`，确认因 `putJson`/`JsonMutationApi` 不存在而失败。
- [ ] 新增 `JsonMutationApi`，让 `ApiClient` 实现 `putJson(String path, {Object? body})`，复用写请求 headers 与 `_decode`。
- [ ] 重跑定向测试并确认通过。

### Task 2: 注册与重置密码仓储/控制器

**Files:**
- Modify: `app/lib/features/auth/auth_repository.dart`
- Modify: `app/lib/features/auth/auth_controller.dart`
- Modify: `app/test/features/auth/auth_repository_test.dart`
- Modify: `app/test/features/auth/auth_controller_test.dart`

- [ ] 先写失败测试，约束 `register` 请求 `/api/c/v1/auth/register`，payload 包含 `type/account/code/password/nickname/preferredRegion`，并映射 `AuthSession`。
- [ ] 实现 `AuthRepository.register(...)`，重跑仓储测试。
- [ ] 先写失败测试，约束 `resetPassword` 请求 `/api/c/v1/auth/password/reset`，payload 包含 `type/account/code/newPassword`。
- [ ] 实现 `AuthRepository.resetPassword(...)`，重跑仓储测试。
- [ ] 先写失败测试，约束 `AuthController.register(...)` 与登录共用会话保存逻辑，并新增 `replaceCurrentUser(AuthUser user)` 通知监听者。
- [ ] 实现控制器方法，重跑控制器测试。

### Task 3: 注册和找回密码页面

**Files:**
- Create: `app/lib/features/auth/register_screen.dart`
- Create: `app/lib/features/auth/reset_password_screen.dart`
- Modify: `app/lib/features/auth/login_screen.dart`
- Create: `app/test/features/auth/register_screen_test.dart`
- Create: `app/test/features/auth/reset_password_screen_test.dart`
- Modify: `app/test/features/auth/login_screen_test.dart`

- [ ] 先写注册页失败测试：发送验证码必须使用 `scene=register`，提交成功调用 `onAuthenticated`。
- [ ] 实现注册表单、加载态、错误提示和后端 `mockCode` 条件提示。
- [ ] 先写重置页失败测试：两次密码一致时调用重置接口，成功回调关闭页面；不一致时不发请求。
- [ ] 实现重置表单、验证码发送、密码确认和成功反馈。
- [ ] 先写登录页导航失败测试，约束“注册账号”“忘记密码”分别打开两个页面。
- [ ] 在 `LoginScreen` 接入两个入口，并把注册成功沿用原 `onAuthenticated`。

### Task 4: 完整用户资料和账户写接口

**Files:**
- Modify: `app/lib/features/user/user_repository.dart`
- Modify: `app/test/features/user/user_repository_test.dart`

- [ ] 先写失败测试，把 `hasPassword/gender/signature` 纳入 `UserProfile` 映射。
- [ ] 扩展 `UserProfile`，保留缺失字段的安全默认值。
- [ ] 先写失败测试，约束 `updateProfile` 使用 `PUT /api/c/v1/user/profile` 和完整资料 payload。
- [ ] 实现 `updateProfile`，若 API 不支持 `JsonMutationApi` 则抛出明确状态错误。
- [ ] 先写失败测试，约束 `sendBindCode(scene=bind)`、`bindAccount` 和 `updatePassword` 的请求路径与 payload。
- [ ] 实现三个方法并重跑仓储测试。

### Task 5: 账户设置页面

**Files:**
- Create: `app/lib/features/user/account_settings_screen.dart`
- Create: `app/test/features/user/account_settings_screen_test.dart`

- [ ] 先写失败 Widget 测试：加载资料后显示昵称、邮箱/手机号、签名和密码状态。
- [ ] 实现基础加载、错误态与三张设置卡片骨架。
- [ ] 先写失败测试：编辑昵称/头像 URL/性别/签名并保存后调用 `updateProfile`，触发 `onProfileChanged`。
- [ ] 实现资料保存和成功/错误反馈。
- [ ] 先写失败测试：发送绑定验证码使用 `scene=bind`，提交绑定后刷新资料。
- [ ] 实现绑定类型、账号、验证码和加载态。
- [ ] 先写失败测试：新密码确认不一致时拦截，一致时调用 `updatePassword`。
- [ ] 实现密码更新表单，并在成功后清空密码输入。
- [ ] 增加 375×812 Widget 回归，确保页面滚动后无 `RenderFlex` 溢出。

### Task 6: 用户中心接入与会话摘要同步

**Files:**
- Modify: `app/lib/features/user/user_center_screen.dart`
- Modify: `app/test/features/user/user_center_screen_test.dart`

- [ ] 先写失败测试，约束用户中心显示“账户设置”入口并能打开 `AccountSettingsScreen`。
- [ ] 把 `UserCenterScreen` 转为可刷新资料的 StatefulWidget；账户设置保存后调用 `AuthController.replaceCurrentUser`，返回用户中心时重新加载资料。
- [ ] 重跑用户中心和账户设置测试。

### Task 7: 回归、CI 与文档

**Files:**
- Modify: `app/README.md`
- Modify: `README.md`
- Modify: `docs/README.md`
- Modify: `docs/superpowers/plans/2026-07-15-m6-flutter-account-lifecycle.md`

- [ ] 运行 `dart format lib test`。
- [ ] 运行 `flutter test`，确认全部测试通过。
- [ ] 运行 `flutter analyze`，确认 0 issue。
- [ ] 运行 `flutter build web --no-wasm-dry-run`，确认构建成功。
- [ ] 同步已完成能力、测试计数和 M6 剩余边界，不把第三方 OAuth/真实短信邮件宣称为已接通。
