// lib/models/location_entry.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationEntry {
  final String id; // ID del documento en Firestore
  final String userId;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  LocationEntry({
    required this.id,
    required this.userId,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  // Constructor de fábrica para crear una instancia de LocationEntry
  // a partir de un DocumentSnapshot de Firestore.
  factory LocationEntry.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return LocationEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      address: data['address'] ?? 'Ubicación Desconocida',
      latitude: data['latitude'] ?? 0.0,
      longitude: data['longitude'] ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // Método para convertir una instancia de LocationEntry
  // a un mapa que se pueda guardar en Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // Método copyWith para crear una copia de la instancia con valores modificados.
  // Útil para actualizar el ID después de guardar en Firestore.
  LocationEntry copyWith({
    String? id,
    String? userId,
    String? address,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
  }) {
    return LocationEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
