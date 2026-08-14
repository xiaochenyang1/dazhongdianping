# Flutter 欧洲版 APP

`app/` 是 M6 Flutter 客户端，默认区域为 `EU`，复用现有 `/api/c/v1` 后端接口。

当前已落地：

- 首页、搜索、门店详情、团购下单与预订创建。
- 门店详情与后端 `ShopDetailResponse` / Web 视图对齐 §3.3 商户详情：封面图（`coverUrl` 缺失时占位容器，不构造空 `Image.network`）、口味/环境/服务三维评分明细、推荐菜（菜名 + 推荐理由 + 区域化价格）、门店相册三宫格（图片加载失败回退占位图）。
- 密码登录、验证码登录、会话安全存储、启动恢复和退出。
- 简体中文、繁体中文、英语基础资源，以及 CN/EU 区域切换。
- 用户中心及点评、收藏、订单、券、预订入口。
- 通知列表、未读消息 ACK 和首页登录保护入口。
- 隐私中心：规则与任务历史、创建导出、认证 ZIP 下载并保存到设备、验证码/密码复核删除申请、冷静期撤销。
- Google Maps 可用闭环：配置 `GOOGLE_MAPS_API_KEY` 后，首页地图入口展示当前区域带坐标门店、门店选择列表并支持外部到店导航；Android/iOS 在同时设置 `GOOGLE_MAPS_NATIVE_CONFIGURED=true` 且完成原生 Key 注入时使用可缩放/拖动/点击标记的原生交互地图，并提供用户主动触发的前台定位、当前位置蓝点、镜头聚焦、附近门店距离展示与就近排序；地图拖动或缩放停止后会按可见边界动态刷新门店，空结果或失败时保留已有标记；Web 或未完成原生注入的构建安全降级为 Static Maps。真实地图凭证和真机定位 smoke 仍待验收。

### Google Maps 本地配置

- Android：运行前把 Key 同时提供给 Gradle 环境和 Dart：`GOOGLE_MAPS_API_KEY=你的Key flutter run --dart-define=GOOGLE_MAPS_API_KEY=你的Key --dart-define=GOOGLE_MAPS_NATIVE_CONFIGURED=true`。Gradle 会把环境变量写入 Manifest，Key 不进入仓库。
- iOS：复制 `ios/Flutter/Maps.xcconfig.example` 为 `ios/Flutter/Maps.xcconfig`，填入 Key；再以相同的两个 `--dart-define` 启动。真实文件已被忽略。
- iOS 最低版本统一为 15.0，这是当前 Firebase iOS SDK 的最低要求，也覆盖 Google Maps SDK；Podfile、Xcode target 和 Flutter framework metadata 必须保持一致。
- iOS 当前在 `pubspec.yaml` 中按项目固定使用 CocoaPods，因为地图、文件保存和安全存储插件尚未全部支持 Swift Package Manager；不要依赖开发机的 Flutter 全局开关改变依赖管理方式。
- Web：当前继续使用 Static Maps，不加载 Maps JavaScript SDK；只需 `--dart-define=GOOGLE_MAPS_API_KEY=你的Key`，不要设置 native configured。
- GitHub Android 发布：在对应 Environment 增加 secret `DZDP_GOOGLE_MAPS_API_KEY`；流水线会同时注入 Manifest 与 Dart，并仅在 secret 非空时启用交互地图。
- Google Cloud 至少开启 Maps SDK for Android、Maps SDK for iOS 和 Maps Static API，并按 Android 包名/签名、iOS Bundle ID、Web 来源分别限制 Key。生产环境不建议三端共用一个无限制 Key。
- 用户定位只在 Android/iOS 交互地图中由用户点击定位按钮后申请前台权限，不申请后台定位；拒绝、永久拒绝或系统定位关闭时仍可继续按城市和门店列表浏览。
- 门店详情分享走系统原生分享面板（`share_plus`），分享链接的站点域名由 `SHARE_BASE_URL` dart-define 注入（默认占位 `https://local.life`，生产用真实域名覆盖），目标平台无原生分享目标时降级写入剪贴板。
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
`DZDP_ANDROID_APPLICATION_ID`、`DZDP_APP_API_BASE_URL`（必须为绝对 HTTPS URL）、
`VITE_STRIPE_PUBLISHABLE_KEY` 和 `PUBLIC_SITE_URL`。移动流水线复用后两项，分别
注入 Flutter 的 `STRIPE_PUBLISHABLE_KEY` 与 `SHARE_BASE_URL`；`test/pre` 必须使用
`pk_test_`，`prod` 必须使用 `pk_live_`，分享域名必须是 HTTPS。同时配置以下
secrets：

- `DZDP_ANDROID_KEYSTORE_BASE64`：release keystore 文件的 Base64 内容。
- `DZDP_ANDROID_KEY_ALIAS`
- `DZDP_ANDROID_STORE_PASSWORD`
- `DZDP_ANDROID_KEY_PASSWORD`
- `DZDP_FIREBASE_ANDROID_CONFIG_BASE64`：可选，Firebase `google-services.json` 的 Base64 内容；未配置时发布包保持推送关闭。

触发 `mobile-release` 时必须选择环境、区域并填写语义版本号和正整数构建号。流水线
会先运行 Flutter 测试与静态分析，再生成签名 AAB、SHA-256 文件和
`mobile-release-manifest.json`，作为保留 30 天的 GitHub Actions artifact 上传。
所选区域会通过 `APP_REGION` 编译为首次启动区域，API 地址会通过
`API_BASE_URL` 编译进应用；Stripe publishable key 与公开站点域名也会分别通过
`STRIPE_PUBLISHABLE_KEY`、`SHARE_BASE_URL` 编译，存在 Firebase 配置时流水线还会
写入 `FIREBASE_CONFIGURED=true`。manifest 记录分享域名和 Stripe 已配置状态，但不
记录 publishable key。用户仍可在应用内切换 CN/EU。
解码后的 keystore 只存在于 runner 临时目录，并在成功或失败后清理。该入口只生成
可追溯的签名制品；上传 Google Play 仍需目标商店账号和发布审批。

真实地图、支付和推送仍需要对应供应商账号、密钥、sandbox/pre 环境与真机验收，仓库当前只声明已经实际接通和自动验证的能力。
