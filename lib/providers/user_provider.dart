import 'package:alzalert/main.dart';
import 'package:alzalert/providers/alert_system_provider.dart';
import 'package:alzalert/providers/contacto_emergencia_provider.dart';
import 'package:alzalert/providers/location_history_provider.dart';
import 'package:alzalert/providers/medical_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alzalert/models/user_model.dart';
import 'package:provider/provider.dart';

enum NavigationContext { registration, editing }

class UserProvider extends ChangeNotifier {
  UserModel _user = UserModel.empty();
  bool _isLoading = false;
  String? _error;
  NavigationContext _navigationContext = NavigationContext.registration;

  UserModel get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  NavigationContext get navigationContext => _navigationContext;

  bool get isNewUser => _user.name.isEmpty || _user.address.isEmpty;

  String get buttonText =>
      _navigationContext == NavigationContext.registration
          ? 'Continuar'
          : 'Guardar';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void setNavigationContext(NavigationContext context) {
    _navigationContext = context;
    notifyListeners();
  }

  Future<void> loadUserData() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final docSnapshot =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (docSnapshot.exists) {
        _user = UserModel.fromMap(currentUser.uid, docSnapshot.data()!);

        if (!isNewUser) {
          _navigationContext = NavigationContext.editing;
        }
      } else {
        _user = UserModel(
          id: currentUser.uid,
          name: currentUser.displayName ?? '',
          address: '',
        );
        _navigationContext = NavigationContext.registration;
      }
    } catch (e) {
      _error = 'Error al cargar los datos del usuario: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  LocationHistoryProvider? _getLocationHistoryProvider() {
    try {
      return navigatorKey.currentContext != null
          ? Provider.of<LocationHistoryProvider>(
            navigatorKey.currentContext!,
            listen: false,
          )
          : null;
    } catch (e) {
      debugPrint('Error al obtener LocationHistoryProvider: $e');
      return null;
    }
  }

  Future<void> updatePersonalInfo({
    required String name,
    DateTime? birthDate,
    required String address,
    String? profileImageUrl,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = _user.copyWith(
        name: name,
        birthDate: birthDate,
        address: address,
        profileImageUrl: profileImageUrl,
      );

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .set(_user.toMap(), SetOptions(merge: true));
      await currentUser.updateDisplayName(name);
    } catch (e) {
      _error = 'Error al actualizar los datos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfileImage(String imageUrl) async {
    await updatePersonalInfo(
      name: _user.name,
      birthDate: _user.birthDate,
      address: _user.address,
      profileImageUrl: imageUrl,
    );
  }

  void clearUser() {
    _user = UserModel.empty();
    if (navigatorKey.currentContext != null) {
      final alertProvider = Provider.of<AlertSystemProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );

      final locationProvider = Provider.of<LocationHistoryProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );

      final contactosProvider = Provider.of<ContactoEmergenciaProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      contactosProvider.resetContactos();
      try {
        final medicalInfoProvider = Provider.of<MedicalInfoProvider>(
          navigatorKey.currentContext!,
          listen: false,
        );
        medicalInfoProvider.clearMedicalInfo();
      } catch (e) {
        debugPrint('Error al limpiar la información médica: $e');
      }
    }
    notifyListeners();
  }

  String getNextRoute() {
    switch (_navigationContext) {
      case NavigationContext.registration:
        if (_user.name.isEmpty || _user.address.isEmpty) {
          return '/medical-info';
        } else {
          // Determinar siguiente pantalla en el registro
          return '/emergency-contacts';
        }
      case NavigationContext.editing:
        // Siempre regresar al perfil cuando se edita
        return '/profile';
    }
  }
}
