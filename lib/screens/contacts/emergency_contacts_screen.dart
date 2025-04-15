import 'package:flutter/material.dart';
import 'package:pruebavercel/screens/home/home_screen.dart';
import 'package:pruebavercel/theme/app_theme.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<Map<String, dynamic>> _contacts = [];

  void _addContact() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final phoneController = TextEditingController();
        final relationController = TextEditingController();
        bool isPrimary = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Agregar contacto de emergencia'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: relationController,
                      decoration: const InputDecoration(
                        labelText: 'Relación (ej: Hijo/a, Esposo/a)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: isPrimary,
                          onChanged: (value) {
                            setState(() {
                              isPrimary = value!;
                            });
                          },
                        ),
                        const Text('Contacto primario'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                      if (isPrimary) {
                        // Si el nuevo contacto es primario, quitar la marca de primario de los demás
                        for (var contact in _contacts) {
                          contact['isPrimary'] = false;
                        }
                      }
                      
                      setState(() {
                        _contacts.add({
                          'name': nameController.text,
                          'phone': phoneController.text,
                          'relation': relationController.text,
                          'isPrimary': isPrimary,
                        });
                      });
                      Navigator.pop(context);
                      
                      // Actualizar la pantalla principal
                      this.setState(() {});
                    }
                  },
                  child: const Text('Agregar'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _editContact(int index) {
    final contact = _contacts[index];
    
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController(text: contact['name']);
        final phoneController = TextEditingController(text: contact['phone']);
        final relationController = TextEditingController(text: contact['relation']);
        bool isPrimary = contact['isPrimary'];

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar contacto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: relationController,
                      decoration: const InputDecoration(
                        labelText: 'Relación (ej: Hijo/a, Esposo/a)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: isPrimary,
                          onChanged: (value) {
                            setState(() {
                              isPrimary = value!;
                            });
                          },
                        ),
                        const Text('Contacto primario'),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                      if (isPrimary) {
                        // Si este contacto es primario, quitar la marca de primario de los demás
                        for (var i = 0; i < _contacts.length; i++) {
                          if (i != index) {
                            _contacts[i]['isPrimary'] = false;
                          }
                        }
                      }
                      
                      this.setState(() {
                        _contacts[index] = {
                          'name': nameController.text,
                          'phone': phoneController.text,
                          'relation': relationController.text,
                          'isPrimary': isPrimary,
                        };
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _deleteContact(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar contacto'),
          content: const Text('¿Estás seguro de que deseas eliminar este contacto?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryRed,
              ),
              onPressed: () {
                setState(() {
                  _contacts.removeAt(index);
                });
                Navigator.pop(context);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  void _finishSetup() {
    if (_contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes agregar al menos un contacto de emergencia'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Navegar a la pantalla principal
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contactos de Emergencia'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contactos de Emergencia',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Agrega personas que serán notificadas en caso de emergencia',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _contacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.contact_phone_outlined,
                              size: 80,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay contactos de emergencia',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Agrega al menos un contacto',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _contacts.length,
                        itemBuilder: (context, index) {
                          final contact = _contacts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: contact['isPrimary']
                                    ? AppTheme.secondaryGreen
                                    : AppTheme.primaryBlue,
                                child: Icon(
                                  Icons.person,
                                  color: AppTheme.primaryWhite,
                                ),
                              ),
                              title: Text(contact['name']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(contact['phone']),
                                  Text(contact['relation']),
                                  if (contact['isPrimary'])
                                    const Text(
                                      'Contacto primario',
                                      style: TextStyle(
                                        color: AppTheme.secondaryGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _editContact(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: AppTheme.secondaryRed,
                                    ),
                                    onPressed: () => _deleteContact(index),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _addContact,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Contacto'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _finishSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryGreen,
                  ),
                  child: const Text('Finalizar Configuración'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

