import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:AlzAlert/providers/alert_system_provider.dart';
import 'package:AlzAlert/theme/app_theme.dart';

class AlertDialogScreen extends StatefulWidget {
  final bool isRetry;

  const AlertDialogScreen({super.key, this.isRetry = false});

  @override
  State<AlertDialogScreen> createState() => _AlertDialogScreenState();
}

class _AlertDialogScreenState extends State<AlertDialogScreen> {
  late int _remainingSeconds; // Segundos restantes de la cuenta regresiva
  Timer? _countdownTimer;    // Temporizador periódico
  final Telephony telephony = Telephony.instance; // Servicio SMS

  @override
  void initState() {
    super.initState();
    _remainingSeconds = 60; // Iniciar cuenta regresiva en 60 segundos
    _startCountdownTimer(); // Comenzar temporizador
    _checkTelephonyCapabilities(); // Verificar capacidad SMS y permisos
  }

  /// Comprueba si el dispositivo puede enviar SMS y el estado de permisos
  Future<void> _checkTelephonyCapabilities() async {
    final canSend = await telephony.isSmsCapable;
    if (canSend != true) debugPrint('SMS no soportado o permisos faltantes');

    final smsPerm = await Permission.sms.status;
    final phonePerm = await Permission.phone.status;
    debugPrint('Permisos - SMS: \$smsPerm, Teléfono: \$phonePerm');
  }

  /// Inicia el temporizador que decrementa cada segundo y cierra el diálogo al llegar a cero
  void _startCountdownTimer() {
    _countdownTimer?.cancel(); // Detener temporizador previo si existe
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--; // Reducir segundos
        } else {
          timer.cancel();
          final result = widget.isRetry ? 'final_timeout' : 'timeout';
          Navigator.pop(context, result); // Cerrar diálogo con resultado
        }
      });
    });
  }

  /// Acción al pulsar 'SÍ': reinicia el temporizador en el proveedor y cierra el diálogo
  void _respondYes() {
    _countdownTimer?.cancel();
    Provider.of<AlertSystemProvider>(context, listen: false).resetAlertTimer();
    Navigator.of(context).pop();
  }

  /// Acción al pulsar 'NO': cierra el diálogo indicando respuesta manual
  void _respondNo() {
    _countdownTimer?.cancel();
    Navigator.pop(context, 'manual_no');
  }

  /// Devuelve el tiempo formateado en MM:SS
  String get _formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '\$minutes:\$seconds';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel(); // Cancelar temporizador al eliminar widget
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Impide cerrar con botón atrás
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.9), // Fondo oscuro semi-transparente
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
                  // Pregunta al usuario, varía si es reintento
                  Text(
                    widget.isRetry
                        ? '¡Última verificación!\n¿Te encuentras bien?'
                        : '¿Te encuentras bien?',
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(
                          color: AppTheme.primaryWhite,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Muestra el tiempo restante
                  Text(
                    _formattedTime,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          color: _remainingSeconds <= 10
                              ? AppTheme.secondaryRed
                              : AppTheme.primaryWhite,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 48),
                  // Botones de respuesta
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
                                color: Colors.white,
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
                                color: Colors.white,
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
