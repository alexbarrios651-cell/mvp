import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/api.dart';

/// Página que muestra las solicitudes abiertas disponibles para el taller.
///
/// Filtra las solicitudes por las especialidades del taller. Permite
/// ofrecer un presupuesto y tiempo estimado para cada solicitud. Al
/// enviar una oferta, la solicitud desaparece de la lista local.
class AvailableRequestsPage extends StatefulWidget {
  const AvailableRequestsPage({super.key});

  @override
  State<AvailableRequestsPage> createState() => _AvailableRequestsPageState();
}

class _AvailableRequestsPageState extends State<AvailableRequestsPage> {
  bool loading = true;
  String? error;
  List<dynamic> items = [];
  List<String> specialties = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final dio = await Api.client();
      // Obtener taller para saber especialidades
      final tRes = await dio.get('/taller');
      final t = tRes.data as Map?;
      specialties = (t?['especialidades'] as List?)?.map<String>((e) => e.toString()).toList() ?? [];
      // Obtener todas las solicitudes
      final solRes = await dio.get('/solicitudes');
      final List<dynamic> sols = solRes.data as List;
      final filtered = sols.where((s) => s['estado'] == 'abierta' && specialties.contains(s['especialidad'])).toList();
      // Opcional: ordenar por fecha (más recientes primero)
      filtered.sort((a, b) => DateTime.parse(b['createdAt']).compareTo(DateTime.parse(a['createdAt'])));
      setState(() {
        items = filtered;
      });
    } on DioException catch (e) {
      setState(() {
        error = e.response?.data?['error']?.toString() ?? 'Error al cargar solicitudes';
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

  Future<void> _offer(Map<String, dynamic> solicitud) async {
    final precioCtrl = TextEditingController();
    final tiempoCtrl = TextEditingController();
    final mensajeCtrl = TextEditingController();
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear oferta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: precioCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Precio (ARS)'),
            ),
            TextField(
              controller: tiempoCtrl,
              decoration: const InputDecoration(labelText: 'Tiempo estimado (días)'),
            ),
            TextField(
              controller: mensajeCtrl,
              decoration: const InputDecoration(labelText: 'Mensaje opcional'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop({
                'precio': double.tryParse(precioCtrl.text) ?? 0,
                'tiempo': tiempoCtrl.text,
                'mensaje': mensajeCtrl.text,
              });
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (result != null) {
      try {
        final dio = await Api.client();
        await dio.post('/ofertas', data: {
          'idSolicitud': solicitud['id'],
          'precio': result['precio'],
          'tiempoEstimado': result['tiempo'],
          'mensaje': result['mensaje'],
        });
        // Eliminar de la lista local
        setState(() {
          items.removeWhere((s) => s['id'] == solicitud['id']);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Oferta enviada')),);
      } on DioException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar oferta: ${e.response?.data?['error'] ?? e.message}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitudes disponibles'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : items.isEmpty
                  ? const Center(child: Text('No hay solicitudes disponibles.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final s = items[index] as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(s['especialidad'] ?? 'Especialidad'),
                            subtitle: Text(s['sintomas'] ?? ''),
                            trailing: ElevatedButton(
                              onPressed: () => _offer(s),
                              child: const Text('Ofertar'),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}