class ContactoEmergenciaModel {
  final String id;
  final String name;
  final String phone;
  final String relation;
  final bool isPrimary;
  final String? userId;

  ContactoEmergenciaModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.relation,
    required this.isPrimary,
    required this.userId,
  });


  factory ContactoEmergenciaModel.empty() {
    return ContactoEmergenciaModel(
      id: '',
      name: '',
      phone: '',
      relation: '',
      isPrimary: false,
      userId: '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'relation': relation,
      'isPrimary': isPrimary,
      'userId': userId,
    };
  }

  factory ContactoEmergenciaModel.fromMap(String id, Map<String, dynamic> map) {
    return ContactoEmergenciaModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      relation: map['relation'] ?? '',
      isPrimary: map['isPrimary'] ?? false,
      userId: map['userId'] ?? '',
    );
  }

  ContactoEmergenciaModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? relation,
    bool? isPrimary,
    String? userId,
  }) {
    return ContactoEmergenciaModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relation: relation ?? this.relation,
      isPrimary: isPrimary ?? this.isPrimary,
      userId: userId ?? this.userId,
    );
  }
}

