/// Build-time configuration.
///
/// The API base URL is intentionally NOT baked into the source tree. Supply it
/// with `--dart-define=API_BASE_URL=https://your.host` (the CI workflow wires
/// this to a GitHub repository variable), so the same sources can be rebuilt
/// against any backend you control.
class AppConfig {
  const AppConfig({required this.baseUrl});

  final String baseUrl;

  bool get configured {
    final u = Uri.tryParse(baseUrl);
    return u != null && u.hasScheme && u.host.isNotEmpty;
  }

  static const AppConfig current = AppConfig(
    baseUrl: String.fromEnvironment('API_BASE_URL', defaultValue: ''),
  );
}
