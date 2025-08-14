import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/api.dart';

/// Página que muestra las solicitudes del usuario actual (rol cliente).
///
/// Esta vista recupera las solicitudes desde el backend usando el token
/// guardado en SharedPreferences. Se solicita el parámetro `rol=cliente` para
/// que el backend devuelva las solicitudes asociadas al usuario actual. Se
/// muestra una lista con el estado y la especialidad de cada solicitud. Un
/// botón en la AppBar permite recargar los datos.
class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  List<dynamic> items = [];
  bool loading = true;
  String? error;

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final dio = await Api.client();
      final res = await dio.get('/solicitudes', queryParameters: {'rol': 'cliente'});
      setState(() {
        items = res.data as List;
      });
    } on DioException catch (e) {
      setState(() {
        error = e.response?.data?['error']?.toString() ?? 'Error al cargar solicitudes';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis solicitudes'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : items.isEmpty
                  ? const Center(child: Text('No tienes solicitudes aún.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(item['especialidad'] ?? 'Especialidad'),
                            subtitle: Text('Estado: ${item['estado']}'),
                            trailing: Text('ID: ${item['id']}'),
                          ),
                        );
                      },
                    ),
    );
  }
}