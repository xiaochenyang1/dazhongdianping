$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$workflowPath = Join-Path $repoRoot ".github\workflows\mobile-release.yml"

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

Assert-True (Test-Path -LiteralPath $workflowPath) ".github/workflows/mobile-release.yml must exist"

$workflow = Get-Content -LiteralPath $workflowPath -Raw

Assert-True ($workflow -match "workflow_dispatch:") "mobile release must be manually dispatched"
Assert-True ($workflow -match "environment:.*\$\{\{ inputs\.environment \}\}") "mobile release must use a GitHub Environment gate"
Assert-True ($workflow -match "region:") "mobile release must require a release region"
Assert-True ($workflow -match "build_name:") "mobile release must require a build name"
Assert-True ($workflow -match "build_number:") "mobile release must require a build number"
Assert-True ($workflow -match "DZDP_ANDROID_APPLICATION_ID:.*vars\.DZDP_ANDROID_APPLICATION_ID") "mobile release must read the application ID from environment variables"
Assert-True ($workflow -match "DZDP_APP_API_BASE_URL:.*vars\.DZDP_APP_API_BASE_URL") "mobile release must read the API base URL from environment variables"
Assert-True ($workflow -match "DZDP_ANDROID_KEYSTORE_BASE64:.*secrets\.DZDP_ANDROID_KEYSTORE_BASE64") "mobile release must read the keystore from environment secrets"
Assert-True ($workflow -match "DZDP_ANDROID_KEY_ALIAS:.*secrets\.DZDP_ANDROID_KEY_ALIAS") "mobile release must read the key alias from environment secrets"
Assert-True ($workflow -match "DZDP_ANDROID_STORE_PASSWORD:.*secrets\.DZDP_ANDROID_STORE_PASSWORD") "mobile release must read the store password from environment secrets"
Assert-True ($workflow -match "DZDP_ANDROID_KEY_PASSWORD:.*secrets\.DZDP_ANDROID_KEY_PASSWORD") "mobile release must read the key password from environment secrets"
Assert-True ($workflow -match "base64 --decode") "mobile release must decode the keystore at runtime"
Assert-True ($workflow -match "flutter test") "mobile release must run Flutter tests"
Assert-True ($workflow -match "flutter analyze") "mobile release must run Flutter analysis"
Assert-True ($workflow -match "flutter build appbundle --release") "mobile release must build a release app bundle"
Assert-True ($workflow -match "--build-name") "mobile release must stamp the requested build name"
Assert-True ($workflow -match "--build-number") "mobile release must stamp the requested build number"
Assert-True ($workflow -match '--dart-define "API_BASE_URL=\$DZDP_APP_API_BASE_URL"') "mobile release must compile the selected API base URL into the app"
Assert-True ($workflow -match '--dart-define "APP_REGION=\$RELEASE_REGION"') "mobile release must compile the selected initial region into the app"
Assert-True ($workflow -match "jarsigner -verify") "mobile release must verify the app bundle signature"
Assert-True ($workflow -match "META-INF/.*RSA.*DSA.*EC") "mobile release must require an app bundle signing block"
Assert-True ($workflow -match "sha256sum") "mobile release must checksum the app bundle"
Assert-True ($workflow -match "mobile-release-manifest\.json") "mobile release must write a release manifest"
Assert-True ($workflow -match "actions/upload-artifact@v4") "mobile release must upload the signed app bundle"
Assert-True ($workflow -match "if-no-files-found: error") "mobile release must fail when the app bundle is missing"
Assert-True ($workflow -match "if: always\(\)") "mobile release must always clean up the keystore"
Assert-True ($workflow -match "rm -f.*dzdp-android-release\.jks") "mobile release must remove the decoded keystore"

Write-Output "mobile release workflow contract passed"
