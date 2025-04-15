import 'package:flutter/material.dart';
import 'package:pruebavercel/theme/app_theme.dart';

class LocationHistoryScreen extends StatefulWidget {
  const LocationHistoryScreen({super.key});

  @override
  State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'Hoy';

  final List<Map<String, dynamic>> _locationHistory = [
    {
      'address': 'Av. Insurgentes Sur 1602, Ciudad de México',
      'time': '10:30 AM',
      'date': 'Hoy',
      'coordinates': {'lat': 19.3833, 'lng': -99.1833},
    },
    {
      'address': 'Paseo de la Reforma 222, Ciudad de México',
      'time': '2:45 PM',
      'date': 'Ayer',
      'coordinates': {'lat': 19.4333, 'lng': -99.1333},
    },
    {
      'address': 'Calle Madero 1, Centro Histórico, Ciudad de México',
      'time': '5:15 PM',
      'date': 'Ayer',
      'coordinates': {'lat': 19.4333, 'lng': -99.1333},
    },
    {
      'address': 'Av. Universidad 3000, Ciudad de México',
      'time': '11:20 AM',
      'date': '12/04/2023',
      'coordinates': {'lat': 19.3333, 'lng': -99.2333},
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredLocations() {
    if (_selectedFilter == 'Todos') {
      return _locationHistory;
    } else {
      return _locationHistory
          .where((location) => location['date'] == _selectedFilter)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLocations = _getFilteredLocations();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Ubicaciones'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mapa'),
            Tab(text: 'Lista'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('Filtrar por: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedFilter,
                  items: const [
                    DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                    DropdownMenuItem(value: 'Hoy', child: Text('Hoy')),
                    DropdownMenuItem(value: 'Ayer', child: Text('Ayer')),
                    DropdownMenuItem(value: '12/04/2023', child: Text('12/04/2023')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                  },
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    // Implementar exportación de historial
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Exportar'),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pestaña de Mapa
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map,
                        size: 100,
                        color: AppTheme.textLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Mapa de ubicaciones',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Aquí se mostrará el mapa con las ubicaciones registradas',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // Pestaña de Lista
                filteredLocations.isEmpty
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
                              'No hay ubicaciones registradas',
                              style: Theme.of(context).textTheme.bodyLarge,
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
                                backgroundColor: AppTheme.primaryBlue,
                                child: const Icon(
                                  Icons.location_on,
                                  color: AppTheme.primaryWhite,
                                ),
                              ),
                              title: Text(location['address']),
                              subtitle: Text(
                                  '${location['date']} - ${location['time']}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.map),
                                onPressed: () {
                                  // Abrir ubicación en mapa
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

