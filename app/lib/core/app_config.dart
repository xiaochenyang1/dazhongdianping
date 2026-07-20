enum AppRegion { cn, eu }

extension AppRegionCode on AppRegion {
  String get code => this == AppRegion.eu ? 'EU' : 'CN';
}

class AppConfig {
  const AppConfig({
    this.region = AppRegion.eu,
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
