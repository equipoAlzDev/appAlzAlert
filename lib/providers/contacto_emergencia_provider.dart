import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pruebavercel/models/contacto_emergencia_model.dart';

class ContactoEmergenciaProvider extends ChangeNotifier {
  final List<ContactoEmergenciaModel> _contactos = [];
  bool _contactosCargados = false;

  List<ContactoEmergenciaModel> get contactos => _contactos;

  bool get contactosCargados => _contactosCargados;

  final _db = FirebaseFirestore.instance.collection('contactos_emergencia');

  Future<void> cargarContactos(String userId) async {
    if (_contactosCargados) return; // No volver a cargar si ya están cargados

    final snapshot = await _db.where('userId', isEqualTo: userId).get();
    _contactos.clear();
    for (var doc in snapshot.docs) {
      _contactos.add(ContactoEmergenciaModel.fromMap(doc.id, doc.data()));
    }
    _contactosCargados = true;
    notifyListeners();
  }

  Future<void> agregarContacto(
    ContactoEmergenciaModel contacto,
    String userId,
  ) async {
    final nuevo = contacto.copyWith(userId: userId);
    final docRef = await _db.add(nuevo.toMap());

    _contactos.add(nuevo.copyWith(id: docRef.id));
    notifyListeners();
  }

  Future<void> editarContacto(ContactoEmergenciaModel contacto) async {
    await _db.doc(contacto.id).update(contacto.toMap());
    final index = _contactos.indexWhere((c) => c.id == contacto.id);
    if (index != -1) {
      _contactos[index] = contacto;
      notifyListeners();
    }
  }

  Future<void> eliminarContacto(String contactoId, String userId) async {
    final index = _contactos.indexWhere(
      (c) => c.id == contactoId && c.userId == userId,
    );
    if (index == -1) return;// No se encontró el contacto

    // elimina en Firestore y en memoria
    await _db.doc(contactoId).delete();
    _contactos.removeAt(index);
    notifyListeners();
  }

  // desmarcar el contacto primario actual y marcar el nuevo
  Future<void> eliminarContactosPrimariosExcepto(
    String contactoId,
    String userId,
  ) async {
    // actualiza los contactos del usuario actual en memoria
    for (final contacto
        in _contactos
            .where(
              (c) => c.userId == userId && c.isPrimary && c.id != contactoId,
            )
            .toList()) {
      final actualizado = contacto.copyWith(isPrimary: false);
      final idx = _contactos.indexWhere((c) => c.id == actualizado.id);
      _contactos[idx] = actualizado;
    }

    //  actualiza en Firestore los docs de este mismo userId
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
  }
}
