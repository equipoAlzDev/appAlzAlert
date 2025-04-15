import 'package:flutter/material.dart';
import 'package:pruebavercel/theme/app_theme.dart';

class LockScreenInfo extends StatefulWidget {
  const LockScreenInfo({super.key});

  @override
  State<LockScreenInfo> createState() => _LockScreenInfoState();
}

class _LockScreenInfoState extends State<LockScreenInfo> {
  int _remainingSeconds = 600; // 10 minutos

  @override
  void initState() {
    super.initState();
    // Iniciar temporizador
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Center(
                child: Icon(
                  Icons.medical_information,
                  size: 80,
                  color: AppTheme.secondaryRed,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'INFORMACIÓN MÉDICA',
                  style: TextStyle(
                    color: AppTheme.primaryWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              _buildInfoSection('Nombre:', 'Juan Pérez'),
              _buildInfoSection('Diagnóstico:', 'Alzheimer avanzado'),
              _buildInfoSection('Alergias:', 'Penicilina, Aspirina'),
              _buildInfoSection('Medicamentos:', 'Donepezilo, Memantina'),
              _buildInfoSection('Contacto de emergencia:', 'María Pérez (Hija) - 555-123-4567'),
              const SizedBox(height: 48),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Si no hay respuesta en:',
                      style: TextStyle(
                        color: AppTheme.primaryWhite,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        color: AppTheme.secondaryRed,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Se notificará a los contactos de emergencia',
                      style: TextStyle(
                        color: AppTheme.primaryWhite,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Responder a la alerta
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryGreen,
                  ),
                  child: const Text(
                    'Estoy bien',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.primaryWhite.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.primaryWhite,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

