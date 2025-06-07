import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:alzalert/providers/alert_system_provider.dart';
import 'package:alzalert/providers/user_provider.dart';
import 'package:alzalert/screens/alerts/alert_config_screen.dart';
import 'package:alzalert/screens/history/location_history_screen.dart';
import 'package:alzalert/screens/profile/profile_screen.dart';
import 'package:alzalert/theme/app_theme.dart';
import 'package:telephony/telephony.dart';
import 'package:alzalert/providers/location_history_provider.dart';
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
    const AlertConfigScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 0, 128, 128),
        iconSize: 25,
        selectedFontSize: 15,
        unselectedFontSize: 15,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(
          255,
          200,
          255,
          130,
        ), // Color contrastante para el elemento seleccionado
        unselectedItemColor:
            Colors.white, // Color blanco para los elementos no seleccionados
        elevation: 8,
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
  // Variable para almacenar la ubicación capturada
  String _currentLocationString = '';
  double?
  _currentLatitude; // Guardar latitud y longitud por separado para el proveedor
  double? _currentLongitude;

  // Getter para la ubicación capturada (aunque solo se usará internamente para imprimir)
  String get currentLocationString => _currentLocationString;

  @override
  void initState() {
    super.initState();
    _initializeTelephony();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId =
          Provider.of<UserProvider>(context, listen: false).user?.id ?? '';
      if (userId.isNotEmpty) {
        await Provider.of<ContactoEmergenciaProvider>(
          context,
          listen: false,
        ).cargarContactos(userId);
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
      debugPrint(
        'El dispositivo no puede enviar SMS o permisos no concedidos.',
      );
      // Consider showing a persistent message to the user if permissions are denied.
    }
  }

  // Corrected: Removed BuildContext argument from the call to toggleAlertSystem
  void _toggleAlertSystem(BuildContext context) {
    final alertSystemProvider = Provider.of<AlertSystemProvider>(
      context,
      listen: false,
    );
    alertSystemProvider.toggleAlertSystem(); // Removed context argument

    // The context is still needed here for showing the SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          alertSystemProvider.isAlertSystemActive
              ? 'Sistema de alertas activado'
              : 'Sistema de alertas desactivado',
        ),
        backgroundColor:
            alertSystemProvider.isAlertSystemActive
                ? AppTheme.secondaryGreen
                : AppTheme.secondaryRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Method to capture the current location
  Future<void> _captureCurrentLocation() async {
    try {
      // Verificar si los servicios de ubicación están habilitados
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Servicios de ubicación deshabilitados.');
        _currentLocationString =
            'Error: Servicios de ubicación deshabilitados.';
        return; // No se puede obtener la ubicación si el servicio está deshabilitado
      }

      // Verificar el estado del permiso de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Permisos de ubicación denegados.');
        _currentLocationString = 'Error: Permisos de ubicación denegados.';
        // En una app de producción, aquí se podría considerar solicitar el permiso de nuevo
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('Permisos de ubicación permanentemente denegados.');
        _currentLocationString =
            'Error: Permisos de ubicación permanentemente denegados.';
        return; // Permisos denegados permanentemente, no se puede solicitar
      }

      // Obtener la posición actual con alta precisión
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;
      // Formatear y almacenar la ubicación
      _currentLocationString = '${position.latitude},${position.longitude}';
      debugPrint(
        'Ubicación capturada: $_currentLocationString',
      ); // Imprimir en consola
    } catch (e) {
      debugPrint('Error al capturar la ubicación: $e');
      _currentLocationString = 'Error al capturar ubicación: ${e.toString()}';
      _currentLatitude = null;
      _currentLongitude = null;
    }
    // No es necesario llamar notifyListeners aquí, ya que la UI no mostrará esta variable directamente
    // La ubicación se captura cuando se activa el diálogo.
  }

  Future<void> _sendEmergencySMS() async {
    // Verificar si el sistema está activo antes de continuar
    final alertSystemProvider = Provider.of<AlertSystemProvider>(
      context,
      listen: false,
    );
    if (!alertSystemProvider.isAlertSystemActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sistema de alertas desactivado. No se puede enviar la alerta.',
          ),
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
            const SnackBar(
              content: Text('Error: Usuario no identificado para enviar SMS.'),
              backgroundColor: AppTheme.secondaryRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      if (_currentLatitude != null && _currentLongitude != null) {
        await Provider.of<LocationHistoryProvider>(
          context,
          listen: false,
        ).addLocationEntry(userId, _currentLatitude!, _currentLongitude!);
      } else {
        debugPrint(
          'No se pudo guardar la ubicación en Firestore: coordenadas no disponibles.',
        );
      }

      // Obtener contactos de emergencia
      final contactosProvider = Provider.of<ContactoEmergenciaProvider>(
        context,
        listen: false,
      );
      final contactos =
          contactosProvider.contactos.where((c) => c.userId == userId).toList();

      // Mensaje de emergencia
      String mensaje =
          'EMERGENCIA! ${userName.isNotEmpty ? userName : 'Usuario'} necesita ayuda urgente';

      // Agregar ubicación si disponible, en formato simple
      if (_currentLocationString.isNotEmpty &&
          !_currentLocationString.startsWith('Error')) {
        mensaje +=
            '\nUbicacion: https://www.google.com/maps/search/?api=1&query=$_currentLocationString';
      }

      // Enviar SMS a todos los contactos
      List<String> numeros = []; // List to hold phone numbers

      if (contactos.isNotEmpty) {
        // Add all contact numbers
        numeros = contactos.map((c) => c.phone).toList();
        debugPrint('Sending emergency SMS to configured contacts.');
      } else {
        // Si no hay contactos registrados, usar el número predeterminado
        numeros.add(_emergencyNumber);
        debugPrint(
          'No contacts found. Sending emergency SMS to default number: $_emergencyNumber',
        );
      }

      if (numeros.isNotEmpty) {
        // Send all SMS in parallel
        await Future.wait(
          numeros.map(
            (numero) => telephony.sendSms(to: numero, message: mensaje),
          ),
        );
        debugPrint('Emergency SMS sent successfully.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alerta enviada a contactos de emergencia'),
              backgroundColor: AppTheme.primaryBlue,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        debugPrint('No phone numbers available to send SMS.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No hay números de contacto disponibles para enviar la alerta.',
              ),
              backgroundColor: AppTheme.secondaryRed,
              behavior: SnackBarBehavior.floating,
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
            behavior: SnackBarBehavior.floating,
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
      Map<Permission, PermissionStatus> statuses =
          await [Permission.sms, Permission.phone].request();

      granted =
          statuses[Permission.sms]?.isGranted == true &&
          statuses[Permission.phone]?.isGranted == true;

      if (!granted) {
        debugPrint('SMS or Phone permissions denied after request.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Permisos de SMS y Teléfono necesarios para enviar alertas.',
              ),
              backgroundColor: AppTheme.secondaryRed,
              behavior: SnackBarBehavior.floating,
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
    final alertSystemProvider = Provider.of<AlertSystemProvider>(
      context,
      listen: false,
    );
    if (!alertSystemProvider.isAlertSystemActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sistema de alertas desactivado.'),
          backgroundColor: AppTheme.secondaryRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    bool alertSent = false;

    // Obtener información de contactos para mostrar en el mensaje
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id ?? '';
    final contactosProvider = Provider.of<ContactoEmergenciaProvider>(
      context,
      listen: false,
    );
    final contactos =
        contactosProvider.contactos.where((c) => c.userId == userId).toList();

    // Texto para mostrar a quién se enviará la alerta
    final String destinatarioText =
        contactos.isNotEmpty
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
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.secondaryRed),
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
              onPressed: () async {
                alertSent = true; // Mark as sent to prevent auto-send
                Navigator.pop(context);
                await _captureCurrentLocation();
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
        final bool isAlertSystemActive =
            alertSystemProvider.isAlertSystemActive;

        return Scaffold(
          appBar: AppBar(
            title: const Text('AlzAlert'),
            actions: [
              Switch(
                value: isAlertSystemActive,
                // Corrected: Removed context argument from _toggleAlertSystem call
                onChanged:
                    (_) => _toggleAlertSystem(
                      context,
                    ), // Still need context for SnackBar
                activeColor: const Color.fromARGB(255, 200, 255, 130),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color.fromARGB(255, 206, 206, 206),
              ),
            ],
          ),
          body: SafeArea(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Colors.blue.shade50],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta de perfil con diseño moderno
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppTheme.primaryBlue.withOpacity(
                                0.1,
                              ),
                              child: Icon(
                                Icons.person,
                                size: 30,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bienvenido,',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Consumer<UserProvider>(
                                    builder: (context, userProvider, _) {
                                      final name =
                                          userProvider.user?.name ?? '';
                                      return Text(
                                        '${name.isNotEmpty ? name : 'Usuario'}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryBlue,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isAlertSystemActive
                                              ? AppTheme.secondaryGreen
                                                  .withOpacity(0.15)
                                              : AppTheme.secondaryRed
                                                  .withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isAlertSystemActive
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          color:
                                              isAlertSystemActive
                                                  ? AppTheme.secondaryGreen
                                                  : AppTheme.secondaryRed,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isAlertSystemActive
                                              ? 'Sistema activo'
                                              : 'Sistema inactivo',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                isAlertSystemActive
                                                    ? AppTheme.secondaryGreen
                                                    : AppTheme.secondaryRed,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Sección central con botón de emergencia
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Botón de emergencia con animación mejorada
                            GestureDetector(
                              onTap:
                                  _isSendingSMS
                                      ? null
                                      : _showEmergencyConfirmation,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  color:
                                      _isSendingSMS
                                          ? AppTheme.secondaryRed.withOpacity(
                                            0.8,
                                          )
                                          : isAlertSystemActive
                                          ? AppTheme.secondaryRed
                                          : AppTheme.secondaryRed.withOpacity(
                                            0.4,
                                          ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          isAlertSystemActive
                                              ? AppTheme.secondaryRed
                                                  .withOpacity(0.3)
                                              : Colors.transparent,
                                      spreadRadius: 5,
                                      blurRadius: 15,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 4,
                                  ),
                                ),
                                child: Center(
                                  child:
                                      _isSendingSMS
                                          ? const CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3,
                                          )
                                          : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.white,
                                                size: 50,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'EMERGENCIA',
                                                style: TextStyle(
                                                  color:
                                                      isAlertSystemActive
                                                          ? Colors.white
                                                          : Colors.white
                                                              .withOpacity(0.7),
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                            ],
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
                              style: TextStyle(
                                color:
                                    isAlertSystemActive
                                        ? AppTheme.primaryBlue
                                        : Colors.grey,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Tarjeta de información sobre el estado del sistema
                    Container(
                      margin: EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color:
                            isAlertSystemActive
                                ? AppTheme.primaryBlue.withOpacity(0.1)
                                : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 0,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    isAlertSystemActive
                                        ? AppTheme.primaryBlue.withOpacity(0.15)
                                        : Colors.grey.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAlertSystemActive
                                    ? Icons.info_outline
                                    : Icons.warning_amber_outlined,
                                color:
                                    isAlertSystemActive
                                        ? AppTheme.primaryBlue
                                        : Colors.amber[800],
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAlertSystemActive
                                        ? 'Sistema de alertas activo'
                                        : 'Sistema de alertas desactivado',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color:
                                          isAlertSystemActive
                                              ? AppTheme.primaryBlue
                                              : Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isAlertSystemActive
                                        ? 'Recibirás alertas periódicas para verificar tu estado.'
                                        : 'Active el sistema para poder usar las funciones de emergencia.',
                                    style: TextStyle(
                                      color:
                                          isAlertSystemActive
                                              ? AppTheme.primaryBlue
                                                  .withOpacity(0.8)
                                              : Colors.grey[600],
                                      fontSize: 16,
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
          ),
        );
      },
    );
  }
}
