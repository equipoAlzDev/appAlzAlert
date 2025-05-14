import 'package:AlzAlert/screens/devices_conection/ble_connection_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:AlzAlert/providers/alert_system_provider.dart';
import 'package:AlzAlert/theme/app_theme.dart'; // Asegúrate de que este archivo exista y contenga AppTheme
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AlertConfigScreen extends StatefulWidget {
  const AlertConfigScreen({super.key});

  @override
  State<AlertConfigScreen> createState() => _AlertConfigScreenState();
}

class _AlertConfigScreenState extends State<AlertConfigScreen> {
  late int _selectedPrimaryIntervalSeconds;
  late int _selectedSecondaryIntervalSeconds;

  final Map<String, int> _primaryIntervalOptions = {
    '1 hora': 3600,
    '2 horas': 7200,
    '3 horas': 10800,
    '4 horas': 14400,
    '5 horas': 18000,
    '6 horas': 21600,
    '7 horas': 25200,
    '8 horas': 28800,
    '9 horas': 32400,
    '10 horas': 36000,
    '20 segundos (Prueba)': 20,
  };

  final Map<String, int> _secondaryIntervalOptions = {
    '5 minutos': 300,
    '10 minutos': 600,
    '15 minutos': 900,
    '20 minutos': 1200,
    '25 minutos': 1500,
    '30 minutos': 1800,
    '10 segundos (Prueba)': 10,
  };

  String _getPrimaryDisplayString(int seconds) {
    return _primaryIntervalOptions.entries
        .firstWhere(
          (entry) => entry.value == seconds,
          orElse: () => _primaryIntervalOptions.entries.first,
        )
        .key;
  }

  String _getSecondaryDisplayString(int seconds) {
    return _secondaryIntervalOptions.entries
        .firstWhere(
          (entry) => entry.value == seconds,
          orElse: () => _secondaryIntervalOptions.entries.first,
        )
        .key;
  }

  @override
  void initState() {
    super.initState();
    final alertSystemProvider = Provider.of<AlertSystemProvider>(
      context,
      listen: false,
    );
    _selectedPrimaryIntervalSeconds =
        alertSystemProvider.configuredPrimaryIntervalSeconds;
    _selectedSecondaryIntervalSeconds =
        alertSystemProvider.configuredSecondaryIntervalSeconds;
  }

  void _saveSettings() {
    final alertSystemProvider = Provider.of<AlertSystemProvider>(
      context,
      listen: false,
    );
    alertSystemProvider.setPrimaryInterval(_selectedPrimaryIntervalSeconds);
    alertSystemProvider.setSecondaryInterval(_selectedSecondaryIntervalSeconds);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Configuración guardada')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Alertas'),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Intervalo de Alerta Principal',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedPrimaryIntervalSeconds,
                      items:
                          _primaryIntervalOptions.entries.map((entry) {
                            return DropdownMenuItem<int>(
                              value: entry.value,
                              child: Text(entry.key),
                            );
                          }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedPrimaryIntervalSeconds = newValue;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar intervalo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Intervalo de Alerta Secundaria',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedSecondaryIntervalSeconds,
                      items:
                          _secondaryIntervalOptions.entries.map((entry) {
                            return DropdownMenuItem<int>(
                              value: entry.value,
                              child: Text(entry.key),
                            );
                          }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedSecondaryIntervalSeconds = newValue;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar intervalo',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: AppTheme.secondaryGreen,
              ),
              child: const Text(
                'Guardar Configuración',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BluetoothConnectionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: const Color.fromARGB(255, 231, 112, 68),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Validar conexión a Bluetooth',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
