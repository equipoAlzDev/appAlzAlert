import 'package:alzalert/screens/auth/login_screen.dart';
import 'package:alzalert/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alzalert/models/contacto_emergencia_model.dart';
import 'package:alzalert/providers/contacto_emergencia_provider.dart';
import 'package:alzalert/providers/user_provider.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  bool _cargando = true;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

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

    final Size screenSize = MediaQuery.of(context).size;
    final double dialogWidth = screenSize.width * 0.75;

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Container(
                    width: dialogWidth,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contacto == null
                              ? 'Nuevo contacto'
                              : 'Editar contacto',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
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
                            DropdownMenuItem(
                              value: 'Otro',
                              child: Text('Otro'),
                            ),
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
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 8),
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
                                  await provider
                                      .eliminarContactosPrimariosExcepto(
                                        nuevoContacto.id,
                                        userId,
                                      );
                                }

                                if (contacto == null) {
                                  await provider.agregarContacto(
                                    nuevoContacto,
                                    userId,
                                  );
                                } else {
                                  await provider.editarContacto(nuevoContacto);
                                }

                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text('Guardar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final provider = context.read<ContactoEmergenciaProvider>();
                  await provider.eliminarContacto(contacto.id, userId);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );
  }

  void _saveAndContinue() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final contactProvider = Provider.of<ContactoEmergenciaProvider>(context, listen: false);
    final userId = userProvider.user.id;
    final contactos = contactProvider.contactos.where((c) => c.userId == userId).toList();
    
    // Verificar si hay al menos un contacto
    if (contactos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe agregar al menos un contacto de emergencia'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Aquí puedes guardar la información adicional si es necesario
      
      // Verificamos el contexto de navegación para determinar a dónde ir
      if (userProvider.navigationContext == NavigationContext.registration) {
        // Si estamos en registro, vamos al login
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } else {
        // Si estamos editando, regresamos al perfil
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar los datos: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<UserProvider>().user?.id ?? '';
    final provider = context.watch<ContactoEmergenciaProvider>();
    final contactos = provider.contactos.where((c) => c.userId == userId).toList();

    // Obtenemos el contexto de navegación para ajustar el texto del botón
    final userProvider = Provider.of<UserProvider>(context);
    final String buttonText = userProvider.buttonText;

    return Scaffold(
      appBar: AppBar(title: const Text('Contactos de Emergencia')),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child:
                      _cargando
                          ? const Center(child: CircularProgressIndicator())
                          : contactos.isEmpty
                          ? const Center(
                            child: Text('No hay contactos guardados'),
                          )
                          : ListView.builder(
                            itemCount: contactos.length,
                            itemBuilder: (context, index) {
                              final contacto = contactos[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 1.0,
                                ),
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(10),
                                    leading: Icon(
                                      contacto.isPrimary
                                          ? Icons.star
                                          : Icons.person,
                                      color:
                                          contacto.isPrimary
                                              ? Colors.orange
                                              : null,
                                      size: 50,
                                    ),
                                    title: Text(
                                      contacto.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(contacto.phone),
                                        Text(contacto.relation),
                                      ],
                                    ),
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
                                              () => _confirmarEliminacion(
                                                context,
                                                contacto,
                                                userId,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                ),
                SizedBox(height: 80),
              ],
            ),
          ),

          Positioned(
            right: 24,
            bottom: 150,
            child: SizedBox(
              width: 50,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _mostrarFormulario(context, userId: userId),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(90),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                ),
                child: const Icon(Icons.group_add_rounded, size: 30),
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 70,
            child: Center(
              child: SizedBox(
                width: 300,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(fontSize: 17),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
