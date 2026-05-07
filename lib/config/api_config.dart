class ApiConfig {
  static const String _devBaseUrl = 'http://localhost:3000';
  static const String _prodBaseUrl = 'https://tizhongji.cisonc.site';

  static String get baseUrl {
    return const bool.fromEnvironment('dart.vm.product', defaultValue: false)
        ? _prodBaseUrl
        : _devBaseUrl;
  }
}
