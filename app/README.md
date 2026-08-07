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
- Android 登录设备会在配置 Firebase 后登记 FCM token，iOS 登记 APNs token；token 轮换会同步回后端，退出时停用当前设备。
- 推送代码路径：`lib/core/push_service.dart` 在 `FIREBASE_CONFIGURED=true`（`ThirdPartyConfig.pushEnabled`）时走 Firebase；初始化优先 `DefaultFirebaseOptions.currentPlatform`（`lib/firebase_options.dart`，可由 dart-define 注入 API Key），失败再回退平台默认 `Firebase.initializeApp()`（依赖真实 `google-services.json` / `GoogleService-Info.plist`）；任一步失败静默降级为无推送，不崩溃。完整配置步骤见仓库根目录 `docs/firebase-push-setup.md`。未放入原生配置文件前，本地默认保持推送关闭。

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

仓库的 `.github/workflows/mobile-release.yml` 提供手工签名构建入口。先在 GitHub
的 `test`、`pre`、`prod` Environment 中配置变量
`DZDP_ANDROID_APPLICATION_ID`、`DZDP_APP_API_BASE_URL`（必须为绝对 HTTPS URL），
并配置以下 secrets：

- `DZDP_ANDROID_KEYSTORE_BASE64`：release keystore 文件的 Base64 内容。
- `DZDP_ANDROID_KEY_ALIAS`
- `DZDP_ANDROID_STORE_PASSWORD`
- `DZDP_ANDROID_KEY_PASSWORD`
- `DZDP_FIREBASE_ANDROID_CONFIG_BASE64`：可选，Firebase `google-services.json` 的 Base64 内容；未配置时发布包保持推送关闭。

触发 `mobile-release` 时必须选择环境、区域并填写语义版本号和正整数构建号。流水线
会先运行 Flutter 测试与静态分析，再生成签名 AAB、SHA-256 文件和
`mobile-release-manifest.json`，作为保留 30 天的 GitHub Actions artifact 上传。
所选区域会通过 `APP_REGION` 编译为首次启动区域，API 地址会通过
`API_BASE_URL` 编译进应用；存在 Firebase 配置时流水线还会写入
`FIREBASE_CONFIGURED=true`。用户仍可在应用内切换 CN/EU。
解码后的 keystore 只存在于 runner 临时目录，并在成功或失败后清理。该入口只生成
可追溯的签名制品；上传 Google Play 仍需目标商店账号和发布审批。

真实地图、支付和推送仍需要对应供应商账号、密钥、sandbox/pre 环境与真机验收，仓库当前只声明已经实际接通和自动验证的能力。
