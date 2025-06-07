import 'package:alzalert/providers/alert_system_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alzalert/screens/auth/welcome_screen.dart';
import 'package:alzalert/screens/contacts/emergency_contacts_screen.dart';
import 'package:alzalert/screens/profile/medical_info_screen.dart';
import 'package:alzalert/screens/profile/profile_setup_screen.dart';
import 'package:alzalert/screens/profile/about_screen.dart';
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'Mi Perfil',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            elevation: 0,
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
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Sección superior - Cabecera con foto
                Container(
                  color: AppTheme.primaryBlue,
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      // Avatar con efecto de borde
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
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
                                    size: 50,
                                    color: AppTheme.primaryBlue,
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Nombre del usuario
                      Text(
                        user.name.isNotEmpty
                            ? user.name
                            : 'Nombre no disponible',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (ageText.isNotEmpty || user.address.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 5, bottom: 20),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (ageText.isNotEmpty) ...[
                                const Icon(
                                  Icons.cake,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  ageText,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                              if (ageText.isNotEmpty && user.address.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  height: 12,
                                  width: 1,
                                  color: Colors.white30,
                                ),
                              if (user.address.isNotEmpty) ...[
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    user.address.length > 20
                                        ? '${user.address.substring(0, 20)}...'
                                        : user.address,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),

                // Sección de opciones
                Container(
                  padding: const EdgeInsets.only(top: 15, left: 15, right: 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 12),
                        child: Text(
                          'Información personal',
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      _buildModernProfileOption(
                        icon: Icons.person_outline,
                        title: 'Datos personales',
                        onTap: () {
                          final userProvider = Provider.of<UserProvider>(
                            context,
                            listen: false,
                          );
                          userProvider.setNavigationContext(
                            NavigationContext.editing,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileSetupScreen(),
                            ),
                          );
                        },
                      ),
                      _buildModernProfileOption(
                        icon: Icons.medical_information_outlined,
                        title: 'Información médica',
                        onTap: () {
                          final userProvider = Provider.of<UserProvider>(
                            context,
                            listen: false,
                          );
                          userProvider.setNavigationContext(
                            NavigationContext.editing,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MedicalInfoScreen(),
                            ),
                          );
                        },
                      ),
                      _buildModernProfileOption(
                        icon: Icons.contact_phone_outlined,
                        title: 'Contactos de emergencia',
                        onTap: () {
                          final userProvider = Provider.of<UserProvider>(
                            context,
                            listen: false,
                          );
                          userProvider.setNavigationContext(
                            NavigationContext.editing,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const EmergencyContactsScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      const Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 12),
                        child: Text(
                          'Información adicional',
                          style: TextStyle(
                            color: AppTheme.textLight,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      _buildModernProfileOption(
                        icon: Icons.info_outline,
                        title: 'Acerca de la aplicación',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      // Botón de cerrar sesión
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          width: 300,
                          height: 50,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.logout),
                            label: const Text('Cerrar sesión'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryRed
                                  .withOpacity(0.8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: _signOut,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            spreadRadius: 0.5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          size: 22,
          color: AppTheme.textLight,
        ),
        onTap: onTap,
      ),
    );
  }
}
