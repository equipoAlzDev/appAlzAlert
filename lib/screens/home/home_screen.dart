import 'package:flutter/material.dart';
import 'package:pruebavercel/screens/alerts/alert_config_screen.dart';
import 'package:pruebavercel/screens/contacts/emergency_contacts_screen.dart';
import 'package:pruebavercel/screens/history/location_history_screen.dart';
import 'package:pruebavercel/screens/notifications/notifications_screen.dart';
import 'package:pruebavercel/screens/profile/profile_screen.dart';
import 'package:pruebavercel/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isAlertSystemActive = true;

  final List<Widget> _screens = [
    const MainHomeScreen(),
    const LocationHistoryScreen(),
    const AlertConfigScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryBlue,
        unselectedItemColor: AppTheme.textLight,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'Ubicaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Alertas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            activeIcon: Icon(Icons.message),
            label: 'Notificaciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  bool _isAlertSystemActive = true;

  void _toggleAlertSystem() {
    setState(() {
      _isAlertSystemActive = !_isAlertSystemActive;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isAlertSystemActive
              ? 'Sistema de alertas activado'
              : 'Sistema de alertas desactivado',
        ),
        backgroundColor:
            _isAlertSystemActive ? AppTheme.secondaryGreen : AppTheme.secondaryRed,
      ),
    );
  }

  void _showEmergencyConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Emergencia'),
          content: const Text('¿Enviar alerta a tus contactos de emergencia?'),
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
                // Implementar envío de alerta
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alerta enviada a tus contactos de emergencia'),
                    backgroundColor: AppTheme.secondaryRed,
                  ),
                );
              },
              child: const Text('Enviar Alerta'),
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
        title: const Text('Alzheimer Care'),
        actions: [
          Switch(
            value: _isAlertSystemActive,
            onChanged: (value) => _toggleAlertSystem(),
            activeColor: AppTheme.secondaryGreen,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppTheme.primaryBlue,
                        child: const Icon(
                          Icons.person,
                          size: 30,
                          color: AppTheme.primaryWhite,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bienvenido, Usuario',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  _isAlertSystemActive
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _isAlertSystemActive
                                      ? AppTheme.secondaryGreen
                                      : AppTheme.secondaryRed,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isAlertSystemActive
                                      ? 'Sistema activo'
                                      : 'Sistema inactivo',
                                  style: TextStyle(
                                    color: _isAlertSystemActive
                                        ? AppTheme.secondaryGreen
                                        : AppTheme.secondaryRed,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _showEmergencyConfirmation,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryRed,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.secondaryRed.withOpacity(0.3),
                                spreadRadius: 10,
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'EMERGENCIA',
                              style: TextStyle(
                                color: AppTheme.primaryWhite,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Presiona el botón en caso de emergencia',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isAlertSystemActive)
                Card(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sistema de alertas activo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Recibirás alertas periódicas para verificar tu estado',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ],
                          ),
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

