import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/auth/demo_login_page.dart';
import 'features/home/home_page.dart';
import 'features/requests/request_new_page.dart';
import 'features/requests/requests_page.dart';

void main() {
  runApp(const AllprocarApp());
}

class AllprocarApp extends StatelessWidget {
  const AllprocarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/signin',
      routes: [
        // Ruta principal después de la autenticación demo
        GoRoute(path: '/', builder: (_, __) => const HomePage()),
        // Ruta de inicio de sesión/registro demostrativo
        GoRoute(path: '/signin', builder: (_, __) => const DemoLoginPage()),
        // Rutas de la aplicación
        GoRoute(path: '/request/new', builder: (_, __) => const RequestNewPage()),
        GoRoute(path: '/requests', builder: (_, __) => const RequestsPage()),
      ],
    );

    return MaterialApp.router(
      title: 'Allprocar',
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(primary: Color(0xFF0E6BA8)),
        scaffoldBackgroundColor: const Color(0xFF0B132B),
      ),
      routerConfig: router,
    );
  }
}
