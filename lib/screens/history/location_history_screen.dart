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
      final userId =
          Provider.of<UserProvider>(context, listen: false).user?.id ?? '';
      if (userId.isNotEmpty) {
        Provider.of<LocationHistoryProvider>(
          context,
          listen: false,
        ).fetchLocationHistory(userId);
      }
    });
  }

  List<Map<String, dynamic>> _getFilteredLocations(
    List<LocationEntry> allLocations,
  ) {
    if (_selectedFilter == 'Todos') {
      return allLocations
          .map(
            (entry) => {
              'address': entry.address,
              'time': DateFormat('hh:mm a').format(entry.timestamp),
              'date': DateFormat(
                'dd/MM/yyyy',
              ).format(entry.timestamp), // Formato para el filtro
              'timestamp': entry.timestamp, // Añadimos timestamp para ordenar
              'coordinates': {'lat': entry.latitude, 'lng': entry.longitude},
            },
          )
          .toList()
        ..sort(
          (a, b) => (b['timestamp'] as DateTime).compareTo(
            a['timestamp'] as DateTime,
          ),
        ); // Ordenamos de más reciente a más antiguo
    } else {
      // Filtra por la fecha seleccionada
      return allLocations
          .where(
            (entry) =>
                DateFormat('dd/MM/yyyy').format(entry.timestamp) ==
                _selectedFilter,
          )
          .map(
            (entry) => {
              'address': entry.address,
              'time': DateFormat('hh:mm a').format(entry.timestamp),
              'date': DateFormat('dd/MM/yyyy').format(entry.timestamp),
              'timestamp': entry.timestamp, // Añadimos timestamp para ordenar
              'coordinates': {'lat': entry.latitude, 'lng': entry.longitude},
            },
          )
          .toList()
        ..sort(
          (a, b) => (b['timestamp'] as DateTime).compareTo(
            a['timestamp'] as DateTime,
          ),
        ); // Ordenamos de más reciente a más antiguo
    }
  }

  // Método para obtener las fechas únicas para el Dropdown
  List<String> _getUniqueDates(List<LocationEntry> allLocations) {
    final List<String> dates = ['Todos'];
    final Set<String> uniqueDates = {};
    for (var entry in allLocations) {
      uniqueDates.add(DateFormat('dd/MM/yyyy').format(entry.timestamp));
    }
    dates.addAll(
      uniqueDates.toList()..sort((a, b) {
        // Ordenar las fechas de forma descendente
        try {
          DateTime dateA = DateFormat('dd/MM/yyyy').parse(a);
          DateTime dateB = DateFormat('dd/MM/yyyy').parse(b);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0; // En caso de error, no reordenar
        }
      }),
    );
    return dates;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Ubicaciones'),
        backgroundColor: AppTheme.primaryBlue, // Mantenemos el encabezado verde
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.blue.shade50],
          ),
        ),
        child: Consumer<LocationHistoryProvider>(
          builder: (context, locationHistoryProvider, child) {
            if (locationHistoryProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final allLocations = locationHistoryProvider.locationHistory;
            final filteredLocations = _getFilteredLocations(allLocations);
            final uniqueDates = _getUniqueDates(allLocations);

            // Ajusta el valor del filtro si el filtro actual ya no existe en las fechas disponibles
            if (!uniqueDates.contains(_selectedFilter) &&
                _selectedFilter != 'Todos') {
              _selectedFilter = 'Todos';
            }
            if (uniqueDates.length == 1 && uniqueDates.first != 'Todos') {
              _selectedFilter = uniqueDates.first;
            }

            return Column(
              children: [
                // Sección de filtro mejorada
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filtrar por fecha',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedFilter,
                            isExpanded: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: AppTheme.primaryBlue,
                            ),
                            items:
                                uniqueDates.map<DropdownMenuItem<String>>((
                                  String value,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedFilter = value!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenido principal
                Expanded(
                  child:
                      filteredLocations.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.location_off,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: Text(
                                    'No hay ubicaciones registradas para el filtro seleccionado',
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(color: AppTheme.textLight),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredLocations.length,
                            itemBuilder: (context, index) {
                              final location = filteredLocations[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withOpacity(
                                        0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: AppTheme.primaryBlue,
                                      size: 28,
                                    ),
                                  ),
                                  title: Text(
                                    location['address'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: AppTheme.textLight,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          location['date'],
                                          style: const TextStyle(
                                            color: AppTheme.textLight,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: AppTheme.textLight,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          location['time'],
                                          style: const TextStyle(
                                            color: AppTheme.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Se eliminó el icono de mapa
                                ),
                              );
                            },
                          ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
