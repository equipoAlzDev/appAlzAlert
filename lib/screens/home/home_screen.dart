import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:AlzAlert/providers/alert_system_provider.dart';
import 'package:AlzAlert/providers/user_provider.dart';
import 'package:AlzAlert/screens/alerts/alert_config_screen.dart';
import 'package:AlzAlert/screens/history/location_history_screen.dart';
import 'package:AlzAlert/screens/notifications/notifications_screen.dart';
import 'package:AlzAlert/screens/profile/profile_screen.dart';
import 'package:AlzAlert/theme/app_theme.dart';
import 'package:telephony/telephony.dart';

import '../../providers/contacto_emergencia_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Carga inicial de datos del usuario
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUserData();
    });
  }

  // Updated the index for AlertConfigScreen based on your provided list
  final List<Widget> _screens = [
    const MainHomeScreen(),
    const LocationHistoryScreen(),
    const AlertConfigScreen(), // Index 2 for AlertConfigScreen
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
          // Corrected label to 'Config. Alertas' or similar if it's the config screen
          BottomNavigationBarItem(
             icon: Icon(Icons.settings_outlined),
             activeIcon: Icon(Icons.settings),
             label: 'Config. Alertas',
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
  bool _isSendingSMS = false;
  bool _contactosCargados = false;
  final Telephony telephony = Telephony.instance;
  final String _emergencyNumber = "3157042961";

  @override
  void initState() {
    super.initState();
    _initializeTelephony();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = Provider.of<UserProvider>(context, listen: false).user?.id ?? '';
      if (userId.isNotEmpty) {
        await Provider.of<ContactoEmergenciaProvider>(context, listen: false)
            .cargarContactos(userId);
        if (mounted) {
          setState(() {
            _contactosCargados = true;
          });
        }
      }
    });
  }

  Future<void> _initializeTelephony() async {
    // Verificar si el dispositivo puede enviar SMS
    // Request permissions here or earlier in your app lifecycle (recommended)
    final bool? canSendSms = await telephony.requestPhoneAndSmsPermissions;
    if (canSendSms != true) {
      debugPrint('El dispositivo no puede enviar SMS o permisos no concedidos.');
      // Consider showing a persistent message to the user if permissions are denied.
    }
  }

  // Corrected: Removed BuildContext argument from the call to toggleAlertSystem
  void _toggleAlertSystem(BuildContext context) {
    final alertSystemProvider = Provider.of<AlertSystemProvider>(context, listen: false);
    alertSystemProvider.toggleAlertSystem(); // Removed context argument

    // The context is still needed here for showing the SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          alertSystemProvider.isAlertSystemActive
              ? 'Sistema de alertas activado'
              : 'Sistema de alertas desactivado',
        ),
        backgroundColor: alertSystemProvider.isAlertSystemActive
            ? AppTheme.secondaryGreen
            : AppTheme.secondaryRed,
      ),
    );
  }

  Future<void> _sendEmergencySMS() async {
    // Verificar si el sistema está activo antes de continuar
    final alertSystemProvider = Provider.of<AlertSystemProvider>(context, listen: false);
    if (!alertSystemProvider.isAlertSystemActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sistema de alertas desactivado. No se puede enviar la alerta.'),
          backgroundColor: AppTheme.secondaryRed,
        ),
      );
      return;
    }

    setState(() {
      _isSendingSMS = true;
    });

    try {
      // Verificar permisos
      if (!await _checkSMSPermissions()) {
         // _checkSMSPermissions already shows a SnackBar if permissions are denied
        return;
      }

      // Obtener nombre del usuario
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userName = userProvider.user?.name ?? '';
      final userId = userProvider.user?.id ?? '';

      if (userId.isEmpty) {
         debugPrint('Error: User ID is empty. Cannot send emergency SMS.');
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Error: Usuario no identificado para enviar SMS.'),
               backgroundColor: AppTheme.secondaryRed,
               ),
             );
          }
          return;
      }

      // Obtener contactos de emergencia
      final contactosProvider = Provider.of<ContactoEmergenciaProvider>(context, listen: false);
      final contactos = contactosProvider.contactos.where((c) => c.userId == userId).toList();

      // Mensaje de emergencia
      final message = '¡EMERGENCIA! ${userName.isNotEmpty ? userName : 'Usuario'} necesita ayuda urgente';

      List<String> numeros = []; // List to hold phone numbers

      if (contactos.isNotEmpty) {
        // Add all contact numbers
        numeros = contactos.map((c) => c.phone).toList();
         debugPrint('Sending emergency SMS to configured contacts.');
      } else {
        // Si no hay contactos registrados, usar el número predeterminado
        numeros.add(_emergencyNumber);
         debugPrint('No contacts found. Sending emergency SMS to default number: $_emergencyNumber');
      }

      if (numeros.isNotEmpty) {
         // Send all SMS in parallel
         await Future.wait(
           numeros.map((numero) => telephony.sendSms(to: numero, message: message))
         );
         debugPrint('Emergency SMS sent successfully.');
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Alerta enviada a contactos de emergencia'),
               backgroundColor: AppTheme.secondaryGreen,
             ),
           );
         }
      } else {
         debugPrint('No phone numbers available to send SMS.');
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(
                content: Text('No hay números de contacto disponibles para enviar la alerta.'),
                backgroundColor: AppTheme.secondaryRed,
                ),
             );
          }
      }


    } catch (e) {
      debugPrint('Error sending emergency SMS: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar alerta: ${e.toString()}'),
            backgroundColor: AppTheme.secondaryRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingSMS = false;
        });
      }
    }
  }

  Future<bool> _checkSMSPermissions() async {
    // Verificar permiso para SMS
    var smsStatus = await Permission.sms.status;
    var phoneStatus = await Permission.phone.status;

    bool granted = smsStatus.isGranted && phoneStatus.isGranted;

    if (!granted) {
       debugPrint('SMS or Phone permissions not granted. Requesting...');
       // Request both permissions
       Map<Permission, PermissionStatus> statuses = await [
          Permission.sms,
          Permission.phone,
       ].request();

       granted = statuses[Permission.sms]?.isGranted == true &&
                 statuses[Permission.phone]?.isGranted == true;

       if (!granted) {
          debugPrint('SMS or Phone permissions denied after request.');
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(
                 content: Text('Permisos de SMS y Teléfono necesarios para enviar alertas.'),
                 backgroundColor: AppTheme.secondaryRed,
               ),
             );
          }
       }
    } else {
       debugPrint('SMS and Phone permissions already granted.');
    }

    return granted;
  }


  void _showEmergencyConfirmation() {
    // Si el sistema de alertas está desactivado, mostrar un mensaje y no continuar
    final alertSystemProvider = Provider.of<AlertSystemProvider>(context, listen: false);
    if (!alertSystemProvider.isAlertSystemActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sistema de alertas desactivado.'),
          backgroundColor: AppTheme.secondaryRed,
        ),
      );
      return;
    }

    bool alertSent = false;

    // Obtener información de contactos para mostrar en el mensaje
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id ?? '';
    final contactosProvider = Provider.of<ContactoEmergenciaProvider>(context, listen: false);
    final contactos = contactosProvider.contactos.where((c) => c.userId == userId).toList();

    // Texto para mostrar a quién se enviará la alerta
    final String destinatarioText = contactos.isNotEmpty
        ? '${contactos.length} contacto${contactos.length > 1 ? 's' : ''} de emergencia'
        : 'número de emergencia predeterminado';

    showDialog(
      context: context,
      builder: (context) {

        Future.delayed(const Duration(seconds: 10), () {
          if (!alertSent && Navigator.canPop(context)) {
            Navigator.pop(context);
            _sendEmergencySMS(); // Send SMS automatically after timeout
          }
        });

        return AlertDialog(
          title: const Text('Confirmar Emergencia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('¿Enviar alerta a $destinatarioText?'),
              const SizedBox(height: 8),
              Text(
                'Se enviará automáticamente en 10 segundos',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.secondaryRed,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                alertSent = true; // Mark as sent to prevent auto-send
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryRed,
              ),
              onPressed: () {
                alertSent = true; // Mark as sent to prevent auto-send
                Navigator.pop(context);
                _sendEmergencySMS(); // Send SMS immediately
              },
              child: const Text('Enviar Ahora'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertSystemProvider>(
      builder: (context, alertSystemProvider, _) {
        final bool isAlertSystemActive = alertSystemProvider.isAlertSystemActive;

        return Scaffold(
          appBar: AppBar(
            title: const Text('AlzAlert'),
            actions: [
              Switch(
                value: isAlertSystemActive,
                // Corrected: Removed context argument from _toggleAlertSystem call
                onChanged: (_) => _toggleAlertSystem(context), // Still need context for SnackBar
                activeColor: AppTheme.secondaryGreen,
                inactiveThumbColor: const Color.fromARGB(255, 200, 200, 200),
                inactiveTrackColor: Colors.grey[500],
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
                                const Text('Bienvenido,'),
                                Consumer<UserProvider>(
                                  builder: (context, userProvider, _) {
                                    final name = userProvider.user?.name ?? ''; // Handle potential null user
                                    return Text(
                                      '${name.isNotEmpty ? name : 'Usuario'}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      isAlertSystemActive
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: isAlertSystemActive
                                          ? AppTheme.secondaryGreen
                                          : AppTheme.secondaryRed,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isAlertSystemActive
                                          ? 'Sistema activo'
                                          : 'Sistema inactivo',
                                      style: TextStyle(
                                        color: isAlertSystemActive
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
                            onTap: _isSendingSMS ? null : _showEmergencyConfirmation,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: _isSendingSMS
                                    ? AppTheme.secondaryRed.withOpacity(0.7)
                                    : isAlertSystemActive
                                        ? AppTheme.secondaryRed
                                        : AppTheme.secondaryRed.withOpacity(0.4), // Botón desactivado con opacidad
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: isAlertSystemActive
                                        ? AppTheme.secondaryRed.withOpacity(0.3)
                                        : Colors.transparent, // Sin sombra cuando está desactivado
                                    spreadRadius: 10,
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isSendingSMS
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : Text(
                                        'EMERGENCIA',
                                        style: TextStyle(
                                          color: isAlertSystemActive ? Colors.white : Colors.white.withOpacity(0.7),
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _isSendingSMS
                                ? 'Enviando alerta...'
                                : isAlertSystemActive
                                    ? 'Presiona el botón en caso de emergencia'
                                    : 'Sistema desactivado\nActive el sistema para usar',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: isAlertSystemActive ? null : AppTheme.textLight,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  if (isAlertSystemActive)
                    Card(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
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
                                    'Recibirás alertas periódicas para verificar tu estado.',
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
                  if (!isAlertSystemActive)
                    Card(
                      color: Colors.grey[600],
                      child: Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_outlined,
                              color: Colors.amber[600],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sistema de alertas desactivado',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryWhite,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Active el sistema para poder usar las funciones de emergencia.',
                                    style: TextStyle(
                                      color: AppTheme.primaryWhite,
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
      },
    );
  }
}
