import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/demo_provider_login_page.dart';
import 'features/home/home_provider_page.dart';
import 'features/requests/available_requests_page.dart';
import 'features/requests/assigned_requests_page.dart';

void main() {
  runApp(const AllprocarProviderApp());
}

/// Aplicación principal de Allprocar para proveedores.
///
/// Utiliza GoRouter para la navegación. Inicializa en la pantalla de
/// inicio de sesión demo.
class AllprocarProviderApp extends StatelessWidget {
  const AllprocarProviderApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/signin',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeProviderPage()),
        GoRoute(path: '/signin', builder: (_, __) => const DemoProviderLoginPage()),
        GoRoute(path: '/requests/available', builder: (_, __) => const AvailableRequestsPage()),
        GoRoute(path: '/requests/assigned', builder: (_, __) => const AssignedRequestsPage()),
      ],
    );
    return MaterialApp.router(
      title: 'Allprocar Taller',
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(primary: Color(0xFF0E6BA8)),
        scaffoldBackgroundColor: const Color(0xFF0B132B),
      ),
      routerConfig: router,
    );
  }
}