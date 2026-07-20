import 'package:dazhongdianping_app/core/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app defaults to EU region and supports zh/en locale', () {
    const config = AppConfig();
    expect(config.region, AppRegion.eu);
    expect(config.apiBaseUrl, 'http://10.0.2.2:8080');
    expect(config.supportedLanguageCodes, ['zh', 'en']);
  });
}
