# Flutter 欧洲版 APP

`app/` 是 M6 Flutter 客户端，默认区域为 `EU`，复用现有 `/api/c/v1` 后端接口。

当前已落地：

- 首页、搜索、门店详情、团购下单与预订创建。
- 密码登录、验证码登录、会话安全存储、启动恢复和退出。
- 简体中文、繁体中文、英语基础资源，以及 CN/EU 区域切换。
- 用户中心及点评、收藏、订单、券、预订入口。
- 通知列表、未读消息 ACK 和首页登录保护入口。
- 隐私中心：规则与任务历史、创建导出、认证 ZIP 下载并保存到设备、验证码/密码复核删除申请、冷静期撤销。
- Google Maps、Stripe/PayPal、FCM/APNs 的配置边界和未配置保护；未配置时不会使用 mock 冒充真实接通。

本地运行：

```powershell
flutter pub get
flutter run
```

完整验证：

```powershell
flutter test
flutter analyze
flutter build web --no-wasm-dry-run
```

真实地图、支付和推送仍需要对应供应商账号、密钥、sandbox/pre 环境与真机验收，仓库当前只声明已经实际接通和自动验证的能力。
