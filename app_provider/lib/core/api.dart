import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'env.dart';

/// Clase auxiliar para interactuar con la API REST.
///
/// Provee un cliente Dio configurado con el token de autenticación
/// almacenado en SharedPreferences. También permite guardar el token
/// recibido al iniciar sesión.
class Api {
  static final Dio _dio = Dio(BaseOptions(baseUrl: Env.apiBase));

  /// Devuelve un cliente Dio con los encabezados apropiados.
  static Future<Dio> client() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    _dio.interceptors.clear();
    _dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      if (token != null) o.headers['Authorization'] = 'Bearer $token';
      return h.next(o);
    }));
    return _dio;
  }

  /// Guarda el token JWT en almacenamiento local.
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }
}