import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final DateTime? birthDate;
  final String address;
  final String? profileImageUrl;

  UserModel({
    required this.id,
    required this.name,
    this.birthDate,
    required this.address,
    this.profileImageUrl,
  });

  // Constructor para crear un usuario vacío
  factory UserModel.empty() {
    return UserModel(id: '', name: '', address: '');
  }

  // Método para crear un objeto a partir de datos de Firestore
  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      name: data['name'] ?? '',
      birthDate:
          data['birthDate'] != null
              ? (data['birthDate'] as Timestamp).toDate()
              : null,
      address: data['address'] ?? '',
      profileImageUrl: data['profileImageUrl'],
    );
  }

  // Método para convertir el objeto a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'birthDate': birthDate,
      'address': address,
      'profileImageUrl': profileImageUrl,
    };
  }

  // Método para crear una copia del objeto con algunos campos modificados
  UserModel copyWith({
    String? name,
    DateTime? birthDate,
    String? address,
    String? profileImageUrl,
  }) {
    return UserModel(
      id: this.id,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
