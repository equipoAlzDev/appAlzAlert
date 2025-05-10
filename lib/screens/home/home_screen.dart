import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:telephony/telephony.dart';

import 'package:AlzAlert/providers/alert_system_provider.dart';
import 'package:AlzAlert/providers/user_provider.dart';
import 'package:AlzAlert/providers/contacto_emergencia_provider.dart';
import 'package:AlzAlert/screens/alerts/alert_config_screen.dart';
import 'package:AlzAlert/screens/history/location_history_screen.dart';
import 'package:AlzAlert/screens/notifications/notifications_screen.dart';
import 'package:AlzAlert/screens/profile/profile_screen.dart';
import 'package:AlzAlert/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0; // Índice de la pantalla seleccionada

  @override
  void initState() {
    super.initState();
    // Carga inicial de datos del usuario después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUserData();
    });
  }

  // Lista de pantallas disponibles en la barra inferior
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
        onTap: (index) => setState(() => _selectedIndex = index),
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
  bool _isSendingSMS = false; // Estado de envío de SMS
  bool _contactosCargados = false; // Estado de carga de contactos
  final Telephony telephony = Telephony.instance; // Instancia de Telephony
  final String _emergencyNumber = '3157042961'; // Número predeterminado

  @override
  void initState() {
    super.initState();
    _initializeTelephony();
    // Cargar contactos de emergencia después de obtener userId
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = Provider.of<UserProvider>(context, listen: false).user?.id ?? '';
      if (userId.isNotEmpty) {
        await Provider.of<ContactoEmergenciaProvider>(context, listen: false)
            .cargarContactos(userId);
        if (mounted) setState(() => _contactosCargados = true);
      }
    });
  }

  /// Solicita permisos de teléfono y SMS
  Future<void> _initializeTelephony() async {
    final canSendSms = await telephony.requestPhoneAndSmsPermissions;
    if (canSendSms != true) {
      debugPrint('Permisos de SMS o Teléfono no concedidos');
    }
  }

  /// Activa o desactiva el sistema de alertas y muestra un SnackBar
  void _toggleAlertSystem(BuildContext context) {
    final provider = Provider.of<AlertSystemProvider>(context, listen: false);
    provider.toggleAlertSystem();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.isAlertSystemActive
              ? 'Sistema de alertas activado'
              : 'Sistema de alertas desactivado',
        ),
        backgroundColor: provider.isAlertSystemActive
            ? AppTheme.secondaryGreen
            : AppTheme.secondaryRed,
      ),
    );
  }

  /// Envía SMS de emergencia a contactos o número predeterminado
  Future<void> _sendEmergencySMS() async {
    final alertProvider = Provider.of<AlertSystemProvider>(context, listen: false);
    if (!alertProvider.isAlertSystemActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sistema de alertas desactivado. No se envía SMS.'),
          backgroundColor: AppTheme.secondaryRed,
        ),
      );
      return;
    }

    setState(() => _isSendingSMS = true);

    try {
      if (!await _checkSMSPermissions()) return;

      final userProv = Provider.of<UserProvider>(context, listen: false);
      final userName = userProv.user?.name ?? 'Usuario';
      final userId = userProv.user?.id ?? '';
      if (userId.isEmpty) {
        debugPrint('User ID vacío. No se envía SMS.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario no identificado.'),
              backgroundColor: AppTheme.secondaryRed,
            ),
          );
        }
        return;
      }

      final contactos = Provider.of<ContactoEmergenciaProvider>(context, listen: false)
          .contactos
          .where((c) => c.userId == userId)
          .toList();
      final message = '¡EMERGENCIA! \$userName necesita ayuda urgente';
      final numeros = contactos.isNotEmpty
          ? contactos.map((c) => c.phone).toList()
          : [_emergencyNumber];

      await Future.wait(numeros.map((n) => telephony.sendSms(to: n, message: message)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alerta enviada correctamente'),
            backgroundColor: AppTheme.secondaryGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al enviar SMS: \$e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar alerta: \$e'),
            backgroundColor: AppTheme.secondaryRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingSMS = false);
    }
  }

  /// Verifica y solicita permisos necesarios
  Future<bool> _checkSMSPermissions() async {
    var smsStatus = await Permission.sms.status;
    var phoneStatus = await Permission.phone.status;
    if (!(smsStatus.isGranted && phoneStatus.isGranted)) {
      final statuses = await [Permission.sms, Permission.phone].request();
      if (!(statuses[Permission.sms]?.isGranted == true && 
            statuses[Permission.phone]?.isGranted == true)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permisos de SMS y Teléfono necesarios.'),
              backgroundColor: AppTheme.secondaryRed,
            ),
          );
        }
        return false;
      }
    }
    return true;
  }

  /// Muestra diálogo de confirmación antes de enviar alerta
  void _showEmergencyConfirmation() {
    final alertProv = Provider.of<AlertSystemProvider>(context, listen: false);
    if (!alertProv.isAlertSystemActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sistema desactivado.'),
          backgroundColor: AppTheme.secondaryRed,
        ),
      );
      return;
    }

    bool sent = false;
    final userId = Provider.of<UserProvider>(context, listen: false).user?.id ?? '';
    final contactos = Provider.of<ContactoEmergenciaProvider>(context, listen: false)
        .contactos
        .where((c) => c.userId == userId)
        .toList();
    final destinatario = contactos.isNotEmpty
        ? '${contactos.length} contacto${contactos.length > 1 ? 's' : ''}'
        : 'número predeterminado';

    showDialog(
      context: context,
      builder: (context) {
        Future.delayed(const Duration(seconds: 10), () {
          if (!sent && Navigator.canPop(context)) {
            Navigator.pop(context);
            _sendEmergencySMS();
          }
        });
        return AlertDialog(
          title: const Text('Confirmar Emergencia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('¿Enviar alerta a $destinatario?'),
              const SizedBox(height: 8),
              Text('Se enviará en 10 segundos', style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.secondaryRed)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () { sent = true; Navigator.pop(context); },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryRed),
              onPressed: () { sent = true; Navigator.pop(context); _sendEmergencySMS(); },
              child: const Text('Enviar Ahora'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertSystemProvider>(builder: (context, alertProv, _) {
      final active = alertProv.isAlertSystemActive;
      return Scaffold(
        appBar: AppBar(
          title: const Text('AlzAlert'),
          actions: [
            Switch(
              value: active,
              onChanged: (_) => _toggleAlertSystem(context),
              activeColor: AppTheme.secondaryGreen,
              inactiveThumbColor: Colors.grey,
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
                          child: const Icon(Icons.person, color: AppTheme.primaryWhite),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bienvenido,'),
                              Consumer<UserProvider>(builder: (context, up, _) {
                                final name = up.user?.name ?? 'Usuario';
                                return Text(name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.bold));
                              }),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    active ? Icons.check_circle : Icons.cancel,
                                    color: active ? AppTheme.secondaryGreen : AppTheme.secondaryRed,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    active ? 'Sistema activo' : 'Sistema inactivo',
                                    style: TextStyle(
                                        color: active ? AppTheme.secondaryGreen : AppTheme.secondaryRed),
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
                          onTap: _isSendingSMS || !active ? null : _showEmergencyConfirmation,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: _isSendingSMS
                                  ? AppTheme.secondaryRed.withOpacity(0.7)
                                  : active
                                      ? AppTheme.secondaryRed
                                      : AppTheme.secondaryRed.withOpacity(0.4),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: active ? AppTheme.secondaryRed.withOpacity(0.3) : Colors.transparent,
                                  spreadRadius: 10,
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isSendingSMS
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      'EMERGENCIA',
                                      style: TextStyle(
                                        color: active ? Colors.white : Colors.white.withOpacity(0.7),
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
                              : active
                                  ? 'Presiona el botón en caso de emergencia'
                                  : 'Sistema desactivado\nActive el sistema para usar',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: active ? null : AppTheme.textLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                if (active)
                  Card(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Sistema de alertas activo', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                const SizedBox(height: 4),
                                Text('Recibirás alertas periódicas para verificar tu estado.'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (!active)
                  Card(
                    color: Colors.grey[600],
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_outlined, color: Colors.amber[600]),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Sistema de alertas desactivado', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryWhite)),
                                const SizedBox(height: 4),
                                Text('Active el sistema para poder usar las funciones de emergencia.'),
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
    });
  }
}