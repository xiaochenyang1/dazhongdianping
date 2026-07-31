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

Android 正式构建必须配置生产 application ID 和 release keystore。可在不入库的
`android/key.properties` 中填写：

```properties
DZDP_ANDROID_APPLICATION_ID=com.yourcompany.dazhongdianping
DZDP_ANDROID_KEYSTORE_PATH=/absolute/path/to/release.jks
DZDP_ANDROID_KEY_ALIAS=your-key-alias
DZDP_ANDROID_STORE_PASSWORD=your-store-password
DZDP_ANDROID_KEY_PASSWORD=your-key-password
```

相对 keystore 路径从 `app/android/` 解析。CI 也可使用同名环境变量或 Gradle
属性（`-P...`）；优先级依次为 Gradle 属性、环境变量、`key.properties`。仓库已
忽略 `key.properties`、`*.jks` 和 `*.keystore`，不要提交签名文件或密码。未配置
时 debug 构建不受影响，release 构建会明确失败，不会回退到 debug 签名。

真实地图、支付和推送仍需要对应供应商账号、密钥、sandbox/pre 环境与真机验收，仓库当前只声明已经实际接通和自动验证的能力。
