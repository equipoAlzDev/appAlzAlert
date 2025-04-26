import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pruebavercel/providers/alert_system_provider.dart';
import 'package:pruebavercel/theme/app_theme.dart';

class AlertDialogScreen extends StatefulWidget {
  const AlertDialogScreen({super.key});

  @override
  State<AlertDialogScreen> createState() => _AlertDialogScreenState();
}

class _AlertDialogScreenState extends State<AlertDialogScreen> {
  // Establecemos el temporizador a 60 segundos (1 minuto)
  int _remainingSeconds = 60;
  Timer? _countdownTimer;
  
  @override
  void initState() {
    super.initState();
    // Iniciar sonido de alerta (puedes implementar esto más adelante)
    
    // Iniciar el temporizador de cuenta regresiva una única vez
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--; // Decrementa normalmente
          } else {
            timer.cancel();
            _respondNo(); // Cierra al llegar a 0
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _respondYes() {
    // Cancelamos el temporizador para evitar fugas de memoria
    _countdownTimer?.cancel();
    
    // Reiniciamos el temporizador de verificación
    if (mounted) {
      final alertSystemProvider = Provider.of<AlertSystemProvider>(context, listen: false);
      alertSystemProvider.resetAlertTimer(context);
    }
    
    // Salimos de esta pantalla
    Navigator.of(context).pop();
  }

  void _respondNo() {
    // Cancelamos el temporizador
    _countdownTimer?.cancel();
    
    // Aquí implementaríamos la lógica para enviar una alerta de emergencia
    // Podríamos llamar a la función de envío de SMS de MainHomeScreen
    
    // Salimos de esta pantalla
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String get _formattedTime {
    final minutes = (_remainingSeconds / 60).floor();
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // Importante: cancelar el temporizador cuando se destruye el widget
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Evitar que el usuario salga con el botón de retroceso sin responder
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.9),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: AppTheme.primaryWhite,
                    size: 80,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '¿Te encuentras bien?',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.primaryWhite,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _formattedTime,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: _remainingSeconds <= 10 ? AppTheme.secondaryRed : AppTheme.primaryWhite,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 80,
                          child: ElevatedButton(
                            onPressed: _respondYes,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              'SÍ',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: SizedBox(
                          height: 80,
                          child: ElevatedButton(
                            onPressed: _respondNo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryRed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              'NO',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

