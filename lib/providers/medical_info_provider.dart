import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:alzalert/models/medical_info_model.dart';

class MedicalInfoProvider extends ChangeNotifier {
  MedicalInfoModel _medicalInfo = MedicalInfoModel.empty();
  bool _isLoading = false;
  String? _error;

  MedicalInfoModel get medicalInfo => _medicalInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> loadMedicalInfo() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final docSnapshot =
          await _firestore
              .collection('users')
              .doc(currentUser.uid)
              .collection('medical_info')
              .doc('data')
              .get();

      if (docSnapshot.exists) {
        _medicalInfo = MedicalInfoModel.fromMap(docSnapshot.data()!);
      } else {
        _medicalInfo = MedicalInfoModel.empty();
      }
    } catch (e) {
      _error = 'Error al cargar la información médica: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveMedicalInfo(MedicalInfoModel medicalInfo) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _medicalInfo = medicalInfo;
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('medical_info')
          .doc('data')
          .set(medicalInfo.toMap());
    } catch (e) {
      _error = 'Error al guardar la información médica: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMedication(MedicationModel medication) async {
    final currentMedications = List<MedicationModel>.from(
      _medicalInfo.medications,
    );
    currentMedications.add(medication);

    await saveMedicalInfo(
      MedicalInfoModel(
        diagnosis: _medicalInfo.diagnosis,
        medications: currentMedications,
        allergies: _medicalInfo.allergies,
        doctorName: _medicalInfo.doctorName,
        doctorPhone: _medicalInfo.doctorPhone,
      ),
    );
  }

  Future<void> removeMedication(int index) async {
    final currentMedications = List<MedicationModel>.from(
      _medicalInfo.medications,
    );
    if (index >= 0 && index < currentMedications.length) {
      currentMedications.removeAt(index);

      await saveMedicalInfo(
        MedicalInfoModel(
          diagnosis: _medicalInfo.diagnosis,
          medications: currentMedications,
          allergies: _medicalInfo.allergies,
          doctorName: _medicalInfo.doctorName,
          doctorPhone: _medicalInfo.doctorPhone,
        ),
      );
    }
  }

  void clearMedicalInfo() {
    _medicalInfo = MedicalInfoModel.empty();
    notifyListeners();
  }
}
