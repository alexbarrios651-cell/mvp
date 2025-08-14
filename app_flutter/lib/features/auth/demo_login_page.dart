import 'package:flutter/material.dart';
import '../../core/api.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

/// Página de inicio de sesión demostrativa para la app de dueños de vehículos.
///
/// Esta pantalla no solicita datos al usuario; en su lugar, crea o inicia
/// sesión con un usuario y vehículo predeterminados. Si el usuario ya existe
/// (email en uso) intenta loguearse con las mismas credenciales. Tras
/// autenticarse, se registrará automáticamente un vehículo si no hay
/// vehículos asociados. Por simplicidad, se omite la contraseña en la UI.
class DemoLoginPage extends StatefulWidget {
  const DemoLoginPage({super.key});

  @override
  State<DemoLoginPage> createState() => _DemoLoginPageState();
}

class _DemoLoginPageState extends State<DemoLoginPage> {
  bool loading = false;
  String? error;

  // Configuración del usuario y vehículo demo. Ajusta estos valores si
  // quieres personalizar el usuario predeterminado.
  final String _demoName = 'Usuario Demo';
  final String _demoEmail = 'cliente@demo.com';
  final String _demoPassword = 'demo1234';
  final Map<String, dynamic> _demoVehicle = {
    'marca': 'Toyota',
    'modelo': 'Corolla',
    'anio': 2016,
  };

  Future<void> _loginDemo() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final dio = await Api.client();
      // Intenta registrar el usuario demo
      Response res;
      try {
        res = await dio.post('/auth/register', data: {
          'nombre': _demoName,
          'email': _demoEmail,
          'password': _demoPassword,
          'rol': 'cliente',
        });
      } on DioException catch (e) {
        // Si el email ya existe, intenta login
        if (e.response?.statusCode == 409) {
          res = await dio.post('/auth/login', data: {
            'email': _demoEmail,
            'password': _demoPassword,
          });
        } else {
          throw e;
        }
      }
      // Guarda el token en SharedPreferences
      final token = res.data['token'] as String;
      await Api.saveToken(token);
      // Comprueba si ya existe un vehículo; si no, crea uno
      try {
        final vehRes = await dio.get('/vehiculos');
        final list = vehRes.data as List;
        if (list.isEmpty) {
          await dio.post('/vehiculos', data: _demoVehicle);
        }
      } catch (_) {
        // Ignoramos cualquier error de creación de vehículo
      }
      if (!mounted) return;
      // Navega a la pantalla principal
      context.go('/');
    } on DioException catch (e) {
      setState(() {
        error = e.response?.data?['error']?.toString() ?? 'Error al iniciar sesión';
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Allprocar Demo',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bienvenido a la versión demostrativa para dueños de vehículos.\n'
                  'Esta app crea un usuario y un vehículo predeterminados para que puedas\n'
                  'probar las funciones sin registrarte.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (error != null) ...[
                  Text(error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                ],
                ElevatedButton(
                  onPressed: loading ? null : _loginDemo,
                  child: Text(loading ? 'Accediendo...' : 'Iniciar sesión demo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}