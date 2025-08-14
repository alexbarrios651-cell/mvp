class Env {
  // En emulador Android, 10.0.2.2 apunta al localhost del host.
  static const String apiBase = String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:4000/api');
}
