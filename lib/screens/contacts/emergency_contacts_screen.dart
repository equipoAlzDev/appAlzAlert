import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pruebavercel/models/contacto_emergencia_model.dart';
import 'package:pruebavercel/providers/contacto_emergencia_provider.dart';
import 'package:pruebavercel/providers/user_provider.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarContactosIniciales();
  }

  Future<void> _cargarContactosIniciales() async {
    final userId = context.read<UserProvider>().user?.id ?? '';
    if (userId.isNotEmpty) {
      await context.read<ContactoEmergenciaProvider>().cargarContactos(userId);
    }
    setState(() => _cargando = false);
  }

  void _mostrarFormulario(
    BuildContext context, {
    ContactoEmergenciaModel? contacto,
    required String userId,
  }) {
    final provider = context.read<ContactoEmergenciaProvider>();
    final nameController = TextEditingController(text: contacto?.name ?? '');
    final phoneController = TextEditingController(text: contacto?.phone ?? '');
    String relation = contacto?.relation ?? 'Familiar';
    bool isPrimary = contacto?.isPrimary ?? false;

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(
                    contacto == null ? 'Nuevo contacto' : 'Editar contacto',
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 10),
                      Row(children: const [Text('Parentesco:')]),
                      DropdownButton<String>(
                        value: relation,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'Familiar',
                            child: Text('Familiar'),
                          ),
                          DropdownMenuItem(
                            value: 'Cuidador',
                            child: Text('Cuidador'),
                          ),
                          DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => relation = value);
                          }
                        },
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: isPrimary,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => isPrimary = value);
                              }
                            },
                          ),
                          const Text('Contacto principal'),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final nuevoContacto = ContactoEmergenciaModel(
                          id: contacto?.id ?? '',
                          name: nameController.text.trim(),
                          phone: phoneController.text.trim(),
                          relation: relation,
                          isPrimary: isPrimary,
                          userId: userId,
                        );

                        if (isPrimary) {
                          await provider.eliminarContactosPrimariosExcepto(
                            nuevoContacto.id,
                            userId,
                          );
                        }

                        if (contacto == null) {
                          await provider.agregarContacto(nuevoContacto, userId);
                        } else {
                          await provider.editarContacto(nuevoContacto);
                        }

                        if (mounted) {
                          setState(() {}); 
                        }
                        Navigator.pop(context);
                      },

                      child: const Text('Guardar'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _confirmarEliminacion(
    BuildContext context,
    ContactoEmergenciaModel contacto,
    String userId,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Eliminar contacto'),
            content: Text(
              '¿Estás seguro de que deseas eliminar a "${contacto.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // Cancelar
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final provider = context.read<ContactoEmergenciaProvider>();
                  await provider.eliminarContacto(contacto.id, userId);
                  Navigator.pop(context); // Cerrar el diálogo
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<UserProvider>().user?.id ?? '';
    final provider = context.watch<ContactoEmergenciaProvider>();
    final contactos =
        provider.contactos.where((c) => c.userId == userId).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Contactos de Emergencia')),
      body:
          _cargando
              ? const Center(child: CircularProgressIndicator())
              : contactos.isEmpty
              ? const Center(child: Text('No hay contactos guardados'))
              : ListView.builder(
                itemCount: contactos.length,
                itemBuilder: (context, index) {
                  final contacto = contactos[index];
                  return ListTile(
                    leading: Icon(
                      contacto.isPrimary ? Icons.star : Icons.person,
                      color: contacto.isPrimary ? Colors.orange : null,
                    ),
                    title: Text(contacto.name),
                    subtitle: Text('${contacto.phone} • ${contacto.relation}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed:
                              () => _mostrarFormulario(
                                context,
                                contacto: contacto,
                                userId: userId,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed:
                              () => _confirmarEliminacion(context, contacto, userId),
                        ),
                      ],
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(context, userId: userId),
        child: const Icon(Icons.add),
      ),
    );
  }
}
