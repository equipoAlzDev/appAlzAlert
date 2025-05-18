// lib/screens/history/location_history_screen.dart
import 'package:alzalert/models/location_entry.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alzalert/theme/app_theme.dart';
import 'package:alzalert/providers/location_history_provider.dart'; // Importa el proveedor
import 'package:alzalert/providers/user_provider.dart'; // Importa el proveedor de usuario
import 'package:intl/intl.dart'; // Para formatear fechas, añade a pubspec.yaml si no lo tienes

class LocationHistoryScreen extends StatefulWidget {
  const LocationHistoryScreen({super.key});

  @override
  State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  String _selectedFilter = 'Todos'; // Valor inicial para ver todo

  @override
  void initState() {
    super.initState();
    // Carga el historial de ubicaciones del usuario actual al iniciar la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = Provider.of<UserProvider>(context, listen: false).user?.id ?? '';
      if (userId.isNotEmpty) {
        Provider.of<LocationHistoryProvider>(context, listen: false).fetchLocationHistory(userId);
      }
    });
  }

  List<Map<String, dynamic>> _getFilteredLocations(List<LocationEntry> allLocations) {
    if (_selectedFilter == 'Todos') {
      return allLocations.map((entry) => {
        'address': entry.address,
        'time': DateFormat('hh:mm a').format(entry.timestamp),
        'date': DateFormat('dd/MM/yyyy').format(entry.timestamp), // Formato para el filtro
        'coordinates': {'lat': entry.latitude, 'lng': entry.longitude},
      }).toList();
    } else {
      // Filtra por la fecha seleccionada
      return allLocations
          .where((entry) => DateFormat('dd/MM/yyyy').format(entry.timestamp) == _selectedFilter)
          .map((entry) => {
            'address': entry.address,
            'time': DateFormat('hh:mm a').format(entry.timestamp),
            'date': DateFormat('dd/MM/yyyy').format(entry.timestamp),
            'coordinates': {'lat': entry.latitude, 'lng': entry.longitude},
          })
          .toList();
    }
  }

  // Método para obtener las fechas únicas para el Dropdown
  List<String> _getUniqueDates(List<LocationEntry> allLocations) {
    final List<String> dates = ['Todos'];
    final Set<String> uniqueDates = {};
    for (var entry in allLocations) {
      uniqueDates.add(DateFormat('dd/MM/yyyy').format(entry.timestamp));
    }
    dates.addAll(uniqueDates.toList()..sort((a, b) { // Ordenar las fechas de forma descendente
      try {
        DateTime dateA = DateFormat('dd/MM/yyyy').parse(a);
        DateTime dateB = DateFormat('dd/MM/yyyy').parse(b);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0; // En caso de error, no reordenar
      }
    }));
    return dates;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Ubicaciones'),
      ),
      body: Consumer<LocationHistoryProvider>(
        builder: (context, locationHistoryProvider, child) {
          if (locationHistoryProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allLocations = locationHistoryProvider.locationHistory;
          final filteredLocations = _getFilteredLocations(allLocations);
          final uniqueDates = _getUniqueDates(allLocations);

          // Ajusta el valor del filtro si el filtro actual ya no existe en las fechas disponibles
          if (!uniqueDates.contains(_selectedFilter) && _selectedFilter != 'Todos') {
            _selectedFilter = 'Todos';
          }
          if (uniqueDates.length == 1 && uniqueDates.first != 'Todos') {
            _selectedFilter = uniqueDates.first;
          }


          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text('Filtrar por: '),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedFilter,
                      items: uniqueDates.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFilter = value!;
                        });
                      },
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Implementar exportación de historial
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Funcionalidad de exportar no implementada aún.')),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Exportar'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredLocations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 80,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay ubicaciones registradas para el filtro seleccionado',
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredLocations.length,
                        itemBuilder: (context, index) {
                          final location = filteredLocations[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 25, // Un poco más grande para mejor visibilidad
                                backgroundColor: AppTheme.primaryBlue,
                                child: const Icon(
                                  Icons.location_on,
                                  color: AppTheme.primaryWhite,
                                  size: 28, // Tamaño del icono
                                ),
                              ),
                              title: Text(location['address']),
                              subtitle: Text(
                                  '${location['date']} - ${location['time']}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.map),
                                onPressed: () {
                                  // TODO: Abrir ubicación en mapa
                                  final lat = location['coordinates']['lat'];
                                  final lng = location['coordinates']['lng'];
                                  debugPrint('Abrir mapa para: $lat, $lng');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Funcionalidad de abrir mapa no implementada aún.')),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}