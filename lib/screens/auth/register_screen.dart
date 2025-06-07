import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:alzalert/screens/profile/profile_setup_screen.dart';

import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  String? _emailErrorMessage;
  String? _passwordErrorMessage;
  String? _confirmPasswordErrorMessage;

  // Controlador de animación
  late AnimationController _animationController;
  Animation<double> _scaleAnimation = const AlwaysStoppedAnimation(1.0);

  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  bool _isPasswordStrong(String password) {
    bool hasMinLength = password.length >= 8;
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return hasMinLength && hasUppercase && hasNumber && hasSpecialChar;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa una contraseña';
    }

    if (!_isPasswordStrong(value)) {
      return 'La contraseña debe cumplir con los requisitos mencionados';
    }

    return null;
  }

  Future<void> _register() async {
    setState(() {
      _emailErrorMessage = null;
      _passwordErrorMessage = null;
      _confirmPasswordErrorMessage = null;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUserData();

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Verificar si el email ya está registrado
        final methods = await _auth.fetchSignInMethodsForEmail(
          _emailController.text.trim(),
        );
        if (methods.isNotEmpty) {
          setState(() {
            _emailErrorMessage = 'Este correo electrónico ya está registrado';
            _isLoading = false;
          });
          return;
        }

        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        // Establecer el contexto de navegación para registro
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setNavigationContext(NavigationContext.registration);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        _handleFirebaseError(e);
      } catch (e) {
        setState(() {
          _emailErrorMessage = 'Error al registrar usuario: $e';
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _handleFirebaseError(FirebaseAuthException e) {
    setState(() {
      switch (e.code) {
        case 'email-already-in-use':
          _emailErrorMessage = 'Este correo electrónico ya está registrado';
          break;
        case 'invalid-email':
          _emailErrorMessage = 'Formato de correo electrónico inválido';
          break;
        case 'weak-password':
          _passwordErrorMessage = 'La contraseña es demasiado débil';
          break;
        case 'operation-not-allowed':
          _emailErrorMessage =
              'El registro con email y contraseña no está habilitado';
          break;
        default:
          _emailErrorMessage = 'Error: ${e.message}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos las dimensiones de la pantalla
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      // Quitamos cualquier color de fondo predeterminado para usar nuestro fondo personalizado
      backgroundColor: Colors.transparent,
      body: Container(
        // Aseguramos que este contenedor ocupe toda la pantalla
        width: screenSize.width,
        height: screenSize.height,
        decoration: BoxDecoration(
          // Agregamos un color de fondo base
          color: AppTheme.background,
        ),
        child: Stack(
          // Hacemos que el stack ocupe todo el espacio disponible
          fit: StackFit.expand,
          children: [
            // Formas decorativas en el fondo - Ahora con posiciones relativas al tamaño de la pantalla
            Positioned(
              top: -screenSize.height * 0.12,
              left: -screenSize.width * 0.15,
              child: Transform.rotate(
                angle: -0.2,
                child: Container(
                  width: screenSize.width * 0.6,
                  height: screenSize.width * 0.6,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(
                      screenSize.width * 0.12,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenSize.height * 0.1,
              right: -screenSize.width * 0.25,
              child: Transform.rotate(
                angle: 0.3,
                child: Container(
                  width: screenSize.width * 0.55,
                  height: screenSize.width * 0.55,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(screenSize.width * 0.1),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -screenSize.height * 0.05,
              right: -screenSize.width * 0.07,
              child: Container(
                width: screenSize.width * 0.45,
                height: screenSize.width * 0.45,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(screenSize.width * 0.225),
                ),
              ),
            ),
            // Fondo adicional para asegurar cobertura completa
            Positioned(
              bottom: screenSize.height * 0.3,
              left: -screenSize.width * 0.1,
              child: Container(
                width: screenSize.width * 0.3,
                height: screenSize.width * 0.3,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(screenSize.width * 0.15),
                ),
              ),
            ),
            // Contenido principal - Envuelto en un contenedor que ocupa toda la pantalla
            SizedBox.expand(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Botón de retroceso personalizado
                        Container(
                          margin: const EdgeInsets.only(top: 10, bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),

                        Text(
                          'Crear una cuenta',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Completa tus datos para registrarte',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 30),

                        // Campo de correo electrónico con estilo moderno
                        Container(
                          margin: const EdgeInsets.only(bottom: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Correo electrónico',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.white,
                              filled: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu correo electrónico';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return 'Ingresa un correo electrónico válido';
                              }
                              return null;
                            },
                          ),
                        ),

                        if (_emailErrorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 5.0,
                              left: 12.0,
                            ),
                            child: Text(
                              _emailErrorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Campo de contraseña con estilo moderno
                        Container(
                          margin: const EdgeInsets.only(bottom: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.white,
                              filled: true,
                            ),
                            validator: _validatePassword,
                          ),
                        ),

                        // Mensaje de error para la contraseña
                        if (_passwordErrorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 5.0,
                              left: 12.0,
                            ),
                            child: Text(
                              _passwordErrorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),

                        // Información sobre requisitos de contraseña con estilo mejorado
                        Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 5,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'La contraseña debe tener al menos 8 caracteres, una letra mayúscula, un número y un símbolo',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Campo de confirmar contraseña con estilo moderno
                        Container(
                          margin: const EdgeInsets.only(bottom: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirmar contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.white,
                              filled: true,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor confirma tu contraseña';
                              }
                              if (value != _passwordController.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                          ),
                        ),

                        // Mensaje de error para confirmar contraseña
                        if (_confirmPasswordErrorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 5.0,
                              left: 12.0,
                            ),
                            child: Text(
                              _confirmPasswordErrorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),

                        const SizedBox(height: 30),

                        // Botón de registro con efectos
                        Center(
                          child: GestureDetector(
                            onTapDown: (_) => _animationController.forward(),
                            onTapUp: (_) => _animationController.reverse(),
                            onTapCancel: () => _animationController.reverse(),
                            child: AnimatedBuilder(
                              animation: _scaleAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _scaleAnimation.value,
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.7,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.primaryBlue,
                                          AppTheme.secondaryGreen,
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryBlue
                                              .withOpacity(0.3),
                                          spreadRadius: 1,
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _register,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                      ),
                                      child:
                                          _isLoading
                                              ? const CircularProgressIndicator(
                                                color: Colors.white,
                                              )
                                              : const Text(
                                                'Registrarse',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
