import 'package:dazhongdianping_app/core/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app uses compiled configuration and supports zh/en locale', () {
    const expectedRegionCode = String.fromEnvironment(
      'EXPECTED_APP_REGION',
      defaultValue: 'EU',
    );
    const expectedApiBaseUrl = String.fromEnvironment(
      'EXPECTED_API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8080',
    );
    const config = AppConfig();
    final expectedRegion = expectedRegionCode == 'CN'
        ? AppRegion.cn
        : AppRegion.eu;

    expect(config.region, expectedRegion);
    expect(AppConfig.compiledRegionCode, expectedRegionCode);
    expect(AppConfig.defaultRegion, expectedRegion);
    expect(config.apiBaseUrl, expectedApiBaseUrl);
    expect(config.supportedLanguageCodes, ['zh', 'en']);
  });
}
