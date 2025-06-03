import 'package:alzalert/providers/alert_system_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alzalert/screens/auth/welcome_screen.dart';
import 'package:alzalert/screens/contacts/emergency_contacts_screen.dart';
import 'package:alzalert/screens/profile/medical_info_screen.dart';
import 'package:alzalert/screens/profile/profile_setup_screen.dart';
import 'package:alzalert/theme/app_theme.dart';
import 'package:alzalert/providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
              onPressed: () async {
                Navigator.of(context).pop(); // Cerrar el diálogo
                // Cerrar sesión en Firebase

                // Se cancelan las alertas
                Provider.of<AlertSystemProvider>(
                  context,
                  listen: false,
                ).stopAlertSystem();

                await FirebaseAuth.instance.signOut();
                // Limpiar el estado del usuario en el provider
                Provider.of<UserProvider>(context, listen: false).clearUser();
                // Navegar a la pantalla de bienvenida
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WelcomeScreen(),
                  ),
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
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.user;
        // Mostrar indicador si todavía carga datos
        if (userProvider.isLoading && user.name.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Calcular edad a partir de birthDate
        String ageText = '';
        if (user.birthDate != null) {
          final now = DateTime.now();
          int years = now.year - user.birthDate!.year;
          if (now.month < user.birthDate!.month ||
              (now.month == user.birthDate!.month &&
                  now.day < user.birthDate!.day)) {
            years--;
          }
          ageText = '$years años';
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Perfil')),
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
                          backgroundImage:
                              user.profileImageUrl != null &&
                                      user.profileImageUrl!.isNotEmpty
                                  ? NetworkImage(user.profileImageUrl!)
                                  : null,
                          child:
                              (user.profileImageUrl == null ||
                                      user.profileImageUrl!.isEmpty)
                                  ? const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: AppTheme.textLight,
                                  )
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.name.isNotEmpty
                              ? user.name
                              : 'Nombre no disponible',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ageText,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.address.isNotEmpty
                              ? user.address
                              : 'Dirección no disponible',
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
                        MaterialPageRoute(
                          builder: (context) => const ProfileSetupScreen(),
                        ),
                      );
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.medical_information_outlined,
                    title: 'Información médica',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MedicalInfoScreen(),
                        ),
                      );
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.contact_phone_outlined,
                    title: 'Contactos de emergencia',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmergencyContactsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.settings_outlined,
                    title: 'Configuración',
                    onTap: () {
                      // Acción de configuración
                    },
                  ),
                  _buildProfileOption(
                    icon: Icons.help_outline,
                    title: 'Ayuda y soporte',
                    onTap: () {
                      // Acción de ayuda
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
      },
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppTheme.primaryBlue),
      title: Text(title, style: TextStyle(color: textColor, fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
