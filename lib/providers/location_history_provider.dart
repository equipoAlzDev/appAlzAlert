import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location_entry.dart';
import 'package:geocoding/geocoding.dart';

class LocationHistoryProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<LocationEntry> _locationHistory = [];
  bool _isLoading = false;

  List<LocationEntry> get locationHistory => _locationHistory;
  bool get isLoading => _isLoading;

  Future<void> addLocationEntry(
    String userId,
    double latitude,
    double longitude,
  ) async {
    if (userId.isEmpty) {
      debugPrint('User ID is empty. Cannot add location entry.');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      String address = 'Ubicación Desconocida';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          latitude,
          longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          address = '${place.street}\n${place.locality},${place.country}';
        }
      } catch (e) {
        debugPrint('Error en geocodificación inversa: $e');
      }

      final locationData = {
        'userId': userId,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'timestamp': Timestamp.now(),
      };

      await _firestore.collection('locationHistory').add(locationData);

      final newEntry = LocationEntry(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        latitude: latitude,
        longitude: longitude,
        address: address,
        timestamp: DateTime.now(),
      );

      _locationHistory.insert(0, newEntry);
      _isLoading = false;
      notifyListeners();
      debugPrint(
        'Entrada de ubicación agregada: $address ($latitude, $longitude)',
      );
    } catch (e) {
      _isLoading = false;
      debugPrint('Error al agregar entrada de ubicación: $e');
    }
  }

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

      final querySnapshot =
          await _firestore
              .collection('locationHistory')
              .where('userId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .get();

      debugPrint('Documentos encontrados: ${querySnapshot.docs.length}');

      _locationHistory =
          querySnapshot.docs
              .where((doc) {
                final data = doc.data();
                final docUserId = data['userId'] as String?;
                final matchesUser = docUserId == userId;

                if (!matchesUser) {
                  debugPrint(
                    'Se encontró un documento con userId incorrecto: $docUserId, esperado: $userId',
                  );
                }

                return matchesUser;
              })
              .map((doc) => LocationEntry.fromFirestore(doc))
              .toList();

      _isLoading = false;
      notifyListeners();
      debugPrint(
        'Historial de ubicaciones cargado exitosamente: ${_locationHistory.length} entradas',
      );
    } catch (e) {
      _isLoading = false;
      debugPrint('Error al cargar historial de ubicaciones: $e');
      notifyListeners();
    }
  }
}
