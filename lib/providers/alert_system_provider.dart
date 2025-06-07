import 'dart:async';
import 'dart:math' as Math;
import 'package:alzalert/providers/contacto_emergencia_provider.dart';
import 'package:alzalert/providers/location_history_provider.dart';
import 'package:alzalert/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/alerts/alert_dialog_screen.dart';
import '../theme/app_theme.dart'; // Import AppTheme
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator

class AlertSystemProvider with ChangeNotifier {
  // Store the navigator key internally
  final GlobalKey<NavigatorState> _navigatorKey;

  bool _isAlertSystemActive = true;
  Timer? _alertTimer;
  Timer? _secondaryAlertTimer;

  // Configurable intervals (in seconds), initialized with test values
  int _configuredPrimaryIntervalSeconds =
      3600; // Default to 20 seconds for testing
  int _configuredSecondaryIntervalSeconds =
      300; // Default to 10 seconds for testing

  bool _isDialogShown = false;
  bool _isSecondaryTimer = false; // Flag to identify the current timer
  int _retryCount = 0; // Retry counter

  // Variable para almacenar la ubicación capturada
  String _currentLocationString = '';
  double?
  _currentLatitude; // Guardar latitud y longitud por separado para el proveedor
  double? _currentLongitude;

  // Constructor - accepts the navigatorKey
  AlertSystemProvider(this._navigatorKey) {
    // Start the primary timer immediately if the system is active
    // This assumes the provider is created when the app starts or after login
    if (_isAlertSystemActive) {
      debugPrint('AlertSystemProvider initialized. Starting primary timer.');
      _startPrimaryTimer();
    }
  }

  // Getter for alert system active status
  bool get isAlertSystemActive => _isAlertSystemActive;

  // Getters for configured intervals
  int get configuredPrimaryIntervalSeconds => _configuredPrimaryIntervalSeconds;
  int get configuredSecondaryIntervalSeconds =>
      _configuredSecondaryIntervalSeconds;

  // Getter para la ubicación capturada (aunque solo se usará internamente para imprimir)
  String get currentLocationString => _currentLocationString;

  // Setter para activar/desactivar el sistema
  set isAlertSystemActive(bool value) {
    if (_isAlertSystemActive != value) {
      _isAlertSystemActive = value;
      if (_isAlertSystemActive) {
        // Si se activa el sistema, iniciamos los temporizadores
        _startPrimaryTimer();
      } else {
        // Si se desactiva el sistema, cancelamos los temporizadores
        _cancelAllTimers();
      }
      notifyListeners();
    }
  }

  // Setter for primary interval
  void setPrimaryInterval(int seconds) {
    _configuredPrimaryIntervalSeconds = seconds;
    // If the primary timer is currently active, restart it with the new interval
    if (_isAlertSystemActive && !_isSecondaryTimer) {
      _startPrimaryTimer();
    }
    notifyListeners();
  }

  // Setter for secondary interval
  void setSecondaryInterval(int seconds) {
    _configuredSecondaryIntervalSeconds = seconds;
    // If the secondary timer is currently active, restart it with the new interval
    if (_isAlertSystemActive && _isSecondaryTimer) {
      _startSecondaryTimer();
    }
    notifyListeners();
  }

  // Toggle the alert system on/off
  void toggleAlertSystem() {
    _isAlertSystemActive = !_isAlertSystemActive;
    if (_isAlertSystemActive) {
      // Start the primary timer if activating
      debugPrint('Alert system toggled ON.');
      _startPrimaryTimer();
    } else {
      // Cancel all timers if deactivating
      debugPrint('Alert system toggled OFF.');
      _cancelAllTimers();
    }
    notifyListeners();
  }

  // Start the primary alert timer using the configured interval
  void _startPrimaryTimer() {
    _cancelAllTimers(); // Cancel any existing timers
    if (!_isAlertSystemActive) return;

    _isSecondaryTimer = false; // Indicate it's the primary timer
    _alertTimer = Timer.periodic(
      Duration(seconds: _configuredPrimaryIntervalSeconds),
      (timer) {
        _showAlertDialog();
      },
    );
    debugPrint(
      'Primary timer started: $_configuredPrimaryIntervalSeconds seconds',
    );
  }

  // Start the secondary alert timer using the configured interval
  void _startSecondaryTimer() {
    _cancelAllTimers(); // Cancel any existing timers
    if (!_isAlertSystemActive) return;

    _isSecondaryTimer = true;
    _secondaryAlertTimer = Timer.periodic(
      Duration(seconds: _configuredSecondaryIntervalSeconds),
      (timer) {
        _showAlertDialog();
      },
    );
    debugPrint(
      'Secondary timer started: $_configuredSecondaryIntervalSeconds seconds',
    );
  }

  // Reset the current timer (used when user responds 'Yes')
  void resetAlertTimer() {
    debugPrint('Resetting alert timer.');
    _cancelAllTimers(); // Cancel current timer
    // Restart the appropriate timer based on which one was active before reset
    if (_isSecondaryTimer) {
      _startSecondaryTimer();
    } else {
      _startPrimaryTimer();
    }
  }

  // Cancel all active timers
  void _cancelAllTimers() {
    _alertTimer?.cancel();
    _secondaryAlertTimer?.cancel();
    _alertTimer = null;
    _secondaryAlertTimer = null;
    debugPrint('All timers cancelled.');
  }

  void stopAlertSystem() {
    _isAlertSystemActive = false;
    _isDialogShown = false;
    _retryCount = 0;
    _isSecondaryTimer = false;

    _alertTimer?.cancel();
    _secondaryAlertTimer?.cancel();

    notifyListeners();
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

  // Show the alert dialog using the internally stored navigator key
  // Make this method async because it will await _captureCurrentLocation
  Future<void> _showAlertDialog() async {
    // --- Capturar ubicación antes de mostrar el diálogo ---
    debugPrint(
      'Timer expired. Attempting to capture location before showing dialog.',
    );
    await _captureCurrentLocation();

    // Si el sistema está desactivado, no mostrar el diálogo
    if (!_isAlertSystemActive) {
      debugPrint('Sistema de alertas desactivado. No se mostrará el diálogo.');
      return;
    }

    // --- Capturar ubicación antes de mostrar el diálogo ---
    debugPrint(
      'Timer expired. Attempting to capture location before showing dialog.',
    );
    await _captureCurrentLocation();

    // Prevent showing multiple dialogs
    // IMPORTANT: Check if _navigatorKey.currentState is not null before using it
    if (!_isDialogShown && _navigatorKey.currentState != null) {
      _isDialogShown = true;
      debugPrint('Attempting to show alert dialog using _navigatorKey.');
      // Use the internally stored _navigatorKey to push the dialog
      _navigatorKey.currentState!
          .push(
            MaterialPageRoute(
              builder:
                  (context) => AlertDialogScreen(
                    isRetry: _retryCount > 0, // Pass if it's a retry
                  ),
            ),
          )
          .then((result) {
            // This block runs when the AlertDialogScreen is dismissed (popped)
            _isDialogShown = false;
            debugPrint('Alert dialog dismissed with result: $result');

            // Handle the result of the dialog
            if (_isAlertSystemActive) {
              if (result == 'timeout') {
                // If the primary timer timed out
                _retryCount++; // Increment retry count
                if (_retryCount == 1) {
                  // If it's the first timeout, start the secondary timer
                  _startSecondaryTimer();
                } else {
                  // If it's the second timeout, handle the final emergency (send SMS)
                  _handleFinalTimeout();
                }
              } else if (result == 'manual_no') {
                // If the user manually responded 'No'
                _handleFinalTimeout(); // Handle the final emergency
                _retryCount = 0; // Reset retry count
                _startPrimaryTimer(); // Restart primary timer
              } else if (result == 'final_timeout') {
                // This case is handled by _handleFinalTimeout
                _handleFinalTimeout();
                _retryCount = 0; // Reset retry count
                _startPrimaryTimer(); // Restart primary timer
              } else {
                // User responded 'Yes' (or dialog was popped otherwise)
                _retryCount = 0; // Reset retry count
                _startPrimaryTimer(); // Restart primary timer
              }
            }
          });
    } else {
      debugPrint(
        'Dialog already shown or _navigatorKey.currentState is null, not showing again.',
      );
      if (_navigatorKey.currentState == null) {
        debugPrint('_navigatorKey.currentState is null.');
      }
    }
  }

  Future<void> _handleFinalTimeout() async {
    debugPrint('Handling final emergency. Attempting to send SMS.');

    // Use the context from the internally stored _navigatorKey to access providers
    final context = _navigatorKey.currentContext;
    if (context == null) {
      debugPrint('Error: Context is null. Cannot send final SMS.');
      _retryCount = 0;
      _startPrimaryTimer();
      return;
    }

    try {
      if (!_isAlertSystemActive) {
        debugPrint('Sistema de alertas desactivado. No se enviará SMS.');
        return;
      }

      // Access providers using the context from _navigatorKey
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id ?? '';

      if (userId.isEmpty) {
        debugPrint('Error: Usuario no identificado para enviar SMS final.');
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

      final contactosProvider = Provider.of<ContactoEmergenciaProvider>(
        context,
        listen: false,
      );
      // Filter contacts for the current user
      final contactos =
          contactosProvider.contactos.where((c) => c.userId == userId).toList();

      // Crear mensaje simple sin caracteres especiales ni URLs
      String mensaje =
          'ALZALERT: ${userProvider.user?.name ?? 'Usuario'} ha referido no estar bien, puede que necesite ayuda.';

      // Agregar ubicación si disponible, en formato simple
      if (_currentLocationString.isNotEmpty &&
          !_currentLocationString.startsWith('Error')) {
        mensaje +=
            '\nUbicacion: https://www.google.com/maps/search/?api=1&query=$_currentLocationString';
      }

      List<String> numeros = [];
      if (contactos.isNotEmpty) {
        numeros = contactos.map((c) => c.phone).toList();
      }

      // Instantiate Telephony para envío directo
      final Telephony telephony = Telephony.instance;

      if (numeros.isNotEmpty) {
        debugPrint('Sending direct SMS to: ${numeros.join(', ')}');
        debugPrint('Message: $mensaje');

        // Variable para rastrear si todos los envíos fueron exitosos
        bool allSentSuccessfully = true;

        // Enviar mensajes en serie para evitar problemas
        for (String numero in numeros) {
          try {
            // Usar método simple sin statusListener para evitar problemas con receptores
            telephony.sendSms(to: numero, message: mensaje);
            debugPrint('SMS to $numero sent directly');
          } catch (e) {
            debugPrint('Error sending to $numero: $e');
            allSentSuccessfully = false;
          }
        }

        // Mostrar confirmación
        if (_navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
            SnackBar(
              content: Text(
                allSentSuccessfully
                    ? 'Alertas de emergencia enviadas'
                    : 'Algunas alertas podrían no haberse enviado correctamente',
              ),
              backgroundColor:
                  allSentSuccessfully
                      ? AppTheme.primaryBlue
                      : AppTheme.secondaryRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        debugPrint('No hay contactos configurados para enviar SMS.');
        if (_navigatorKey.currentContext != null) {
          ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
            const SnackBar(
              content: Text('No hay contactos de emergencia configurados'),
              backgroundColor: AppTheme.secondaryRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Exception in _handleFinalTimeout: $e');
      if (_navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.secondaryRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _retryCount = 0;
      _startPrimaryTimer();
    }
  }

  // Dispose method to cancel timers when the provider is no longer needed
  @override
  void dispose() {
    _cancelAllTimers();
    debugPrint('AlertSystemProvider disposed.');
    super.dispose();
  }
}
