import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alzalert/providers/alert_system_provider.dart';
import 'package:alzalert/theme/app_theme.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:alzalert/providers/contacto_emergencia_provider.dart';

// Remove the global declaration of navigatorKey here.
// It's no longer needed in this file.
// late GlobalKey<NavigatorState> navigatorKey; // REMOVE THIS LINE

class AlertDialogScreen extends StatefulWidget {
  final bool isRetry;
  const AlertDialogScreen({super.key, this.isRetry = false});

  @override
  State createState() => _AlertDialogScreenState();
}

class _AlertDialogScreenState extends State<AlertDialogScreen> {
  // Establecemos el temporizador a 60 segundos (1 minuto)
  late int _remainingSeconds;
  Timer? _countdownTimer;
  // We no longer need _isSendingSMS state here, as SMS is sent by the provider
  // bool _isSendingSMS = false; // REMOVE THIS LINE
  final Telephony telephony = Telephony.instance;
  // Número de emergencia predeterminado (usado como fallback if no contacts)
  // REMOVED: final String _emergencyNumber = "3157042961";

  @override
  void initState() {
    // The countdown timer in the dialog is always 60 seconds for user response
    _remainingSeconds = 60;
    super.initState();
    // Iniciar sonido de alerta (puedes implementar esto más adelante)

    // Iniciar el temporizador de cuenta regresiva una única vez
    _startCountdownTimer();

    // Inicializar permisos de telefonía (check, not request here)
    // This check is still useful to inform the user if SMS won't work
    _initializeTelephonyCheck();
  }

  // Check telephony capabilities and permissions status (do not request here)
  Future<void> _initializeTelephonyCheck() async {
    final bool? canSendSms = await telephony.isSmsCapable;
    if (canSendSms != true) {
      debugPrint('El dispositivo no puede enviar SMS o no tiene permisos.');
      // Consider showing a message to the user about SMS not being available/permitted
    }
     // Also check permission status directly
    final smsStatus = await Permission.sms.status;
    final phoneStatus = await Permission.phone.status;
    debugPrint('Estado permisos SMS en Dialog: SMS - $smsStatus, Teléfono - $phoneStatus');
     if (!smsStatus.isGranted || !phoneStatus.isGranted) {
        debugPrint('SMS or Phone permissions not granted.');
        // Inform the user that SMS alerts may not work without permissions
     }
  }


  void _startCountdownTimer() {
      _countdownTimer?.cancel(); // Cancel any existing timer before starting a new one
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) { // Check if the widget is still in the widget tree
          setState(() {
            if (_remainingSeconds > 0) {
              _remainingSeconds--;
            } else {
              timer.cancel(); // Stop the timer when it reaches zero
              // Pop the dialog with the appropriate result based on retry state
              if (widget.isRetry) {
                 // If it was a retry and timed out, pop with 'final_timeout'.
                 // The provider will handle sending the SMS.
                 debugPrint('Retry alert timed out. Popping with final_timeout.');
                 Navigator.pop(context, 'final_timeout');
              } else {
                 // If it was the first alert and timed out, pop with 'timeout'.
                 // The provider will handle starting the secondary timer.
                 debugPrint('Primary alert timed out. Popping with timeout.');
                 Navigator.pop(context, 'timeout');
              }
            }
          });
        } else {
          // If the widget is unmounted before the timer finishes, cancel the timer
          timer.cancel();
           debugPrint('Countdown timer cancelled because widget is unmounted.');
        }
      });
    }

  // Function called when the user responds 'SÍ'
  void _respondYes() {
    _countdownTimer?.cancel(); // Cancel the countdown timer
    // Reset the alert timer in the provider
    if (mounted) {
      // Access the provider using the context available in the widget
      final alertSystemProvider = Provider.of<AlertSystemProvider>(context, listen: false);
      alertSystemProvider.resetAlertTimer(); // This restarts the appropriate timer
    }
    // Pop the dialog
    debugPrint('User responded YES. Popping dialog.');
    Navigator.of(context).pop(); // No specific result needed for 'Yes'
  }

  // Function called when the user responds 'NO'
  void _respondNo() async {
    _countdownTimer?.cancel(); // Cancel the countdown timer
    // DO NOT send SMS here. The provider will handle it.
    // await _sendEmergencySMS(); // REMOVE THIS LINE
    // Pop the dialog with 'manual_no' result
    debugPrint('User responded NO. Popping with manual_no.');
    if (mounted) {
      Navigator.pop(context, 'manual_no');
    }
  }

  // Function to send emergency SMS - This method is now only called by the provider
  // It's kept here for completeness but is not triggered by user actions in this dialog.
  // Consider moving SMS sending logic entirely to the provider or a dedicated service.
  // REMOVED: Future<void> _sendEmergencySMS() async { ... }

  // Check if SMS and Phone permissions are granted
  Future<bool> _checkSMSPermissions() async {
    final smsStatus = await Permission.sms.status;
    final phoneStatus = await Permission.phone.status;
    debugPrint('Checking permissions before sending SMS: SMS - $smsStatus, Teléfono - $phoneStatus');
    // Return true only if both permissions are granted
    return smsStatus.isGranted && phoneStatus.isGranted;
  }

  // Formats the remaining seconds into MM:SS string
  String get _formattedTime {
    final minutes = (_remainingSeconds / 60).floor();
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // Important: cancel the timer when the widget is disposed to prevent memory leaks
    _countdownTimer?.cancel();
    debugPrint('AlertDialogScreen disposed, countdown timer cancelled.');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent the user from dismissing the dialog using the back button
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.9), // Semi-transparent dark background
        body: SafeArea( // Avoid content going under system bars
          child: Center( // Center the content vertically and horizontally
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Center column content vertically
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: AppTheme.primaryWhite, // Use white color from your theme
                    size: 80,
                  ),
                  const SizedBox(height: 32),
                  // Display text based on whether it's a retry
                  Text(
                    widget.isRetry
                        ? '¡Última verificación!\n¿Te encuentras bien?'
                        : '¿Te encuentras bien?',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTheme.primaryWhite,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Display the countdown timer
                  Text(
                    _formattedTime,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          // Change color to red when time is low
                          color: _remainingSeconds <= 10 ? AppTheme.secondaryRed : AppTheme.primaryWhite,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 48),
                  // Show progress indicator while sending SMS, otherwise show buttons
                  // We removed _isSendingSMS state, so we can remove this conditional rendering
                  /* _isSendingSMS
                  ? const CircularProgressIndicator(color: AppTheme.primaryWhite)
                  : */ Row( // Always show buttons now, unless you add a different state
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute space evenly
                    children: [
                      // 'SÍ' Button
                      Expanded( // Make button take available space
                        child: SizedBox(
                          height: 80, // Fixed height for the button
                          child: ElevatedButton(
                            onPressed: _respondYes,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryGreen, // Green color from theme
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15), // Rounded corners
                              ),
                            ),
                            child: const Text(
                              'SÍ',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // Text color
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24), // Space between buttons
                      // 'NO' Button
                      Expanded( // Make button take available space
                        child: SizedBox(
                          height: 80, // Fixed height for the button
                          child: ElevatedButton(
                            onPressed: _respondNo, // This now only pops the dialog
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryRed, // Red color from theme
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15), // Rounded corners
                              ),
                            ),
                            child: const Text(
                              'NO',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white, // Text color
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Message displayed while sending SMS - this message might be less relevant here now
                  // as SMS is sent by the provider. You might remove or adjust this.
                  /* if (_isSendingSMS)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Text(
                        'Enviando alerta de emergencia...',
                        style: TextStyle(color: AppTheme.primaryWhite),
                      ),
                    ), */
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
