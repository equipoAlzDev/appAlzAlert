import 'package:flutter/material.dart';
import 'package:pruebavercel/theme/app_theme.dart';

class AlertDialogScreen extends StatefulWidget {
  const AlertDialogScreen({super.key});

  @override
  State<AlertDialogScreen> createState() => _AlertDialogScreenState();
}

class _AlertDialogScreenState extends State<AlertDialogScreen> {
  bool _isTimerActive = false;
  int _remainingSeconds = 600; // 10 minutos

  @override
  void initState() {
    super.initState();
    // Iniciar sonido de alerta
  }

  void _respondYes() {
    // Implementar respuesta positiva
    Navigator.pop(context);
  }

  void _respondNo() {
    // Implementar respuesta negativa (enviar alerta)
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}

