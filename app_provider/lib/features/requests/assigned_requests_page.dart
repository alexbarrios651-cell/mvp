import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/api.dart';

/// Página que muestra las solicitudes que han sido asignadas a este taller.
///
/// Se obtienen desde la API usando el parámetro `rol=proveedor`. No se
/// incluye funcionalidad de chat en esta demo, pero se muestra la
/// especialidad, los síntomas y el estado de cada solicitud.
class AssignedRequestsPage extends StatefulWidget {
  const AssignedRequestsPage({super.key});

  @override
  State<AssignedRequestsPage> createState() => _AssignedRequestsPageState();
}

class _AssignedRequestsPageState extends State<AssignedRequestsPage> {
  bool loading = true;
  String? error;
  List<dynamic> items = [];

  @override
  void initState() {
    super.initState();
    _loadAssigned();
  }

  Future<void> _loadAssigned() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final dio = await Api.client();
      final res = await dio.get('/solicitudes', queryParameters: {'rol': 'proveedor'});
      setState(() {
        items = res.data as List;
      });
    } on DioException catch (e) {
      setState(() {
        error = e.response?.data?['error']?.toString() ?? 'Error al cargar solicitudes asignadas';
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
      appBar: AppBar(
        title: const Text('Solicitudes asignadas'),
        actions: [
          IconButton(onPressed: _loadAssigned, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : items.isEmpty
                  ? const Center(child: Text('No tienes solicitudes asignadas.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final s = items[index] as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(s['especialidad'] ?? 'Especialidad'),
                            subtitle: Text('Estado: ${s['estado']}\n${s['sintomas'] ?? ''}'),
                            trailing: Text('ID: ${s['id']}'),
                          ),
                        );
                      },
                    ),
    );
  }
}