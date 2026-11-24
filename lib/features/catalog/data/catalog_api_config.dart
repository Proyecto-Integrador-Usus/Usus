/// Configurable at build time, for example:
/// flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
abstract final class CatalogApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );
}
