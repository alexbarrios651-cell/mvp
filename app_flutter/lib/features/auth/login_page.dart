import 'package:flutter/material.dart';
import '../../core/api.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> _login() async {
    setState(() { loading = true; error = null; });
    try {
      final dio = await Api.client();
      final res = await dio.post('/auth/login', data: {
        'email': email.text.trim(),
        'password': pass.text,
      });
      await Api.saveToken(res.data['token']);
      if (!mounted) return;
      context.go('/');
    } on DioException catch (e) {
      setState(() { error = e.response?.data?['error']?.toString() ?? 'Error'; });
    } finally {
      setState(() { loading = false; });
    }
  }

  Future<void> _registerProveedor() async {
    // registro rápido como proveedor demo
    setState(() { loading = true; error = null; });
    try {
      final dio = await Api.client();
      final res = await dio.post('/auth/register', data: {
        'nombre': 'Proveedor Demo',
        'email': email.text.trim(),
        'password': pass.text,
        'rol': 'proveedor',
      });
      await Api.saveToken(res.data['token']);
      if (!mounted) return;
      context.go('/');
    } on DioException catch (e) {
      setState(() { error = e.response?.data?['error']?.toString() ?? 'Error'; });
    } finally {
      setState(() { loading = false; });
    }
  }

  Future<void> _registerCliente() async {
    setState(() { loading = true; error = null; });
    try {
      final dio = await Api.client();
      final res = await dio.post('/auth/register', data: {
        'nombre': 'Cliente Demo',
        'email': email.text.trim(),
        'password': pass.text,
        'rol': 'cliente',
      });
      await Api.saveToken(res.data['token']);
      if (!mounted) return;
      context.go('/');
    } on DioException catch (e) {
      setState(() { error = e.response?.data?['error']?.toString() ?? 'Error'; });
    } finally {
      setState(() { loading = false; });
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
                const Text('Allprocar', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña')),
                const SizedBox(height: 12),
                if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                // Los tres botones se agrupan en un Wrap para evitar desbordes
                // en pantallas estrechas. Wrap reparte los elementos en varias
                // filas si no hay espacio suficiente.
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: loading ? null : _login,
                      child: const Text('Ingresar'),
                    ),
                    ElevatedButton(
                      onPressed: loading ? null : _registerCliente,
                      child: const Text('Crear Cliente'),
                    ),
                    ElevatedButton(
                      onPressed: loading ? null : _registerProveedor,
                      child: const Text('Crear Proveedor'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
