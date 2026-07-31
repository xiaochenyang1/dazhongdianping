enum AppRegion { cn, eu }

extension AppRegionCode on AppRegion {
  String get code => this == AppRegion.eu ? 'EU' : 'CN';
}

class AppConfig {
  static const compiledRegionCode = String.fromEnvironment(
    'APP_REGION',
    defaultValue: 'EU',
  );
  static const defaultRegion = compiledRegionCode == 'CN'
      ? AppRegion.cn
      : AppRegion.eu;

  const AppConfig({
    this.region = defaultRegion,
    this.apiBaseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8080',
    ),
    this.languageTag = 'zh-CN',
  });

  final AppRegion region;
  final String apiBaseUrl;
  final String languageTag;

  List<String> get supportedLanguageCodes => const ['zh', 'en'];
}
