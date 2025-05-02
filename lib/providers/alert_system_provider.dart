import 'dart:async';
import 'package:AlzAlert/providers/contacto_emergencia_provider.dart';
import 'package:AlzAlert/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/alerts/alert_dialog_screen.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';


class AlertSystemProvider with ChangeNotifier {
  // Store the navigator key internally
  final GlobalKey<NavigatorState> _navigatorKey;

  bool _isAlertSystemActive = true;
  Timer? _alertTimer;
  Timer? _secondaryAlertTimer;

  // Configurable intervals (in seconds), initialized with test values
  int _configuredPrimaryIntervalSeconds = 20; // Default to 20 seconds for testing
  int _configuredSecondaryIntervalSeconds = 10; // Default to 10 seconds for testing

  bool _isDialogShown = false;
  bool _isSecondaryTimer = false;   // Flag to identify the current timer
  int _retryCount = 0; // Retry counter

  // REMOVED: Número de emergencia predeterminado
  // final String _emergencyNumber = "3157042961";

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
  int get configuredSecondaryIntervalSeconds => _configuredSecondaryIntervalSeconds;

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
    _isSecondaryTimer = false; // Indicate it's the primary timer
    _alertTimer = Timer(
      Duration(seconds: _configuredPrimaryIntervalSeconds), // Use configured primary interval
      () => _showAlertDialog(), // Show alert when timer finishes
    );
    debugPrint('Primary timer started for $_configuredPrimaryIntervalSeconds seconds');
  }

  // Start the secondary alert timer using the configured interval
  void _startSecondaryTimer() {
    _cancelAllTimers(); // Cancel any existing timers
    _isSecondaryTimer = true; // Indicate it's the secondary timer
    _secondaryAlertTimer = Timer(
      Duration(seconds: _configuredSecondaryIntervalSeconds), // Use configured secondary interval
      () => _showAlertDialog(), // Show alert when timer finishes
    );
    debugPrint('Secondary timer started for $_configuredSecondaryIntervalSeconds seconds');
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

  // Show the alert dialog using the internally stored navigator key
  void _showAlertDialog() {
      // Prevent showing multiple dialogs
      // IMPORTANT: Check if _navigatorKey.currentState is not null before using it
      if (!_isDialogShown && _navigatorKey.currentState != null) {
        _isDialogShown = true;
        debugPrint('Attempting to show alert dialog using _navigatorKey.');
        // Use the internally stored _navigatorKey to push the dialog
        _navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => AlertDialogScreen(
              isRetry: _retryCount > 0, // Pass if it's a retry
            ),
          ),
        ).then((result) {
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
            }
             else if (result == 'final_timeout') {
               // This case is handled by _handleFinalTimeout
               _handleFinalTimeout();
               _retryCount = 0; // Reset retry count
               _startPrimaryTimer(); // Restart primary timer
            }
            else { // User responded 'Yes' (or dialog was popped otherwise)
              _retryCount = 0; // Reset retry count
              _startPrimaryTimer(); // Restart primary timer
            }
          }
        });
      } else {
        debugPrint('Dialog already shown or _navigatorKey.currentState is null, not showing again.');
        if (_navigatorKey.currentState == null) {
            debugPrint('_navigatorKey.currentState is null.');
        }
      }
    }

    // Handle the final timeout event or manual 'No' response
    void _handleFinalTimeout() {
      debugPrint('Handling final emergency. Attempting to send SMS.');

      // Use the context from the internally stored _navigatorKey to access providers
      final context = _navigatorKey.currentContext;
      if (context == null) {
         debugPrint('Error: Context from _navigatorKey.currentContext is null. Cannot send final SMS.');
         // Consider logging this error or showing a persistent notification.
         _retryCount = 0; // Reset retry count even on error
         _startPrimaryTimer(); // Restart primary timer
         return;
      }

      try {
        // Access providers using the context from _navigatorKey
        // Use listen: false as we are only reading data and calling methods
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userId = userProvider.user?.id ?? '';

        if (userId.isEmpty) {
          debugPrint('Error: Usuario no identificado para enviar SMS final.');
          // Consider logging this error or showing a persistent notification.
          return;
        }

        final contactosProvider = Provider.of<ContactoEmergenciaProvider>(context, listen: false);
        // Filter contacts for the current user
        final contactos = contactosProvider.contactos.where((c) => c.userId == userId).toList();

        // Create the emergency message
        final message = '¡EMERGENCIA! ${userProvider.user?.name ?? 'Usuario'} ha referido no estar bien, puede que necesite ayuda.';

        List<String> numeros = []; // List to hold phone numbers

        if (contactos.isNotEmpty) {
          // Add all contact numbers
          numeros = contactos.map((c) => c.phone).toList();
        }
        // REMOVED: Fallback to the default emergency number if no contacts are found
        // else {
        //   numeros.add(_emergencyNumber);
        // }

        // Instantiate Telephony - requires platform channel interaction
        final Telephony telephony = Telephony.instance;

        // Check and request permissions (asynchronous)
        // Doing this here is problematic. Permissions should be requested upfront.
        // Assuming permissions are already granted for this simplified example.
        // A production app needs robust permission handling before attempting to send SMS.

        // ONLY SEND SMS IF THERE ARE NUMBERS
        if (numeros.isNotEmpty) {
           debugPrint('Attempting to send final emergency SMS to: ${numeros.join(', ')}');
           // Send all SMS in parallel
           Future.wait(
             numeros.map((numero) => telephony.sendSms(to: numero, message: message))
           ).then((_) {
              debugPrint('Final emergency SMS sent successfully.');
              // Consider showing a local notification to the user.
               // Show a SnackBar confirming SMS sent
               if (_navigatorKey.currentContext != null) {
                  ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
                     const SnackBar(content: Text('Alertas de emergencia enviadas')),
                  );
               }
           }).catchError((e) {
              debugPrint('Error sending final emergency SMS: $e');
              // Consider logging the error or showing a persistent notification.
               // Show a SnackBar indicating error
               if (_navigatorKey.currentContext != null) {
                  ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
                     SnackBar(content: Text('Error al enviar alertas: ${e.toString()}')),
                  );
               }
           });
        } else {
           debugPrint('No phone numbers configured or found to send final emergency SMS. SMS not sent.');
           // Optionally show a message to the user
            if (_navigatorKey.currentContext != null) {
               ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
                  const SnackBar(content: Text('No hay contactos de emergencia configurados. No se envió la alerta.')),
               );
            }
        }

      } catch (e) {
        debugPrint('Exception in _handleFinalTimeout: $e');
        // Handle any exceptions during provider access or SMS setup
         if (_navigatorKey.currentContext != null) {
            ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
               SnackBar(content: Text('Error interno al preparar alerta: ${e.toString()}')),
            );
         }
      } finally {
        // Always reset retry count and restart the primary timer after handling the final timeout
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



/* import 'dart:async';
import 'package:AlzAlert/providers/contacto_emergencia_provider.dart';
import 'package:AlzAlert/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/alerts/alert_dialog_screen.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator

// Elimina la declaración global de navigatorKey aquí.
// Ahora se pasará al constructor del provider.
// late GlobalKey<NavigatorState> navigatorKey; // REMOVE THIS LINE

class AlertSystemProvider with ChangeNotifier {
  // Almacena la clave del navegador internamente
  final GlobalKey<NavigatorState> _navigatorKey;

  bool _isAlertSystemActive = true;
  Timer? _alertTimer;
  Timer? _secondaryAlertTimer;

  // Intervalos configurables (en segundos), inicializados con valores de prueba
  int _configuredPrimaryIntervalSeconds = 20; // Predeterminado a 20 segundos para pruebas
  int _configuredSecondaryIntervalSeconds = 10; // Predeterminado a 10 segundos para pruebas

  bool _isDialogShown = false;
  bool _isSecondaryTimer = false;   // Bandera para identificar el temporizador actual
  int _retryCount = 0; // Contador de reintentos

  // ELIMINADO: Número de emergencia predeterminado
  // final String _emergencyNumber = "3157042961";

  // Constructor - acepta la navigatorKey
  AlertSystemProvider(this._navigatorKey) {
     // Inicia el temporizador primario inmediatamente si el sistema está activo
     // Esto asume que el provider se crea cuando la app inicia o después del login
     if (_isAlertSystemActive) {
        debugPrint('AlertSystemProvider initialized. Starting primary timer.');
        _startPrimaryTimer();
     }
  }

  // Getter para el estado activo del sistema de alertas
  bool get isAlertSystemActive => _isAlertSystemActive;

  // Getters para los intervalos configurados
  int get configuredPrimaryIntervalSeconds => _configuredPrimaryIntervalSeconds;
  int get configuredSecondaryIntervalSeconds => _configuredSecondaryIntervalSeconds;

  // Setter para el intervalo primario
  void setPrimaryInterval(int seconds) {
    _configuredPrimaryIntervalSeconds = seconds;
    // Si el temporizador primario está actualmente activo, reinícialo con el nuevo intervalo
    if (_isAlertSystemActive && !_isSecondaryTimer) {
        _startPrimaryTimer();
    }
    notifyListeners();
  }

  // Setter para el intervalo secundario
  void setSecondaryInterval(int seconds) {
    _configuredSecondaryIntervalSeconds = seconds;
     // Si el temporizador secundario está actualmente activo, reinícialo con el nuevo intervalo
     if (_isAlertSystemActive && _isSecondaryTimer) {
        _startSecondaryTimer();
     }
    notifyListeners();
  }

  // Activa/desactiva el sistema de alertas
  void toggleAlertSystem() {
    _isAlertSystemActive = !_isAlertSystemActive;
    if (_isAlertSystemActive) {
      // Inicia el temporizador primario si se activa
      debugPrint('Alert system toggled ON.');
      _startPrimaryTimer();
    } else {
      // Cancela todos los temporizadores si se desactiva
      debugPrint('Alert system toggled OFF.');
      _cancelAllTimers();
    }
    notifyListeners();
  }

  // Inicia el temporizador de alerta primario usando el intervalo configurado
  void _startPrimaryTimer() {
    _cancelAllTimers(); // Cancela cualquier temporizador existente
    _isSecondaryTimer = false; // Indica que es el temporizador primario
    _alertTimer = Timer(
      Duration(seconds: _configuredPrimaryIntervalSeconds), // Usa el intervalo primario configurado
      () => _showAlertDialog(), // Muestra la alerta cuando el temporizador termina
    );
    debugPrint('Primary timer started for $_configuredPrimaryIntervalSeconds seconds');
  }

  // Inicia el temporizador de alerta secundario usando el intervalo configurado
  void _startSecondaryTimer() {
    _cancelAllTimers(); // Cancela cualquier temporizador existente
    _isSecondaryTimer = true; // Indica que es el temporizador secundario
    _secondaryAlertTimer = Timer(
      Duration(seconds: _configuredSecondaryIntervalSeconds), // Usa el intervalo secundario configurado
      () => _showAlertDialog(), // Muestra la alerta cuando el temporizador termina
    );
    debugPrint('Secondary timer started for $_configuredSecondaryIntervalSeconds seconds');
  }

  // Reinicia el temporizador actual (usado cuando el usuario responde 'Sí')
  void resetAlertTimer() {
    debugPrint('Resetting alert timer.');
    _cancelAllTimers(); // Cancela el temporizador actual
    // Reinicia el temporizador apropiado basado en cuál estaba activo antes del reinicio
    if (_isSecondaryTimer) {
      _startSecondaryTimer();
    } else {
      _startPrimaryTimer();
    }
  }

  // Cancela todos los temporizadores activos
  void _cancelAllTimers() {
    _alertTimer?.cancel();
    _secondaryAlertTimer?.cancel();
    _alertTimer = null;
    _secondaryAlertTimer = null;
     debugPrint('All timers cancelled.');
  }

  // Muestra el diálogo de alerta usando la clave del navegador almacenada internamente
  void _showAlertDialog() {
      // Previene mostrar múltiples diálogos
      // IMPORTANTE: Verifica si _navigatorKey.currentState no es nulo antes de usarlo
      if (!_isDialogShown && _navigatorKey.currentState != null) {
        _isDialogShown = true;
        debugPrint('Attempting to show alert dialog using _navigatorKey.');
        // Usa la clave del navegador almacenada internamente para mostrar el diálogo
        _navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (context) => AlertDialogScreen(
              isRetry: _retryCount > 0, // Pasa si es un reintento
            ),
          ),
        ).then((result) {
          // Este bloque se ejecuta cuando AlertDialogScreen se cierra (pop)
          _isDialogShown = false;
          debugPrint('Alert dialog dismissed with result: $result');

          // Maneja el resultado del diálogo
          if (_isAlertSystemActive) {
            if (result == 'timeout') {
              // Si el temporizador primario expiró
              _retryCount++; // Incrementa el contador de reintentos
              if (_retryCount == 1) {
                // Si es el primer timeout, inicia el temporizador secundario
                _startSecondaryTimer();
              } else {
                // Si es el segundo timeout, maneja la emergencia final (envía SMS)
                _handleFinalTimeout();
              }
            } else if (result == 'manual_no') {
               // Si el usuario respondió manualmente 'No'
               _handleFinalTimeout(); // Maneja la emergencia final
               _retryCount = 0; // Reinicia el contador de reintentos
               _startPrimaryTimer(); // Reinicia el temporizador primario
            }
             else if (result == 'final_timeout') {
               // Este caso es manejado por _handleFinalTimeout
               _handleFinalTimeout();
               _retryCount = 0; // Reinicia el contador de reintentos
               _startPrimaryTimer(); // Reinicia el temporizador primario
            }
            else { // El usuario respondió 'Sí' (o el diálogo se cerró de otra manera)
              _retryCount = 0; // Reinicia el contador de reintentos
              _startPrimaryTimer(); // Reinicia el temporizador primario
            }
          }
        });
      } else {
        debugPrint('Dialog already shown or _navigatorKey.currentState is null, not showing again.');
        if (_navigatorKey.currentState == null) {
            debugPrint('_navigatorKey.currentState is null.');
        }
      }
    }

    // Método auxiliar para obtener la ubicación actual
    Future<Position?> _getCurrentLocation() async {
      try {
        // Verifica si los servicios de ubicación están habilitados
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          debugPrint('Location services are disabled.');
           // Opcionalmente muestra un mensaje al usuario
           if (_navigatorKey.currentContext != null) {
              ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
                 const SnackBar(content: Text('Servicios de ubicación desactivados. No se pudo incluir la ubicación en la alerta.')),
              );
           }
          return null;
        }

        // Verifica los permisos de ubicación
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied. Requesting...');
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            debugPrint('Location permissions are permanently denied.');
             // Opcionalmente muestra un mensaje al usuario
             if (_navigatorKey.currentContext != null) {
                ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
                   const SnackBar(content: Text('Permisos de ubicación denegados. No se pudo incluir la ubicación en la alerta.')),
                );
             }
            return null;
          }
        }

        if (permission == LocationPermission.deniedForever) {
           debugPrint('Location permissions are permanently denied.');
            // Opcionalmente muestra un mensaje al usuario
            if (_navigatorKey.currentContext != null) {
               ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
                  const SnackBar(content: Text('Permisos de ubicación denegados permanentemente. Habilítalos en la configuración del dispositivo para incluir la ubicación en la alerta.')),
               );
            }
           return null;
        }

        // Si los permisos están concedidos, obtiene la posición actual
        debugPrint('Fetching current location...');
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          // Añade un timeout para evitar que se quede colgado indefinidamente
          timeLimit: const Duration(seconds: 10)
        );
        debugPrint('Location fetched: ${position.latitude}, ${position.longitude}');
        return position;

      } catch (e) {
        debugPrint('Error fetching location: $e');
         if (_navigatorKey.currentContext != null) {
            ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
               SnackBar(content: Text('Error al obtener la ubicación: ${e.toString()}')),
            );
         }
        return null;
      }
    }


    // Maneja el evento de timeout final o la respuesta manual 'No'
    void _handleFinalTimeout() async { // Hecho async para esperar la obtención de la ubicación
      debugPrint('Handling final emergency. Attempting to send SMS with location.');

      // Usa el contexto de la clave del navegador almacenada internamente para acceder a los providers
      final context = _navigatorKey.currentContext;
      if (context == null) {
         debugPrint('Error: Context from _navigatorKey.currentContext is null. Cannot send final SMS.');
         // Considera registrar este error o mostrar una notificación persistente.
         _retryCount = 0; // Reinicia el contador de reintentos incluso en caso de error
         _startPrimaryTimer(); // Reinicia el temporizador primario
         return;
      }

      try {
        // Accede a los providers usando el contexto de _navigatorKey
        // Usa listen: false ya que solo estamos leyendo datos y llamando métodos
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final userId = userProvider.user?.id ?? '';

        if (userId.isEmpty) {
          debugPrint('Error: Usuario no identificado para enviar SMS final.');
          // Considera registrar este error o mostrar una notificación persistente.
          return;
        }

        final contactosProvider = Provider.of<ContactoEmergenciaProvider>(context, listen: false);
        // Filtra los contactos para el usuario actual
        final contactos = contactosProvider.contactos.where((c) => c.userId == userId).toList();

        List<String> numeros = []; // Lista para almacenar números de teléfono

        if (contactos.isNotEmpty) {
          // Añade todos los números de contacto
          numeros = contactos.map((c) => c.phone).toList();
        }
        // ELIMINADO: Fallback al número de emergencia predeterminado si no se encuentran contactos
        // else {
        //   numeros.add(_emergencyNumber);
        // }

        // SOLO ENVÍA SMS SI HAY NÚMEROS
        if (numeros.isEmpty) {
           debugPrint('No phone numbers configured or found to send final emergency SMS. SMS not sent.');
           // Opcionalmente muestra un mensaje al usuario
            if (_navigatorKey.currentContext != null) {
               ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
                  const SnackBar(content: Text('No hay contactos de emergencia configurados. No se envió la alerta.')),
               );
            }
            // Siempre reinicia el contador de reintentos y reinicia el temporizador primario incluso si no se envía SMS
            _retryCount = 0;
            _startPrimaryTimer();
            return; // Sale si no hay números
        }


        // Obtiene la ubicación actual
        Position? position = await _getCurrentLocation();

        // Crea el mensaje de emergencia
        String message = '¡EMERGENCIA! ${userProvider.user?.name ?? 'Usuario'} ha referido no estar bien, puede que necesite ayuda.';

        if (position != null) {
           // Añade el enlace de ubicación al mensaje
           // Usando formato estándar de enlace de Google Maps
           message += '\nUbicación: https://www.google.com/maps?q=${position.latitude},${position.longitude}';
           debugPrint('Message with location: $message');
        } else {
           debugPrint('Could not get location, sending SMS without location.');
           message += '\nNo se pudo obtener la ubicación actual.';
        }


        // Instancia Telephony - requiere interacción con el canal de plataforma
        final Telephony telephony = Telephony.instance;

        // Verifica los permisos de SMS (Telephony también los solicita, pero verificar aquí es bueno)
        final smsGranted = await Permission.sms.isGranted;
        final phoneGranted = await Permission.phone.isGranted;

        if (!smsGranted || !phoneGranted) {
             debugPrint('SMS or Phone permissions not granted. Cannot send SMS.');
              if (_navigatorKey.currentContext != null) {
                 ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
                    const SnackBar(content: Text('Permisos de SMS y Teléfono necesarios para enviar alertas.')),
                 );
              }
              // Siempre reinicia el contador de reintentos y reinicia el temporizador primario incluso si el SMS falla debido a permisos
              _retryCount = 0;
              _startPrimaryTimer();
              return; // Sale si los permisos no están concedidos
        }

        debugPrint('Attempting to send final emergency SMS to: ${numeros.join(', ')}');
        // Envía todos los SMS en paralelo
        // Se añadió registro más específico para el resultado de cada intento de envío
         await Future.wait(
           numeros.map((numero) {
             debugPrint('Sending SMS to $numero...');
             return telephony.sendSms(to: numero, message: message).then((_) {
                debugPrint('SMS sent successfully to $numero.');
             }).catchError((e) {
                debugPrint('Error sending SMS to $numero: $e');
                // Registra el error por número, pero el bloque catch principal maneja el fallo general
                // NO vuelvas a lanzar aquí, de lo contrario Future.wait se detendrá en el primer error
                // throw e; // REMOVED re-throw
             });
           })
         );

        debugPrint('All emergency SMS attempts completed.');
        // Considera mostrar una notificación local al usuario.
         // Muestra un SnackBar confirmando el envío del SMS
         if (_navigatorKey.currentContext != null) {
            ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
               const SnackBar(content: Text('Alertas de emergencia enviadas')),
            );
         }

      } catch (e) {
        debugPrint('Exception in _handleFinalTimeout during SMS sending: $e');
        // Maneja cualquier excepción durante el acceso al provider o la configuración del SMS
         if (_navigatorKey.currentContext != null) {
            ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
               SnackBar(content: Text('Error al enviar alertas: ${e.toString()}')),
            );
         }
      } finally {
        // Siempre reinicia el contador de reintentos y reinicia el temporizador primario después de manejar el timeout final
        _retryCount = 0;
        _startPrimaryTimer();
      }
    }


  // Método dispose para cancelar temporizadores cuando el provider ya no es necesario
  @override
  void dispose() {
    _cancelAllTimers();
    debugPrint('AlertSystemProvider disposed.');
    super.dispose();
  }
} */
