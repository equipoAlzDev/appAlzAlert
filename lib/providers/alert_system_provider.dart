import 'dart:async';
import 'package:AlzAlert/providers/contacto_emergencia_provider.dart';
import 'package:AlzAlert/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/alerts/alert_dialog_screen.dart';

class AlertSystemProvider with ChangeNotifier {
  bool _isAlertSystemActive = true;
  Timer? _alertTimer;
  Timer? _secondaryAlertTimer;
  int _primaryCheckInterval = 20;    // Tiempo inicial (20 segundos)
  int _secondaryCheckInterval = 10;  // Tiempo secundario (10 segundos)
  bool _isDialogShown = false;
  bool _isSecondaryTimer = false;   // Bandera para identificar el temporizador actual
  int _retryCount = 0; // Nuevo contador de reintentos

  bool get isAlertSystemActive => _isAlertSystemActive;

  void toggleAlertSystem(BuildContext context) {
    _isAlertSystemActive = !_isAlertSystemActive;
    
    if (_isAlertSystemActive) {
      _startPrimaryTimer(context);
    } else {
      _cancelAllTimers();
    }
    
    notifyListeners();
  }

  void _startPrimaryTimer(BuildContext context) {
    _cancelAllTimers();
    _isSecondaryTimer = false;
    _alertTimer = Timer(
      Duration(seconds: _primaryCheckInterval),
      () => _showAlertDialog(context),
    );
  }

  void _startSecondaryTimer(BuildContext context) {
    _cancelAllTimers();
    _isSecondaryTimer = true;
    _secondaryAlertTimer = Timer(
      Duration(seconds: _secondaryCheckInterval),
      () => _showAlertDialog(context),
    );
  }

  void resetAlertTimer(BuildContext context) {
    _cancelAllTimers();
    if (_isSecondaryTimer) {
      _startSecondaryTimer(context);
    } else {
      _startPrimaryTimer(context);
    }
  }

  void _cancelAllTimers() {
    _alertTimer?.cancel();
    _secondaryAlertTimer?.cancel();
    _alertTimer = null;
    _secondaryAlertTimer = null;
  }

  void _showAlertDialog(BuildContext context) {
      if (!_isDialogShown) {
        _isDialogShown = true;
        Navigator.push(
          context, 
          MaterialPageRoute(
            builder: (context) => AlertDialogScreen(
              isRetry: _retryCount > 0, // Pasamos si es reintento
            ),
          ),
        ).then((result) {
          _isDialogShown = false;
          if (_isAlertSystemActive) {
            if (result == 'timeout') {
              _retryCount++;
              if (_retryCount == 1) {
                _startSecondaryTimer(context);
              } else {
                _handleFinalTimeout(context);
              }
            } else {
              _retryCount = 0;
              _startPrimaryTimer(context);
            }
          }
        });
      }
    }

    void _handleFinalTimeout(BuildContext context) {
      // Lógica para enviar SMS final
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final contactosProvider = Provider.of<ContactoEmergenciaProvider>(context, listen: false);
      
      // Aquí implementarías el envío de SMS similar a _respondNo
      _retryCount = 0;
      _startPrimaryTimer(context);
    }

  // Métodos para configuración futura
  void setIntervals(int primary, int secondary) {
    _primaryCheckInterval = primary;
    _secondaryCheckInterval = secondary;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelAllTimers();
    super.dispose();
  }
}