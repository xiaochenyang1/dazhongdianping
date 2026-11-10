$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$workflowPath = Join-Path $repoRoot ".github\workflows\ios-release.yml"
$projectPath = Join-Path $repoRoot "app\ios\Runner.xcodeproj\project.pbxproj"
$entitlementsPath = Join-Path $repoRoot "app\ios\Runner\Runner.entitlements"
$releaseConfigPath = Join-Path $repoRoot "app\ios\Flutter\Release.xcconfig"
$defaultsPath = Join-Path $repoRoot "app\ios\Flutter\Environment.xcconfig"
$firebaseOptionsPath = Join-Path $repoRoot "app\lib\firebase_options.dart"
$podfilePath = Join-Path $repoRoot "app\ios\Podfile"
$podfileLockPath = Join-Path $repoRoot "app\ios\Podfile.lock"

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

foreach ($path in @($workflowPath, $projectPath, $entitlementsPath, $releaseConfigPath, $defaultsPath, $firebaseOptionsPath, $podfilePath, $podfileLockPath)) {
    Assert-True (Test-Path -LiteralPath $path) "$path must exist"
}

$workflow = Get-Content -LiteralPath $workflowPath -Raw
$project = Get-Content -LiteralPath $projectPath -Raw
$entitlements = Get-Content -LiteralPath $entitlementsPath -Raw
$releaseConfig = Get-Content -LiteralPath $releaseConfigPath -Raw
$defaults = Get-Content -LiteralPath $defaultsPath -Raw
$firebaseOptions = Get-Content -LiteralPath $firebaseOptionsPath -Raw
$podfile = Get-Content -LiteralPath $podfilePath -Raw

Assert-True ($workflow -match "workflow_dispatch:") "iOS release must be manually dispatched"
Assert-True ($workflow -match "environment:.*\$\{\{ inputs\.environment \}\}") "iOS release must use a GitHub Environment gate"
Assert-True ($workflow -match "runs-on:\s*macos-15") "iOS release must pin macOS 15"
Assert-True ($workflow -match "region:") "iOS release must require a release region"
Assert-True ($workflow -match "build_name:") "iOS release must require a build name"
Assert-True ($workflow -match "build_number:") "iOS release must require a build number"
Assert-True ($workflow -match "DZDP_IOS_BUNDLE_ID:.*vars\.DZDP_IOS_BUNDLE_ID") "iOS release must read the bundle ID from environment variables"
Assert-True ($workflow -match "DZDP_IOS_TEAM_ID:.*vars\.DZDP_IOS_TEAM_ID") "iOS release must read the Team ID from environment variables"
Assert-True ($workflow -match "DZDP_APP_API_BASE_URL:.*vars\.DZDP_APP_API_BASE_URL") "iOS release must read the API base URL from environment variables"
Assert-True ($workflow -match "DZDP_IOS_DISTRIBUTION_CERTIFICATE_BASE64:.*secrets\.DZDP_IOS_DISTRIBUTION_CERTIFICATE_BASE64") "iOS release must read the distribution certificate from environment secrets"
Assert-True ($workflow -match "DZDP_IOS_DISTRIBUTION_CERTIFICATE_PASSWORD:.*secrets\.DZDP_IOS_DISTRIBUTION_CERTIFICATE_PASSWORD") "iOS release must read the certificate password from environment secrets"
Assert-True ($workflow -match "DZDP_IOS_PROVISIONING_PROFILE_BASE64:.*secrets\.DZDP_IOS_PROVISIONING_PROFILE_BASE64") "iOS release must read the provisioning profile from environment secrets"
Assert-True ($workflow -match "DZDP_FIREBASE_IOS_CONFIG_BASE64:.*secrets\.DZDP_FIREBASE_IOS_CONFIG_BASE64") "iOS release must read optional Firebase configuration from environment secrets"
Assert-True ($workflow -match "GOOGLE_MAPS_API_KEY:.*secrets\.DZDP_GOOGLE_MAPS_API_KEY") "iOS release must read the Maps key from environment secrets"
Assert-True ($workflow -match "STRIPE_PUBLISHABLE_KEY:.*vars\.VITE_STRIPE_PUBLISHABLE_KEY") "iOS release must reuse the Web Stripe publishable key"
Assert-True ($workflow -match "SHARE_BASE_URL:.*vars\.PUBLIC_SITE_URL") "iOS release must reuse the public site URL for share links"
Assert-True ($workflow -match 'flutter-version:\s*"3\.44\.8"') "iOS release must pin Flutter 3.44.8"
Assert-True ($workflow -match "base64 -D") "iOS release must decode signing material at runtime"
Assert-True ($workflow -match "security create-keychain") "iOS release must use a temporary signing keychain"
Assert-True ($workflow -match "security import") "iOS release must import the distribution certificate"
Assert-True ($workflow -notmatch "security import[^\r\n]* -A") "iOS release must not grant every process access to the imported signing key"
Assert-True ($workflow -match "-T /usr/bin/codesign") "iOS release must scope private-key access to codesign"
Assert-True ($workflow -match "security set-key-partition-list") "iOS release must allow non-interactive codesigning"
Assert-True ($workflow -match "TeamIdentifier:0") "iOS release must validate the provisioning profile Team ID"
Assert-True ($workflow -match "Entitlements:application-identifier") "iOS release must validate the provisioning profile bundle ID"
Assert-True ($workflow -match "Entitlements:aps-environment") "iOS release must validate production APNs provisioning"
Assert-True ($workflow -match "app-store-connect") "iOS release must export an App Store Connect IPA"
Assert-True ($workflow -match "signingStyle string manual") "iOS release must use deterministic manual signing"
Assert-True ($workflow -match "flutter test") "iOS release must run Flutter tests"
Assert-True ($workflow -match "flutter analyze") "iOS release must run Flutter analysis"
Assert-True ($workflow -match "pod install --deployment") "iOS release must enforce the committed CocoaPods lockfile"
Assert-True ($workflow -match "flutter build ipa --release") "iOS release must build a release IPA"
Assert-True ($workflow -match "--export-options-plist") "iOS release must supply export options"
Assert-True ($workflow -match '--dart-define "API_BASE_URL=\$DZDP_APP_API_BASE_URL"') "iOS release must compile the selected API base URL into the app"
Assert-True ($workflow -match '--dart-define "APP_REGION=\$RELEASE_REGION"') "iOS release must compile the selected initial region into the app"
Assert-True ($workflow -match '--dart-define "FIREBASE_IOS_APP_ID=\$FIREBASE_IOS_APP_ID"') "iOS release must compile Firebase iOS options into the app"
Assert-True ($workflow -match '::add-mask::\$firebase_api_key') "iOS release must mask extracted Firebase client configuration"
Assert-True ($workflow -match '--dart-define "GOOGLE_MAPS_NATIVE_CONFIGURED=true"') "iOS release must enable native maps only after requiring its key"
Assert-True ($workflow -match 'expected_stripe_prefix="pk_test_"') "test and pre iOS releases must require a Stripe test key"
Assert-True ($workflow -match 'expected_stripe_prefix="pk_live_"') "prod iOS releases must require a Stripe live key"
Assert-True ($workflow -match "codesign --verify --deep --strict") "iOS release must verify the IPA code signature"
Assert-True ($workflow -match "codesign -d --entitlements") "iOS release must inspect signed entitlements"
Assert-True ($workflow -match "embedded\.mobileprovision") "iOS release must verify the embedded provisioning profile"
Assert-True ($workflow -match "CFBundleShortVersionString") "iOS release must verify the marketing version"
Assert-True ($workflow -match "CFBundleVersion") "iOS release must verify the build number"
Assert-True ($workflow -match "shasum -a 256") "iOS release must checksum the IPA"
Assert-True ($workflow -match "ios-release-manifest\.json") "iOS release must write a sanitized manifest"
Assert-True ($workflow -match "actions/upload-artifact@v7\.0\.2") "iOS release must upload the signed IPA with upload-artifact 7.0.2"
Assert-True ($workflow -match "if: always\(\)") "iOS release must always clean temporary credentials"
Assert-True ($workflow -match "security delete-keychain") "iOS release must remove the temporary keychain"
Assert-True ($workflow -match 'rm -f "\$DZDP_IOS_INSTALLED_PROFILE"') "iOS release must remove the installed provisioning profile"

Assert-True ($project -notmatch "PRODUCT_BUNDLE_IDENTIFIER = com\.example\.dazhongdianpingApp") "the Xcode project must not hardcode the example application ID"
Assert-True (([regex]::Matches($project, "DZDP_IOS_BUNDLE_ID = com\.example\.dazhongdianpingApp")).Count -eq 3) "all project configurations must provide a safe bundle ID default for inherited test targets"
Assert-True ($project -match 'PRODUCT_BUNDLE_IDENTIFIER = "\$\(DZDP_IOS_BUNDLE_ID\)"') "the Runner bundle ID must be configurable"
Assert-True ($project -match 'PRODUCT_BUNDLE_IDENTIFIER = "\$\(DZDP_IOS_BUNDLE_ID\)\.RunnerTests"') "the test bundle ID must follow the application bundle ID"
Assert-True ($entitlements -match '<string>\$\(DZDP_APNS_ENVIRONMENT\)</string>') "the APNs entitlement must be configurable"
Assert-True ($defaults -match "DZDP_IOS_BUNDLE_ID = com\.example\.dazhongdianpingApp") "local iOS builds must retain a safe example bundle ID"
Assert-True ($defaults -match "DZDP_APNS_ENVIRONMENT = development") "local iOS builds must default to development APNs"
Assert-True ($releaseConfig -match '#include\? "ReleaseOverrides\.xcconfig"') "release builds must load ignored runtime overrides"
Assert-True ($firebaseOptions -match "String\.fromEnvironment\('FIREBASE_IOS_APP_ID'\)") "Firebase iOS app ID must be injectable"
Assert-True ($firebaseOptions -match "String\.fromEnvironment\('FIREBASE_IOS_SENDER_ID'\)") "Firebase iOS sender ID must be injectable"
Assert-True ($firebaseOptions -match "String\.fromEnvironment\('FIREBASE_IOS_PROJECT_ID'\)") "Firebase iOS project ID must be injectable"
Assert-True ($podfile -match "config\.build_settings\['IPHONEOS_DEPLOYMENT_TARGET'\] = '15\.0'") "all CocoaPods targets must follow the application's iOS 15 deployment floor"

Write-Output "iOS release workflow contract passed"
