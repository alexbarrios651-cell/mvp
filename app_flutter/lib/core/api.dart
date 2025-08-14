import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'env.dart';

class Api {
  static final Dio _dio = Dio(BaseOptions(baseUrl: Env.apiBase));

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

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }
}
