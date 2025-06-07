import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationModel {
  final String name;
  final String dose;
  final String time;

  MedicationModel({required this.name, required this.dose, required this.time});

  factory MedicationModel.fromMap(Map<String, dynamic> data) {
    return MedicationModel(
      name: data['name'] ?? '',
      dose: data['dose'] ?? '',
      time: data['time'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'dose': dose, 'time': time};
  }
}

class MedicalInfoModel {
  final String diagnosis;
  final List<MedicationModel> medications;
  final String allergies;
  final String doctorName;
  final String doctorPhone;

  MedicalInfoModel({
    required this.diagnosis,
    required this.medications,
    required this.allergies,
    required this.doctorName,
    required this.doctorPhone,
  });

  // Constructor para crear información médica vacía
  factory MedicalInfoModel.empty() {
    return MedicalInfoModel(
      diagnosis: '',
      medications: [],
      allergies: '',
      doctorName: '',
      doctorPhone: '',
    );
  }

  // Método para crear un objeto a partir de datos de Firestore
  factory MedicalInfoModel.fromMap(Map<String, dynamic> data) {
    List<MedicationModel> medicationsList = [];
    if (data['medications'] != null) {
      final List<dynamic> medicationsData = data['medications'];
      medicationsList =
          medicationsData
              .map((medicationData) => MedicationModel.fromMap(medicationData))
              .toList();
    }

    return MedicalInfoModel(
      diagnosis: data['diagnosis'] ?? '',
      medications: medicationsList,
      allergies: data['allergies'] ?? '',
      doctorName: data['doctorName'] ?? '',
      doctorPhone: data['doctorPhone'] ?? '',
    );
  }

  // Método para convertir el objeto a un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'diagnosis': diagnosis,
      'medications': medications.map((med) => med.toMap()).toList(),
      'allergies': allergies,
      'doctorName': doctorName,
      'doctorPhone': doctorPhone,
    };
  }
}
