import 'package:alzalert/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:alzalert/screens/profile/medical_info_screen.dart';
import 'package:alzalert/theme/app_theme.dart';
import 'package:alzalert/providers/user_provider.dart'; // Importamos el provider

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Cargamos los datos del usuario si existen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.loadUserData().then((_) {
        // Si ya hay datos, los cargamos en los controladores
        final user = userProvider.user;
        _nameController.text = user.name;
        if (user.birthDate != null) {
          _selectedDate = user.birthDate;
          _birthDateController.text = DateFormat(
            'dd/MM/yyyy',
          ).format(user.birthDate!);
        }
        _addressController.text = user.address;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Mostramos un indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Guardamos los datos usando el provider
        await userProvider.updatePersonalInfo(
          name: _nameController.text.trim(),
          birthDate: _selectedDate,
          address: _addressController.text.trim(),
          profileImageUrl: userProvider.user.profileImageUrl,
        );

        // Cerramos el diálogo de carga
        if (mounted) Navigator.of(context).pop();

        // Navegamos según el contexto
        if (mounted) {
          if (userProvider.navigationContext ==
              NavigationContext.registration) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MedicalInfoScreen(),
              ),
            );
          } else {
            // Si estamos editando, regresamos al perfil
            if (mounted) {
              Navigator.pop(context);
            }
          }
        }
      } catch (e) {
        // Cerramos el diálogo de carga
        if (mounted) Navigator.of(context).pop();

        // Mostramos un mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar los datos: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: AppTheme.primaryWhite,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos Consumer para acceder al estado del usuario
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Datos Personales'),
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
            child:
                userProvider.isLoading && _nameController.text.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información Personal',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Esta información es importante para identificarte en caso de emergencia',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre completo',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu nombre';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _birthDateController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Fecha de nacimiento',
                                prefixIcon: Icon(Icons.calendar_today),
                                hintText: 'DD/MM/AAAA',
                              ),
                              onTap: () => _selectDate(context),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor selecciona tu fecha de nacimiento';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Dirección',
                                prefixIcon: Icon(Icons.home_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa tu dirección';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 40),
                            Center(
                              child: SizedBox(
                                width: 300,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed:
                                      userProvider.isLoading
                                          ? null
                                          : _saveAndContinue,
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
                                  child:
                                      userProvider.isLoading
                                          ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppTheme.primaryWhite,
                                            ),
                                          )
                                          : Text(
                                            userProvider.buttonText,
                                            style: const TextStyle(
                                              fontSize: 17,
                                            ),
                                          ),
                                ),
                              ),
                            ),
                            if (userProvider.error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Text(
                                  userProvider.error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
          ),
        );
      },
    );
  }
}
