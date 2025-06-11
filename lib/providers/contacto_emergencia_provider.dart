import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:alzalert/models/contacto_emergencia_model.dart';

class ContactoEmergenciaProvider extends ChangeNotifier {
  final List<ContactoEmergenciaModel> _contactos = [];
  bool _contactosCargados = false;

  List<ContactoEmergenciaModel> get contactos => _contactos;

  bool get contactosCargados => _contactosCargados;

  final _db = FirebaseFirestore.instance.collection('contactos_emergencia');

  Future<void> recargarContactos(String userId) async {
    _contactosCargados = false;
    await cargarContactos(userId);
  }

  Future<void> cargarContactos(String userId) async {
    if (_contactosCargados) return;

    try {
      final snapshot = await _db.where('userId', isEqualTo: userId).get();
      _contactos.clear();
      for (var doc in snapshot.docs) {
        _contactos.add(ContactoEmergenciaModel.fromMap(doc.id, doc.data()));
      }
      _contactosCargados = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar contactos: $e');
      _contactosCargados = false;
    }
  }

  Future<void> agregarContacto(
    ContactoEmergenciaModel contacto,
    String userId,
  ) async {
    try {
      final nuevo = contacto.copyWith(userId: userId);
      final docRef = await _db.add(nuevo.toMap());

      _contactos.add(nuevo.copyWith(id: docRef.id));
      notifyListeners();
    } catch (e) {
      debugPrint('Error al agregar contacto: $e');
    }
  }

  Future<void> editarContacto(ContactoEmergenciaModel contacto) async {
    try {
      await _db.doc(contacto.id).update(contacto.toMap());
      final index = _contactos.indexWhere((c) => c.id == contacto.id);
      if (index != -1) {
        _contactos[index] = contacto;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al editar contacto: $e');
    }
  }

  Future<void> eliminarContacto(String contactoId, String userId) async {
    try {
      await _db.doc(contactoId).delete();
      final index = _contactos.indexWhere(
        (c) => c.id == contactoId && c.userId == userId,
      );

      if (index >= 0 && index < _contactos.length) {
        _contactos.removeAt(index);
        notifyListeners();
      } else {
        await recargarContactos(userId);
      }
    } catch (e) {
      debugPrint('Error al eliminar contacto: $e');
      await recargarContactos(userId);
    }
  }

  Future<void> eliminarContactosPrimariosExcepto(
    String contactoId,
    String userId,
  ) async {
    try {
      final contactosAActualizar =
          _contactos
              .where(
                (c) => c.userId == userId && c.isPrimary && c.id != contactoId,
              )
              .toList();

      for (final contacto in contactosAActualizar) {
        final actualizado = contacto.copyWith(isPrimary: false);
        final idx = _contactos.indexWhere((c) => c.id == actualizado.id);
        if (idx >= 0 && idx < _contactos.length) {
          _contactos[idx] = actualizado;
        }
      }

      final snapshot =
          await _db
              .where('userId', isEqualTo: userId)
              .where('isPrimary', isEqualTo: true)
              .get();

      for (final doc in snapshot.docs) {
        if (doc.id != contactoId) {
          await doc.reference.update({'isPrimary': false});
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error al actualizar contactos primarios: $e');
      await recargarContactos(userId);
    }
  }

  void resetContactos() {
    _contactos.clear();
    _contactosCargados = false;
    notifyListeners();
  }
}
