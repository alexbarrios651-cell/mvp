import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api.dart';

/// Página principal para la app de proveedores.
///
/// Muestra información básica del taller registrado y ofrece accesos
/// rápidos para ver las solicitudes abiertas (disponibles) y las
/// solicitudes asignadas al proveedor. Carga la información del taller
/// desde la API al iniciarse.
class HomeProviderPage extends StatefulWidget {
  const HomeProviderPage({super.key});

  @override
  State<HomeProviderPage> createState() => _HomeProviderPageState();
}

class _HomeProviderPageState extends State<HomeProviderPage> {
  Map<String, dynamic>? workshop;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadWorkshop();
  }

  Future<void> _loadWorkshop() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final dio = await Api.client();
      final res = await dio.get('/taller');
      setState(() {
        workshop = res.data as Map?;
      });
    } catch (e) {
      setState(() {
        error = 'Error cargando taller';
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
      appBar: AppBar(title: const Text('Panel del Taller')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(child: Text(error!))
                : workshop == null
                    ? const Center(child: Text('No se encontró taller registrado'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    workshop!['nombreComercial'] ?? 'Taller',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(workshop!['descripcion'] ?? ''),
                                  const SizedBox(height: 8),
                                  if ((workshop!['especialidades'] as List?)?.isNotEmpty ?? false) ...[
                                    const Text('Especialidades:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: (workshop!['especialidades'] as List)
                                          .map<Widget>((e) => Chip(label: Text(e.toString())))
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              ElevatedButton(
                                onPressed: () => context.go('/requests/available'),
                                child: const Text('Solicitudes disponibles'),
                              ),
                              ElevatedButton(
                                onPressed: () => context.go('/requests/assigned'),
                                child: const Text('Solicitudes asignadas'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Selecciona una opción para empezar a trabajar con las solicitudes.',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
      ),
    );
  }
}