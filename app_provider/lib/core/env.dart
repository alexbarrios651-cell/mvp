class Env {
  // Base URL de la API. En emuladores Android, 10.0.2.2 apunta al host.
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://10.0.2.2:4000/api',
  );
}