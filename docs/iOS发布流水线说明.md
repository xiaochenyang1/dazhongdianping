# iOS 发布流水线说明

`.github/workflows/ios-release.yml` 提供独立的签名 IPA 构建入口。它只生成经过校验、带 SHA-256 和脱敏 manifest 的 App Store Connect 制品，不会自动上传 TestFlight 或 App Store；商店上传、审核、分阶段发布和真机验收仍需 Apple 账号及人工放行。

## GitHub Environment 配置

`test`、`pre`、`prod` 分别配置下列值，`pre/prod` 应继续使用 Environment 审批规则：

| 类型 | 名称 | 用途 |
| --- | --- | --- |
| Variable | `DZDP_IOS_BUNDLE_ID` | 正式 reverse-DNS Bundle ID，拒绝 `com.example*` |
| Variable | `DZDP_IOS_TEAM_ID` | 10 位 Apple Developer Team ID |
| Variable | `DZDP_APP_API_BASE_URL` | HTTPS API 地址 |
| Variable | `VITE_STRIPE_PUBLISHABLE_KEY` | test/pre 使用 `pk_test_`，prod 使用 `pk_live_` |
| Variable | `PUBLIC_SITE_URL` | HTTPS 分享链接站点 |
| Secret | `DZDP_IOS_DISTRIBUTION_CERTIFICATE_BASE64` | Apple Distribution `.p12` 的 Base64 |
| Secret | `DZDP_IOS_DISTRIBUTION_CERTIFICATE_PASSWORD` | `.p12` 密码 |
| Secret | `DZDP_IOS_PROVISIONING_PROFILE_BASE64` | App Store 描述文件的 Base64 |
| Secret | `DZDP_GOOGLE_MAPS_API_KEY` | iOS Google Maps key |
| Secret | `DZDP_FIREBASE_IOS_CONFIG_BASE64` | 可选的 `GoogleService-Info.plist` Base64 |

证书须包含 `Apple Distribution` 身份。描述文件的 Team ID、application identifier 和 Bundle ID 必须与变量一致，并包含 `aps-environment=production`。Firebase 配置非空时，其 `BUNDLE_ID` 也必须一致。

## 流水线门禁和产物

流水线在 `macos-15` 上固定 Flutter 3.44.8，以 `Podfile.lock` 和 `pod install --deployment` 锁定原生依赖，执行 `flutter test`、`flutter analyze`，再通过临时钥匙串和手工签名导出 App Store Connect IPA。构建后会重新解包并核对 Bundle ID、版本号、build number、嵌入描述文件、代码签名和生产 APNs entitlement。

上传的 artifact 包含：

- 版本化 `.ipa`
- `.ipa.sha256`
- 不含证书、密码、Maps/Stripe/Firebase key 的 `ios-release-manifest.json`

无论成功或失败，流水线都会删除临时 `.p12`、描述文件、Firebase plist、Xcode override、export options 和临时钥匙串。

## 仍需真实验收

首次运行前必须由 Apple/Firebase/Google Maps 管理员提供真实配置。流水线成功只证明 IPA 的构建与签名契约通过，不代表 TestFlight/App Store 已提交，也不替代真机安装、Stripe 支付、地图、前后台 APNs/FCM、深链和商店审核验收。
