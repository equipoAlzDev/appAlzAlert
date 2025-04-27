/* import 'dart:async';
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

 */




import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pruebavercel/providers/alert_system_provider.dart';
import 'package:pruebavercel/theme/app_theme.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pruebavercel/providers/user_provider.dart';
import 'package:pruebavercel/providers/contacto_emergencia_provider.dart';

class AlertDialogScreen extends StatefulWidget {
  const AlertDialogScreen({super.key});

  @override
  State<AlertDialogScreen> createState() => _AlertDialogScreenState();
}

class _AlertDialogScreenState extends State<AlertDialogScreen> {
  // Establecemos el temporizador a 60 segundos (1 minuto)
  int _remainingSeconds = 60;
  Timer? _countdownTimer;
  bool _isSendingSMS = false;
  final Telephony telephony = Telephony.instance;
  final String _emergencyNumber = "3157042961"; // Número de emergencia predeterminado
  
  @override
  void initState() {
    super.initState();
    // Iniciar sonido de alerta (puedes implementar esto más adelante)
    
    // Iniciar el temporizador de cuenta regresiva una única vez
    _startCountdownTimer();
    
    // Inicializar permisos de telefonía
    _initializeTelephony();
  }

  Future<void> _initializeTelephony() async {
    // Verificar si el dispositivo puede enviar SMS
    final bool? canSendSms = await telephony.requestPhoneAndSmsPermissions;
    if (canSendSms != true) {
      debugPrint('El dispositivo no puede enviar SMS');
    }
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

  /* void _respondNo() async {
    // Cancelamos el temporizador
    _countdownTimer?.cancel();
    
    // Implementamos la lógica para enviar una alerta de emergencia
    await _sendEmergencySMS();
    
    // Salimos de esta pantalla
    if (mounted) {
      Navigator.of(context).pop();
    }
  } */

 void _respondNo() async {
  _countdownTimer?.cancel();
  
  // Enviar SMS antes de cerrar la pantalla
  await _sendEmergencySMS();
  
  if (mounted) {
    Navigator.of(context).pop();
  }
}

Future<void> _sendEmergencySMS() async {
  if (!mounted) return;
  
  setState(() => _isSendingSMS = true);

  try {
    if (!await _checkSMSPermissions()) return;

    // Obtener proveedores con contexto válido
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id ?? '';
    
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario no identificado')));
      return;
    }

    final contactosProvider = Provider.of<ContactoEmergenciaProvider>(context, listen: false);
    final contactos = contactosProvider.contactos.where((c) => c.userId == userId).toList();
    
    final message = '¡EMERGENCIA! ${userProvider.user?.name ?? 'Usuario'} ha referido no estar bien, puede que necesite ayuda.';

    List<String> numeros = [];
    if (contactos.isNotEmpty) {
      numeros = contactos.map((c) => c.phone).toList();
    } else {
      numeros.add(_emergencyNumber);
    }

    // Enviar todos los SMS en paralelo
    await Future.wait(
      numeros.map((numero) => telephony.sendSms(to: numero, message: message))
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alertas enviadas')));
    }
  } catch (e) {
    debugPrint('Error enviando SMS: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')));
    }
  } finally {
    if (mounted) setState(() => _isSendingSMS = false);
  }
}

  /* Future<void> _sendEmergencySMS() async {
    if (mounted) {
      setState(() {
        _isSendingSMS = true;
      });
    }

    try {
      // Verificar permisos
      if (!await _checkSMSPermissions()) {
        return;
      }

      // Obtener nombre del usuario
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userName = userProvider.user?.name ?? '';
      final userId = userProvider.user?.id ?? '';
      
      // Obtener contactos de emergencia
      final contactosProvider = Provider.of<ContactoEmergenciaProvider>(context, listen: false);
      final contactos = contactosProvider.contactos.where((c) => c.userId == userId).toList();
      
      // Mensaje de emergencia
      final message = '¡EMERGENCIA! ${userName.isNotEmpty ? userName : 'Usuario'} no respondió a la alerta de verificación y necesita ayuda urgente';
      
      // Si hay contactos, enviar a todos ellos (primero al contacto primario si existe)
      if (contactos.isNotEmpty) {
        // Buscar si hay un contacto primario
        final contactoPrimario = contactos.firstWhere(
          (c) => c.isPrimary, 
          orElse: () => contactos.first // Si no hay primario, usar el primero
        );
        
        // Enviar primero al contacto principal o al primero de la lista
        await telephony.sendSms(
          to: contactoPrimario.phone,
          message: message,
        );
        
        // Luego enviar a los demás contactos (si hay más de uno)
        for (final contacto in contactos) {
          // Omitir el que ya se envió
          if (contacto.id != contactoPrimario.id) {
            await telephony.sendSms(
              to: contacto.phone,
              message: message,
            );
          }
        }
      } else {
        // Si no hay contactos registrados, usar el número predeterminado
        await telephony.sendSms(
          to: _emergencyNumber,
          message: message,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alerta enviada a contactos de emergencia'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar alerta: ${e.toString()}'),
            backgroundColor: Colors.red,
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
  } */

  /* Future<bool> _checkSMSPermissions() async {
    // Verificar permiso para SMS
    var smsStatus = await Permission.sms.status;
    if (!smsStatus.isGranted) {
      smsStatus = await Permission.sms.request();
    }

    // Verificar permiso para teléfono (necesario para Telephony)
    var phoneStatus = await Permission.phone.status;
    if (!phoneStatus.isGranted) {
      phoneStatus = await Permission.phone.request();
    }

    return smsStatus.isGranted && phoneStatus.isGranted;
  } */
  Future<bool> _checkSMSPermissions() async {
    final smsStatus = await Permission.sms.status;
    final phoneStatus = await Permission.phone.status;
    
    debugPrint('Estado permisos: SMS - $smsStatus, Teléfono - $phoneStatus');
    
    return smsStatus.isGranted && phoneStatus.isGranted;
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
                  _isSendingSMS 
                  ? const CircularProgressIndicator(color: AppTheme.primaryWhite)
                  : Row(
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
                  if (_isSendingSMS) 
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Text(
                        'Enviando alerta de emergencia...',
                        style: TextStyle(color: AppTheme.primaryWhite),
                      ),
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