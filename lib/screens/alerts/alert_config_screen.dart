import 'package:alzalert/screens/bluethooth_conection/bluethooth_conection_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alzalert/providers/alert_system_provider.dart';
import 'package:alzalert/theme/app_theme.dart';

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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración guardada'),
        backgroundColor: AppTheme.primaryBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Alertas'),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.blue.shade50],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Configure los tiempos entre alertas para mantener un monitoreo adecuado.',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 255, 255, 255),
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
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Intervalo de Alerta Principal',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Este es el tiempo entre verificaciones iniciales de estado. Recibirás una alerta para confirmar que te encuentras bien después de cada periodo configurado.',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                        decoration: InputDecoration(
                          labelText: 'Seleccionar intervalo',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.access_time),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                margin: const EdgeInsets.only(bottom: 20),
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
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Intervalo de Alerta Secundaria',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Este intervalo se usa cuando no respondes a la primera alerta. Es más corto que el principal y, si no respondes de nuevo, se enviará una alerta de emergencia a tus contactos.',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppTheme.textLight,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                        decoration: InputDecoration(
                          labelText: 'Seleccionar intervalo',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.access_alarm),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.save),
                      SizedBox(width: 8),
                      Text(
                        'Guardar Configuración',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BluetoothConnectionScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color.fromARGB(255, 231, 112, 68),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.bluetooth),
                      SizedBox(width: 8),
                      Text(
                        'Validar conexión a Bluetooth',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
