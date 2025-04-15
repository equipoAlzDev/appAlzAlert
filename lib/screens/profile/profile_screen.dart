import 'package:flutter/material.dart';
import 'package:pruebavercel/screens/auth/welcome_screen.dart';
import 'package:pruebavercel/screens/contacts/emergency_contacts_screen.dart';
import 'package:pruebavercel/screens/profile/medical_info_screen.dart';
import 'package:pruebavercel/screens/profile/profile_setup_screen.dart';
import 'package:pruebavercel/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final String _name = 'Juan Pérez';
  final String _age = '75';
  final String _address = 'Av. Insurgentes Sur 1602, Ciudad de México';
  final String _profileImageUrl = '';

  void _signOut() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryRed,
              ),
              onPressed: () {
                // Implementar cierre de sesión
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                  (route) => false,
                );
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.divider,
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl)
                          : null,
                      child: _profileImageUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: AppTheme.textLight,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _name,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_age años',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _address,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              _buildProfileOption(
                icon: Icons.person_outline,
                title: 'Editar datos personales',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
                  );
                },
              ),
              _buildProfileOption(
                icon: Icons.medical_information_outlined,
                title: 'Información médica',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MedicalInfoScreen()),
                  );
                },
              ),
              _buildProfileOption(
                icon: Icons.contact_phone_outlined,
                title: 'Contactos de emergencia',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EmergencyContactsScreen()),
                  );
                },
              ),
              _buildProfileOption(
                icon: Icons.settings_outlined,
                title: 'Configuración',
                onTap: () {
                  // Navegar a configuración
                },
              ),
              _buildProfileOption(
                icon: Icons.help_outline,
                title: 'Ayuda y soporte',
                onTap: () {
                  // Navegar a ayuda
                },
              ),
              _buildProfileOption(
                icon: Icons.info_outline,
                title: 'Acerca de',
                onTap: () {
                  // Mostrar información de la app
                },
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _buildProfileOption(
                icon: Icons.logout,
                title: 'Cerrar sesión',
                textColor: AppTheme.secondaryRed,
                onTap: _signOut,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? AppTheme.primaryBlue,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

