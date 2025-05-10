import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:AlzAlert/providers/contacto_emergencia_provider.dart';
import 'package:AlzAlert/providers/user_provider.dart';
import 'package:AlzAlert/screens/alerts/alert_dialog_screen.dart';

class AlertSystemProvider with ChangeNotifier {
  final GlobalKey<NavigatorState> _navigatorKey; // Clave para navegación de diálogos

  bool _isAlertSystemActive = true;       // Estado del sistema de alertas
  bool _isSecondaryTimer = false;        // Indica si está corriendo el temporizador secundario
  bool _isDialogShown = false;           // Evita mostrar múltiples diálogos
  int _retryCount = 0;                   // Contador de reintentos

  Timer? _primaryTimer;
  Timer? _secondaryTimer;

  int _primaryInterval = 20;  // Intervalo primario en segundos (prueba)
  int _secondaryInterval = 10; // Intervalo secundario en segundos (prueba)

  AlertSystemProvider(this._navigatorKey) {
    if (_isAlertSystemActive) _startPrimaryTimer();
  }

  bool get isAlertSystemActive => _isAlertSystemActive;
  int get configuredPrimaryIntervalSeconds => _primaryInterval;
  int get configuredSecondaryIntervalSeconds => _secondaryInterval;

  /// Activa o desactiva el sistema de alertas
  void toggleAlertSystem() {
    _isAlertSystemActive = !_isAlertSystemActive;
    if (_isAlertSystemActive) {
      _startPrimaryTimer();
    } else {
      _cancelAllTimers();
    }
    notifyListeners();
  }

  /// Configura nuevo intervalo primario y reinicia temporizador si corresponde
  void setPrimaryInterval(int seconds) {
    _primaryInterval = seconds;
    if (_isAlertSystemActive && !_isSecondaryTimer) _startPrimaryTimer();
    notifyListeners();
  }

  /// Configura nuevo intervalo secundario y reinicia temporizador si corresponde
  void setSecondaryInterval(int seconds) {
    _secondaryInterval = seconds;
    if (_isAlertSystemActive && _isSecondaryTimer) _startSecondaryTimer();
    notifyListeners();
  }

  /// Reinicia el temporizador activo (primario o secundario)
  void resetAlertTimer() {
    _cancelAllTimers();
    if (_isSecondaryTimer) {
      _startSecondaryTimer();
    } else {
      _startPrimaryTimer();
    }
  }

  void _startPrimaryTimer() {
    _cancelAllTimers();
    _isSecondaryTimer = false;
    _primaryTimer = Timer(Duration(seconds: _primaryInterval), _showAlertDialog);
  }

  void _startSecondaryTimer() {
    _cancelAllTimers();
    _isSecondaryTimer = true;
    _secondaryTimer = Timer(Duration(seconds: _secondaryInterval), _showAlertDialog);
  }

  void _cancelAllTimers() {
    _primaryTimer?.cancel();
    _secondaryTimer?.cancel();
  }

  /// Muestra el diálogo de alerta y maneja su resultado
  void _showAlertDialog() {
    if (_isDialogShown || _navigatorKey.currentState == null) return;
    _isDialogShown = true;

    _navigatorKey.currentState!.push(
      MaterialPageRoute<bool>(builder: (context) => AlertDialogScreen(isRetry: _retryCount > 0)),
    ).then((result) {
      _isDialogShown = false;
      if (!_isAlertSystemActive) return;

      switch (result) {
        case 'timeout':
          _retryCount++;
          _retryCount == 1 ? _startSecondaryTimer() : _handleFinalTimeout();
          break;
        case 'manual_no':
        case 'final_timeout':
          _handleFinalTimeout();
          break;
        default:
          _retryCount = 0;
          _startPrimaryTimer();
      }
    });
  }

  /// Envía SMS de emergencia a contactos configurados
  Future<void> _handleFinalTimeout() async {
    _retryCount = 0;

    final context = _navigatorKey.currentContext;
    if (context == null) {
      _startPrimaryTimer();
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final contactosProvider = Provider.of<ContactoEmergenciaProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    if (userId == null) {
      _startPrimaryTimer();
      return;
    }

    final contactos = contactosProvider.contactos.where((c) => c.userId == userId).toList();
    if (contactos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay contactos de emergencia configurados.')));
      _startPrimaryTimer();
      return;
    }

    final message = '¡EMERGENCIA! ${userProvider.user?.name ?? 'Usuario'} necesita ayuda.';
    final telephony = Telephony.instance;

    // Enviar SMS en paralelo
    await Future.wait(contactos.map((c) => telephony.sendSms(to: c.phone, message: message)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alertas de emergencia enviadas.')));

    _startPrimaryTimer();
  }

  @override
  void dispose() {
    _cancelAllTimers();
    super.dispose();
  }
}
