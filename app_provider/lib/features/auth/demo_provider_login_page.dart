import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/api.dart';

/// Página de inicio de sesión demo para la app de proveedores.
///
/// Esta pantalla no solicita datos al usuario; al pulsar el botón se
/// registra o inicia sesión con un usuario predeterminado. Si el taller
/// no existe, lo crea con datos predeterminados y las especialidades
/// configuradas abajo. El objetivo es permitir una prueba rápida sin
/// configuración.
class DemoProviderLoginPage extends StatefulWidget {
  const DemoProviderLoginPage({super.key});

  @override
  State<DemoProviderLoginPage> createState() => _DemoProviderLoginPageState();
}

class _DemoProviderLoginPageState extends State<DemoProviderLoginPage> {
  bool loading = false;
  String? error;

  // Datos predeterminados del proveedor demo
  final String _name = 'Proveedor Demo';
  final String _email = 'proveedor@demo.com';
  final String _password = 'demo1234';
  final String _workshopName = 'Taller Demo';
  final String _workshopDesc = 'Taller demostrativo para Allprocar';
  final List<String> _specialties = [
    'cambio-aceite-filtros',
    'pastillas-discos',
    'scanner-obd2',
  ];

  Future<void> _loginDemo() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final dio = await Api.client();
      // Registrar o loguear usuario proveedor
      Response res;
      try {
        res = await dio.post('/auth/register', data: {
          'nombre': _name,
          'email': _email,
          'password': _password,
          'rol': 'proveedor',
        });
      } on DioException catch (e) {
        if (e.response?.statusCode == 409) {
          // Ya existe, intenta login
          res = await dio.post('/auth/login', data: {
            'email': _email,
            'password': _password,
          });
        } else {
          throw e;
        }
      }
      final token = res.data['token'] as String;
      await Api.saveToken(token);
      // Crear o actualizar taller demo
      Position? pos;
      try {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
          pos = await Geolocator.getCurrentPosition();
        }
      } catch (_) {
        // Ignorar errores de geolocalización
      }
      final dioAuthed = await Api.client();
      // ¿Existe taller?
      final tRes = await dioAuthed.get('/taller');
      if (tRes.data == null) {
        await dioAuthed.put('/taller', data: {
          'nombreComercial': _workshopName,
          'descripcion': _workshopDesc,
          'especialidades': _specialties,
          'geo': {
            'lat': pos?.latitude ?? 0,
            'lng': pos?.longitude ?? 0,
          },
        });
      }
      if (!mounted) return;
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
                  'Allprocar Taller Demo',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bienvenido a la versión demostrativa para talleres.
Pulsa el botón para iniciar sesión con el usuario de prueba y crear tu taller demo.',
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