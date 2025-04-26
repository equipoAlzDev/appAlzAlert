import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/alerts/alert_dialog_screen.dart';

class AlertSystemProvider with ChangeNotifier {
  bool _isAlertSystemActive = true;
  Timer? _alertTimer;
  final int _checkIntervalSeconds = 10;
  bool _isDialogShown = false;

  bool get isAlertSystemActive => _isAlertSystemActive;

  void toggleAlertSystem(BuildContext context) {
    _isAlertSystemActive = !_isAlertSystemActive;
    
    if (_isAlertSystemActive) {
      _startAlertTimer(context);
    } else {
      _cancelAlertTimer();
    }
    
    notifyListeners();
  }

  void setAlertSystemActive(bool value, BuildContext context) {
    _isAlertSystemActive = value;
    
    if (_isAlertSystemActive) {
      _startAlertTimer(context);
    } else {
      _cancelAlertTimer();
    }
    
    notifyListeners();
  }

  void _startAlertTimer(BuildContext context) {
    _cancelAlertTimer();
    _alertTimer = Timer(
      Duration(seconds: _checkIntervalSeconds),
      () => _showAlertDialog(context),
    );
  }

  void resetAlertTimer(BuildContext context) {
    if (_isAlertSystemActive) {
      _cancelAlertTimer();
      _startAlertTimer(context);
    }
  }

  void _cancelAlertTimer() {
    _alertTimer?.cancel();
    _alertTimer = null;
  }

  void _showAlertDialog(BuildContext context) {
    if (!_isDialogShown) {
      _isDialogShown = true;
      Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => const AlertDialogScreen()),
      ).then((_) {
        _isDialogShown = false;
        if (_isAlertSystemActive) {
          _startAlertTimer(context);
        }
      });
    }
  }

  @override
  void dispose() {
    _cancelAlertTimer();
    super.dispose();
  }
}