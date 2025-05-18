// lib/providers/location_history_provider.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location_entry.dart';
import 'package:geocoding/geocoding.dart'; // Necesario para geocodificación inversa

class LocationHistoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<LocationEntry> _locationHistory = [];
  bool _isLoading = false;

  List<LocationEntry> get locationHistory => _locationHistory;
  bool get isLoading => _isLoading;

  // Agrega una nueva entrada de ubicación al historial del usuario en Firestore.
  Future<void> addLocationEntry(String userId, double latitude, double longitude) async {
    if (userId.isEmpty) {
      debugPrint('User ID is empty. Cannot add location entry.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Obtener la dirección a partir de las coordenadas (geocodificación inversa)
      String address = 'Ubicación Desconocida';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          address = '${place.street}\n${place.locality},${place.country}';
        }
      } catch (e) {
        debugPrint('Error en geocodificación inversa: $e');
      }

      // Crear un nuevo documento en la colección 'locationHistory'
      final locationData = {
        'userId': userId,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'timestamp': Timestamp.now(),
      };

      // Escribir en Firestore
      await _firestore.collection('locationHistory').add(locationData);
      
      // Actualizar la lista local y notificar a los oyentes
      final newEntry = LocationEntry(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}', // ID temporal hasta que se recargue
        userId: userId,
        latitude: latitude,
        longitude: longitude,
        address: address,
        timestamp: DateTime.now(),
      );
      
      _locationHistory.insert(0, newEntry); // Agregar al principio de la lista
      _isLoading = false;
      notifyListeners();
      debugPrint('Entrada de ubicación agregada: $address ($latitude, $longitude)');
    } catch (e) {
      _isLoading = false;
      debugPrint('Error al agregar entrada de ubicación: $e');
    }
  }

  // Carga el historial de ubicaciones para un usuario específico desde Firestore.
  Future<void> fetchLocationHistory(String userId) async {
    if (userId.isEmpty) {
      _locationHistory = [];
      notifyListeners();
      debugPrint('User ID is empty. Cannot fetch location history.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Cargando historial de ubicaciones para usuario: $userId');
      final querySnapshot = await _firestore
          .collection('locationHistory')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      debugPrint('Documentos encontrados: ${querySnapshot.docs.length}');
      _locationHistory = querySnapshot.docs
          .map((doc) => LocationEntry.fromFirestore(doc))
          .toList();
      
      _isLoading = false;
      notifyListeners();
      debugPrint('Historial de ubicaciones cargado exitosamente');
    } catch (e) {
      _isLoading = false;
      debugPrint('Error al cargar historial de ubicaciones: $e');
      notifyListeners();
    }
  }
}