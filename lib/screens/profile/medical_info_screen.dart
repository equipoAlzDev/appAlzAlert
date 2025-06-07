import 'package:alzalert/providers/user_provider.dart';
import 'package:alzalert/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:alzalert/screens/contacts/emergency_contacts_screen.dart';
import 'package:alzalert/theme/app_theme.dart';
import 'package:provider/provider.dart';

class MedicalInfoScreen extends StatefulWidget {
  const MedicalInfoScreen({super.key});

  @override
  State<MedicalInfoScreen> createState() => _MedicalInfoScreenState();
}

class _MedicalInfoScreenState extends State<MedicalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController(
    text: 'Alzheimer avanzado',
  );
  final _medicationsController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _doctorPhoneController = TextEditingController();
  bool _isLoading = false;

  List<Map<String, dynamic>> _medications = [];

  @override
  void dispose() {
    _diagnosisController.dispose();
    _medicationsController.dispose();
    _allergiesController.dispose();
    _doctorNameController.dispose();
    _doctorPhoneController.dispose();
    super.dispose();
  }

  void _addMedication() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final doseController = TextEditingController();
        final timeController = TextEditingController();

        return AlertDialog(
          title: const Text('Agregar medicamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del medicamento',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: doseController,
                decoration: const InputDecoration(labelText: 'Dosis'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Horario (ej: 8:00, 14:00, 20:00)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _medications.add({
                      'name': nameController.text,
                      'dose': doseController.text,
                      'time': timeController.text,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Aquí guardamos los datos médicos en Firebase
        // Por implementar: guardar _medications, alergias, etc.

        // Verificamos el contexto de navegación
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        if (userProvider.navigationContext == NavigationContext.registration) {
          // Durante el registro, vamos a la siguiente pantalla
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EmergencyContactsScreen(),
              ),
            );
          }
        } else {
          // Si está editando, regresamos al perfil
          if (mounted) {
            Navigator.pop(context);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información Médica'),
        backgroundColor: AppTheme.primaryBlue,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.blue.shade50],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos Médicos',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Esta información es crucial para emergencias médicas',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _diagnosisController,
                    decoration: const InputDecoration(
                      labelText: 'Diagnóstico',
                      prefixIcon: Icon(Icons.medical_information_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa el diagnóstico';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Medicamentos',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: _addMedication,
                            icon: Icon(
                              Icons.add_circle,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _medications.isEmpty
                          ? const Text(
                            'No hay medicamentos registrados',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          )
                          : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _medications.length,
                            itemBuilder: (context, index) {
                              final medication = _medications[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(medication['name']),
                                  subtitle: Text(
                                    'Dosis: ${medication['dose']}\nHorario: ${medication['time']}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: AppTheme.secondaryRed,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _medications.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _allergiesController,
                    decoration: const InputDecoration(
                      labelText: 'Alergias',
                      prefixIcon: Icon(Icons.warning_amber_outlined),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: SizedBox(
                      width: 300,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveAndContinue,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              30,
                            ), // Un valor alto para hacerlo muy redondeado como una cápsula
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 12,
                          ), // Opcional: para darle mejor aspecto
                        ),
                        child: Text(
                          Provider.of<UserProvider>(context).buttonText,
                          style: const TextStyle(fontSize: 17),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
