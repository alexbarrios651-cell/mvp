import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/api.dart';

class RequestNewPage extends StatefulWidget {
  const RequestNewPage({super.key});

  @override
  State<RequestNewPage> createState() => _RequestNewPageState();
}

class _RequestNewPageState extends State<RequestNewPage> {
  // Mantenemos la lista de vehículos aunque solo usemos el primero para
  // poder asignar automáticamente el ID al crear la solicitud. La API
  // devuelve una lista y extraemos el primer elemento en [_loadVehicles].
  List<dynamic> vehicles = [];
  // Estructura de especialidades agrupadas por categoría. Se llena al cargar
  // datos del catálogo desde el backend.
  Map<String, List<dynamic>> specialties = {};
  // Vehículo predeterminado cargado desde el backend. Es el primer
  // vehículo asociado al usuario y se muestra en la UI.
  Map<String, dynamic>? car;
  // ID del vehículo seleccionado; se asigna automáticamente en
  // [_loadVehicles] y no se presenta al usuario en un dropdown.
  String? selectedVehicle;
  // Valor de la especialidad seleccionada por el usuario en el dropdown.
  String? selectedSpecialty;
  // Controlador para capturar la descripción de los síntomas ingresados.
  final sintomas = TextEditingController();
  // Mensaje informativo o de error tras crear una solicitud.
  String? info;

  Future<void> _loadVehicles() async {
    final dio = await Api.client();
    final res = await dio.get('/vehiculos');
    setState(() {
      vehicles = res.data as List;
      if (vehicles.isNotEmpty) {
        car = vehicles.first as Map<String, dynamic>;
        selectedVehicle = car!['id'];
      }
    });
  }

  Future<void> _loadSpecialties() async {
    final dio = await Api.client();
    final res = await dio.get('/catalog/specialties');
    setState(() { specialties = Map<String, List<dynamic>>.from(res.data as Map); });
  }

  Future<Position> _getPosition() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return Geolocator.getCurrentPosition();
  }

  Future<void> _createRequest() async {
    if (selectedVehicle == null || selectedSpecialty == null || sintomas.text.isEmpty) {
      setState(() { info = 'Selecciona vehículo, especialidad y describe los síntomas.'; });
      return;
    }
    final pos = await _getPosition();
    final dio = await Api.client();
    final res = await dio.post('/solicitudes', data: {
      'idVehiculo': selectedVehicle,
      'especialidad': selectedSpecialty,
      'sintomas': sintomas.text,
      'geo': { 'lat': pos.latitude, 'lng': pos.longitude }
    });
    setState(() { info = 'Solicitud creada: ${res.data['id']}'; });
  }

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _loadSpecialties();
  }

  @override
  Widget build(BuildContext context) {
    final flatSpecs = specialties.entries.expand((e) => e.value.map((v) => {'group': e.key, 'value': v['value'], 'label': v['label']})).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva solicitud')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Muestra el vehículo predeterminado en lugar de un selector. Si
            // todavía no se ha cargado ningún vehículo, se muestra un
            // indicador de carga o un mensaje de error.
            if (car == null) ...[
              const Text('Cargando vehículo...', style: TextStyle(fontStyle: FontStyle.italic)),
              const SizedBox(height: 12),
            ] else ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.directions_car),
                  title: Text('${car!['marca']} ${car!['modelo']}'),
                  subtitle: Text('Año ${car!['anio']}'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Selector de especialidad. El usuario elige la categoría de
            // servicio. Se muestran las etiquetas y grupos en el dropdown.
            DropdownButtonFormField<String>(
              value: selectedSpecialty,
              items: flatSpecs
                  .map((s) => DropdownMenuItem<String>(
                        value: s['value'] as String,
                        child: Text('${s['label']} (${s['group']})'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => selectedSpecialty = v),
              decoration: const InputDecoration(labelText: 'Especialidad'),
            ),
            const SizedBox(height: 12),
            // Campo de texto para describir síntomas o problemas del vehículo.
            TextField(
              controller: sintomas,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Síntomas / descripción'),
            ),
            const SizedBox(height: 12),
            // Botón para crear la solicitud. Invoca [_createRequest].
            ElevatedButton(onPressed: _createRequest, child: const Text('Crear solicitud')),
            // Muestra mensajes de estado después de intentar crear la solicitud.
            if (info != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  info!,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
