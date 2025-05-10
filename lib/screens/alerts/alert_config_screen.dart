import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:AlzAlert/providers/alert_system_provider.dart';
import 'package:AlzAlert/theme/app_theme.dart';

class AlertConfigScreen extends StatefulWidget {
  const AlertConfigScreen({super.key});

  @override
  State<AlertConfigScreen> createState() => _AlertConfigScreenState();
}

class _AlertConfigScreenState extends State<AlertConfigScreen> {
  late int _selectedPrimaryInterval;   // Intervalo principal seleccionado en segundos
  late int _selectedSecondaryInterval; // Intervalo secundario seleccionado en segundos

  // Opciones de intervalo principal (texto -> segundos)
  final Map<String, int> _primaryOptions = {
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

  // Opciones de intervalo secundario (texto -> segundos)
  final Map<String, int> _secondaryOptions = {
    '5 minutos': 300,
    '10 minutos': 600,
    '15 minutos': 900,
    '20 minutos': 1200,
    '25 minutos': 1500,
    '30 minutos': 1800,
    '10 segundos (Prueba)': 10,
  };

  @override
  void initState() {
    super.initState();
    // Inicializar valores actuales desde el proveedor
    final provider = Provider.of<AlertSystemProvider>(context, listen: false);
    _selectedPrimaryInterval = provider.configuredPrimaryIntervalSeconds;
    _selectedSecondaryInterval = provider.configuredSecondaryIntervalSeconds;
  }

  /// Guarda las configuraciones seleccionadas en el proveedor
  void _saveSettings() {
    final provider = Provider.of<AlertSystemProvider>(context, listen: false);
    provider.setPrimaryInterval(_selectedPrimaryInterval);
    provider.setSecondaryInterval(_selectedSecondaryInterval);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración guardada')),  
    );
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
            // Configuración de alerta principal
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Intervalo de Alerta Principal', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedPrimaryInterval,
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar intervalo',
                        border: OutlineInputBorder(),
                      ),
                      items: _primaryOptions.entries.map((entry) => DropdownMenuItem<int>(
                        value: entry.value,
                        child: Text(entry.key),
                      )).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedPrimaryInterval = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Configuración de alerta secundaria
            Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Intervalo de Alerta Secundaria', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      value: _selectedSecondaryInterval,
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar intervalo',
                        border: OutlineInputBorder(),
                      ),
                      items: _secondaryOptions.entries.map((entry) => DropdownMenuItem<int>(
                        value: entry.value,
                        child: Text(entry.key),
                      )).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedSecondaryInterval = value);
                      },
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
              child: const Text('Guardar Configuración', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
