import 'package:flutter/material.dart';
import 'package:pruebavercel/theme/app_theme.dart';

class AlertConfigScreen extends StatefulWidget {
  const AlertConfigScreen({super.key});

  @override
  State<AlertConfigScreen> createState() => _AlertConfigScreenState();
}

class _AlertConfigScreenState extends State<AlertConfigScreen> {
  double _alertFrequency = 2.0; // Horas
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _locationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Alertas'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuración de Alertas',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Personaliza cómo y cuándo recibirás las alertas',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Frecuencia de alertas',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cada ${_alertFrequency.toStringAsFixed(1)} horas',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Slider(
                        value: _alertFrequency,
                        min: 0.5,
                        max: 6.0,
                        divisions: 11,
                        label: '${_alertFrequency.toStringAsFixed(1)} h',
                        onChanged: (value) {
                          setState(() {
                            _alertFrequency = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('30 min'),
                          const Text('6 horas'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tipo de notificación',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Sonido'),
                        subtitle: const Text('Alerta con sonido'),
                        value: _soundEnabled,
                        onChanged: (value) {
                          setState(() {
                            _soundEnabled = value;
                          });
                        },
                        secondary: const Icon(Icons.volume_up),
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Vibración'),
                        subtitle: const Text('Alerta con vibración'),
                        value: _vibrationEnabled,
                        onChanged: (value) {
                          setState(() {
                            _vibrationEnabled = value;
                          });
                        },
                        secondary: const Icon(Icons.vibration),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ubicación',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Compartir ubicación'),
                        subtitle: const Text(
                            'Enviar ubicación actual en caso de emergencia'),
                        value: _locationEnabled,
                        onChanged: (value) {
                          setState(() {
                            _locationEnabled = value;
                          });
                        },
                        secondary: const Icon(Icons.location_on),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Guardar configuración
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Configuración guardada'),
                        backgroundColor: AppTheme.secondaryGreen,
                      ),
                    );
                  },
                  child: const Text('Guardar Cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

