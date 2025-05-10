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