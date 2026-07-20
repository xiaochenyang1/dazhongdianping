# M6 Flutter 账户生命周期扩展设计

## 目标

补齐 Flutter 客户端当前缺失的注册、找回密码、资料编辑、账号绑定和登录密码更新，使游客认证与登录后账户维护都复用现有真实后端接口。

## 架构

- `features/auth` 负责游客侧账户入口：登录页提供注册和找回密码导航，`RegisterScreen` 创建会话并复用 `AuthController` 安全落盘 token，`ResetPasswordScreen` 重置成功后返回登录页。
- `features/user` 负责登录后账户维护：`AccountSettingsScreen` 加载完整 `UserProfile`，支持资料、绑定账号和修改密码；`UserRepository` 只封装真实 API，不在页面拼请求路径。
- `core/api_client.dart` 新增独立 `JsonMutationApi` 接口承载 `PUT`，避免给所有只读测试假 API 强行增加无关方法。
- 资料或绑定成功后，把昵称、头像和区域同步回 `AuthController.currentUser`；用户中心返回时重新拉取资料。

## 数据流

1. 注册/重置/绑定发送验证码时，根据账号是否含 `@` 选择 `email` 或 `phone`，并使用对应 `scene`：`register`、`reset`、`bind`。
2. 注册调用 `POST /api/c/v1/auth/register`，成功响应按登录会话处理。
3. 找回密码调用 `POST /api/c/v1/auth/password/reset`，成功后清空敏感输入并返回登录页，不假设用户已经登录。
4. 资料更新调用 `PUT /api/c/v1/user/profile`；账号绑定调用 `POST /api/c/v1/user/bind`；密码更新调用 `PUT /api/c/v1/user/password`。

## 页面与交互

- 注册页：账号、验证码、密码、昵称；验证码发送和提交均有加载态与错误提示。
- 找回密码页：账号、验证码、新密码、确认密码；两次密码不一致时只做本地拦截。
- 账户设置页：基础资料卡、账号绑定卡、密码更新卡。布局继续使用暖橙强调色、低海拔卡片和明确危险/成功反馈，不增加第三方登录入口。
- `mockCode` 只在后端明确返回时显示为本地提示；生产环境没有该字段时只显示发送成功。

## 错误与安全

- 页面不记录密码、验证码，不写入日志或持久化存储。
- 所有服务端错误沿用 `ApiException` 文本；页面提供字段缺失、密码确认不一致等本地校验。
- 账号绑定和密码修改必须在登录态执行；重置密码不复用登录态。

## 测试

- 单元测试覆盖每个请求路径、payload 和会话落盘。
- Widget 测试覆盖登录页导航、注册成功、重置密码、资料保存、绑定验证码/提交、修改密码及 375px 移动端无溢出。
- 最终执行 `flutter test`、`flutter analyze`、`flutter build web --no-wasm-dry-run`。

## 范围外

本批不实现第三方 OAuth、头像文件上传、设备管理和协议留痕；这些继续留在 M6 后续任务中。
