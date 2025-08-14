import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? car;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadCar();
  }

  Future<void> _loadCar() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final dio = await Api.client();
      final res = await dio.get('/vehiculos');
      final list = res.data as List;
      if (list.isNotEmpty) {
        setState(() {
          car = list[0] as Map<String, dynamic>;
        });
      } else {
        setState(() {
          error = 'No se encontró vehículo registrado';
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error cargando vehículo';
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
      appBar: AppBar(title: const Text('Allprocar')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (loading) const Center(child: CircularProgressIndicator()),
            if (!loading && error != null) Center(child: Text(error!)),
            if (!loading && car != null) ...[
              Card(
                child: ListTile(
                  title: Text('${car!['marca']} ${car!['modelo']}'),
                  subtitle: Text('Año ${car!['anio']}'),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton(
                    onPressed: () => context.go('/request/new'),
                    child: const Text('Nueva solicitud'),
                  ),
                  ElevatedButton(
                    onPressed: () => context.go('/requests'),
                    child: const Text('Historial de servicios'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Bienvenido. Crea una solicitud o revisa tu historial.'),
            ],
          ],
        ),
      ),
    );
  }
}
