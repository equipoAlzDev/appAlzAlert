import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:alzalert/models/contacto_emergencia_model.dart';

class ContactoEmergenciaProvider extends ChangeNotifier {
  final List<ContactoEmergenciaModel> _contactos = [];
  bool _contactosCargados = false;

  List<ContactoEmergenciaModel> get contactos => _contactos;

  bool get contactosCargados => _contactosCargados;

  final _db = FirebaseFirestore.instance.collection('contactos_emergencia');

  // Método para recargar contactos forzadamente
  Future<void> recargarContactos(String userId) async {
    _contactosCargados = false;
    await cargarContactos(userId);
  }

  Future<void> cargarContactos(String userId) async {
    if (_contactosCargados) return; // No volver a cargar si ya están cargados

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
      // Se podría lanzar una excepción aquí o manejar el error de otra forma
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
      // Manejo del error
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
      // Manejo del error
    }
  }

  Future<void> eliminarContacto(String contactoId, String userId) async {
    try {
      // Primero elimina en Firestore
      await _db.doc(contactoId).delete();

      // Luego busca y elimina en memoria
      final index = _contactos.indexWhere(
        (c) => c.id == contactoId && c.userId == userId,
      );

      // Verificación adicional para evitar error de índice
      if (index >= 0 && index < _contactos.length) {
        _contactos.removeAt(index);
        notifyListeners();
      } else {
        // Si no se encuentra en memoria pero se eliminó en Firestore
        // Recargamos los contactos para sincronizar
        await recargarContactos(userId);
      }
    } catch (e) {
      debugPrint('Error al eliminar contacto: $e');
      // En caso de error, intentamos recargar para asegurar consistencia
      await recargarContactos(userId);
    }
  }

  // desmarcar el contacto primario actual y marcar el nuevo
  Future<void> eliminarContactosPrimariosExcepto(
    String contactoId,
    String userId,
  ) async {
    try {
      // Lista de contactos a actualizar para evitar modificar la lista durante la iteración
      final contactosAActualizar =
          _contactos
              .where(
                (c) => c.userId == userId && c.isPrimary && c.id != contactoId,
              )
              .toList();

      // actualiza los contactos del usuario actual en memoria
      for (final contacto in contactosAActualizar) {
        final actualizado = contacto.copyWith(isPrimary: false);
        final idx = _contactos.indexWhere((c) => c.id == actualizado.id);
        if (idx >= 0 && idx < _contactos.length) {
          _contactos[idx] = actualizado;
        }
      }

      // actualiza en Firestore los docs de este mismo userId
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
      // En caso de error, intentamos recargar para asegurar consistencia
      await recargarContactos(userId);
    }
  }

  // Método para limpiar los contactos al cerrar sesión
  void resetContactos() {
    _contactos.clear();
    _contactosCargados = false;
    notifyListeners();
  }
}
