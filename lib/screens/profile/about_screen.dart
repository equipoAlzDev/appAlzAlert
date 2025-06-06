import 'package:flutter/material.dart';
import 'package:alzalert/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca de'),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.blue.shade50],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 120,
                    height: 120,
                    color: AppTheme.primaryBlue,
                    child: const Icon(
                      Icons.notification_important,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'AlzAlert',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Versión 1.0.0',
                style: TextStyle(fontSize: 16, color: AppTheme.textLight),
              ),
              const SizedBox(height: 40),
              _buildInfoCard(
                title: '¿Qué es AlzAlert?',
                content:
                    'AlzAlert es una aplicación diseñada para ayudar a personas con Alzheimer y sus cuidadores. Permite monitorear al usuario mediante verificaciones periódicas y enviar alertas a contactos de emergencia cuando sea necesario.',
              ),
              _buildInfoCard(
                title: 'Características',
                content:
                    '• Monitoreo periódico mediante alertas\n'
                    '• Configuración de intervalos de verificación\n'
                    '• Registro de ubicación para emergencias\n'
                    '• Contactos de emergencia personalizables',
              ),
              _buildInfoCard(
                title: 'Información de contacto',
                content:
                    'Para soporte o más información:\n'
                    'Email: equipoalzalert@gmail.com',
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  '© 2025 AlzAlert. Todos los derechos reservados.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
