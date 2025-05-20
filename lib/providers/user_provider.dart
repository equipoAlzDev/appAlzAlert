import 'package:alzalert/main.dart';
import 'package:alzalert/providers/alert_system_provider.dart';
import 'package:alzalert/providers/contacto_emergencia_provider.dart';
import 'package:alzalert/providers/location_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alzalert/models/user_model.dart';
import 'package:provider/provider.dart';

// Enum para definir los contextos de navegación
enum NavigationContext {
  registration, // Durante el proceso de registro
  editing, // Editando información existente
}

class UserProvider extends ChangeNotifier {
  UserModel _user = UserModel.empty();
  bool _isLoading = false;
  String? _error;
  NavigationContext _navigationContext = NavigationContext.registration;

  // Getters
  UserModel get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  NavigationContext get navigationContext => _navigationContext;

  // Getter para determinar si es un usuario nuevo
  bool get isNewUser => _user.name.isEmpty || _user.address.isEmpty;

  // Getter para determinar texto del botón
  String get buttonText =>
      _navigationContext == NavigationContext.registration
          ? 'Continuar'
          : 'Guardar';

  // Referencias a Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para establecer el contexto de navegación
  void setNavigationContext(NavigationContext context) {
    _navigationContext = context;
    notifyListeners();
  }

  // Método para cargar los datos del usuario actual
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

        // Si el usuario ya tiene datos completos, probablemente está editando
        if (!isNewUser) {
          _navigationContext = NavigationContext.editing;
        }
      } else {
        // Si el documento no existe, creamos uno nuevo con los datos básicos
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

  // Método para obtener el LocationHistoryProvider
  LocationHistoryProvider? _getLocationHistoryProvider() {
    try {
      // Intentar obtener el provider desde el árbol de widgets
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

  // Método para actualizar los datos personales del usuario
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
      // Actualizamos el modelo local
      _user = _user.copyWith(
        name: name,
        birthDate: birthDate,
        address: address,
        profileImageUrl: profileImageUrl,
      );

      // Guardamos en Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .set(_user.toMap(), SetOptions(merge: true));

      // También actualizamos el displayName en Firebase Auth
      await currentUser.updateDisplayName(name);
    } catch (e) {
      _error = 'Error al actualizar los datos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para actualizar solo la URL de la imagen de perfil
  Future<void> updateProfileImage(String imageUrl) async {
    await updatePersonalInfo(
      name: _user.name,
      birthDate: _user.birthDate,
      address: _user.address,
      profileImageUrl: imageUrl,
    );
  }

  // Método para limpiar los datos cuando el usuario cierra sesión
  void clearUser() {
    _user = UserModel.empty();
    // Limpiar datos en otros providers
    if (navigatorKey.currentContext != null) {
      // Limpiar datos de alertas
      final alertProvider = Provider.of<AlertSystemProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );

      // Limpiar historial de ubicaciones
      final locationProvider = Provider.of<LocationHistoryProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );

      // Limpiar contactos de emergencia
      final contactosProvider = Provider.of<ContactoEmergenciaProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      contactosProvider.resetContactos();
    }
    notifyListeners();
  }

  // Método para obtener la ruta de navegación apropiada
  String getNextRoute() {
    switch (_navigationContext) {
      case NavigationContext.registration:
        // Lógica del flujo de registro
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
