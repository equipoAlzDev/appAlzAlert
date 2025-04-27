import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:AlzAlert/models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel _user = UserModel.empty();
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Referencias a Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para cargar los datos del usuario actual
  Future<void> loadUserData() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final docSnapshot = await _firestore.collection('users').doc(currentUser.uid).get();
      
      if (docSnapshot.exists) {
        _user = UserModel.fromMap(currentUser.uid, docSnapshot.data()!);
      } else {
        // Si el documento no existe, creamos uno nuevo con los datos básicos
        _user = UserModel(
          id: currentUser.uid,
          name: currentUser.displayName ?? '',
          address: '',
        );
      }
    } catch (e) {
      _error = 'Error al cargar los datos del usuario: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
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
      await _firestore.collection('users').doc(currentUser.uid).set(
        _user.toMap(),
        SetOptions(merge: true),
      );

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
    notifyListeners();
  }
}