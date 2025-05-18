import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alzalert/providers/alert_system_provider.dart';
import 'package:alzalert/theme/app_theme.dart'; // Asegúrate de que este archivo exista y contenga AppTheme

class AlertConfigScreen extends StatefulWidget {
  const AlertConfigScreen({super.key});

  @override
  State<AlertConfigScreen> createState() => _AlertConfigScreenState();
}

class _AlertConfigScreenState extends State<AlertConfigScreen> {
  // State variables to hold the selected values from the dropdowns
  // These will be initialized with the current provider values in initState
  late int _selectedPrimaryIntervalSeconds;
  late int _selectedSecondaryIntervalSeconds;

  // Options for the primary interval dropdown (mapping display text to seconds)
  // Removed the "Test" option
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
    '20 segundos (Prueba)': 20, // Kept test option for development flexibility
  };

  // Options for the secondary interval dropdown (mapping display text to seconds)
  // Removed the "Test" option
  final Map<String, int> _secondaryIntervalOptions = {
    '5 minutos': 300,
    '10 minutos': 600,
    '15 minutos': 900,
    '20 minutos': 1200,
    '25 minutos': 1500,
    '30 minutos': 1800,
    '10 segundos (Prueba)': 10, // Kept test option for development flexibility
  };

  // Helper to get the display string for a given primary interval in seconds
  String _getPrimaryDisplayString(int seconds) {
    return _primaryIntervalOptions.entries
        .firstWhere((entry) => entry.value == seconds,
            // Provide a default in case the current value isn't in the list (shouldn't happen if saved values are valid)
            orElse: () => _primaryIntervalOptions.entries.first)
        .key;
  }

  // Helper to get the display string for a given secondary interval in seconds
  String _getSecondaryDisplayString(int seconds) {
    return _secondaryIntervalOptions.entries
        .firstWhere((entry) => entry.value == seconds,
            orElse: () => _secondaryIntervalOptions.entries.first)
        .key;
  }

  @override
  void initState() {
    super.initState();
    // Initialize the state variables with the current values from the provider
    final alertSystemProvider = Provider.of<AlertSystemProvider>(context, listen: false);
    _selectedPrimaryIntervalSeconds = alertSystemProvider.configuredPrimaryIntervalSeconds;
    _selectedSecondaryIntervalSeconds = alertSystemProvider.configuredSecondaryIntervalSeconds;
  }

  // Function to save the selected settings to the provider
  void _saveSettings() {
    final alertSystemProvider = Provider.of<AlertSystemProvider>(context, listen: false);
    alertSystemProvider.setPrimaryInterval(_selectedPrimaryIntervalSeconds);
    alertSystemProvider.setSecondaryInterval(_selectedSecondaryIntervalSeconds);

    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración guardada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Alertas'),
        backgroundColor: AppTheme.primaryBlue, // Usa el color primario de tu tema
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView( // Use ListView for scrolling if content overflows
          children: [
            // Card for Primary Alert Configuration
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiempo para Alerta Principal',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Selecciona el tiempo antes de que se active la alerta principal:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    // Dropdown to select primary interval
                    DropdownButtonFormField<int>(
                      value: _selectedPrimaryIntervalSeconds,
                      items: _primaryIntervalOptions.entries.map((entry) {
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

            // Card for Secondary Alert Configuration
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiempo para Alerta Secundaria',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Selecciona el tiempo antes de que se active la alerta Secundaria:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    // Dropdown to select secondary interval
                    DropdownButtonFormField<int>(
                      value: _selectedSecondaryIntervalSeconds,
                      items: _secondaryIntervalOptions.entries.map((entry) {
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

            // Button to save all configurations
            Center(
              child: Container(
                width: 300, // Ancho específico en píxeles
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Guardar Configuración',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
