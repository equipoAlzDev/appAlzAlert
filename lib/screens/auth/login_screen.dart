import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:alzalert/screens/home/home_screen.dart';

import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _emailErrorMessage;
  String? _passwordErrorMessage;

  // Controlador de animación
  late AnimationController _animationController;
  // Inicializamos con un valor predeterminado para evitar el error LateInitializationError
  Animation<double> _scaleAnimation = const AlwaysStoppedAnimation(1.0);

  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    // Aquí asignamos el valor real a _scaleAnimation después de que _animationController esté listo
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // Limpiar mensajes de error previos
    setState(() {
      _emailErrorMessage = null;
      _passwordErrorMessage = null;
    });

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Intentar iniciar sesión con Firebase Auth
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loadUserData();

        if (mounted) {
          // Si el inicio de sesión es exitoso, navegar a la pantalla principal
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        // Manejar errores específicos de Firebase Auth
        setState(() {
          switch (e.code) {
            case 'user-not-found':
              _emailErrorMessage =
                  'No existe una cuenta con este correo electrónico.';
              break;
            case 'wrong-password':
              _passwordErrorMessage = 'Contraseña incorrecta.';
              break;
            case 'invalid-email':
              _emailErrorMessage = 'Formato de correo electrónico inválido.';
              break;
            case 'invalid-credential':
              _passwordErrorMessage = 'Credenciales inválidas.';
              break;
            case 'user-disabled':
              _emailErrorMessage = 'Esta cuenta ha sido deshabilitada.';
              break;
            case 'too-many-requests':
              _passwordErrorMessage =
                  'Demasiados intentos fallidos. Intenta más tarde.';
              break;
            default:
              // Para otros errores, mostrar en el campo de correo como ubicación predeterminada
              _emailErrorMessage = 'Error: ${e.message}';
          }
        });
      } catch (e) {
        // Manejar otros errores no específicos de Firebase
        setState(() {
          _emailErrorMessage = 'Error al iniciar sesión: $e';
        });
      } finally {
        // Finalizar el estado de carga
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _emailErrorMessage = 'Por favor ingresa tu correo electrónico';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _emailErrorMessage = null;
    });

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Se ha enviado un correo para restablecer tu contraseña',
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _emailErrorMessage = 'Error: ${e.message}';
        });
      }
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
            // Fondo con formas decorativas - Ahora con posiciones relativas al tamaño de la pantalla
            Positioned(
              top: -screenSize.height * 0.1,
              right: -screenSize.width * 0.1,
              child: Transform.rotate(
                angle: 0.3,
                child: Container(
                  width: screenSize.width * 0.5,
                  height: screenSize.width * 0.5,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(screenSize.width * 0.1),
                  ),
                ),
              ),
            ),
            Positioned(
              top: screenSize.height * 0.08,
              left: -screenSize.width * 0.15,
              child: Transform.rotate(
                angle: -0.5,
                child: Container(
                  width: screenSize.width * 0.45,
                  height: screenSize.width * 0.45,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(screenSize.width * 0.1),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -screenSize.height * 0.05,
              left: -screenSize.width * 0.05,
              child: Container(
                width: screenSize.width * 0.4,
                height: screenSize.width * 0.4,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(screenSize.width * 0.2),
                ),
              ),
            ),
            // Fondo adicional para asegurar cobertura completa
            Positioned(
              bottom: -screenSize.height * 0.05,
              right: -screenSize.width * 0.05,
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Botón de retroceso personalizado
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(top: 20),
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
                        ),
                        const SizedBox(height: 60),
                        // Logo o icono animado
                        AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryBlue.withOpacity(
                                        0.3,
                                      ),
                                      spreadRadius: 2,
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'Bienvenido de nuevo',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Ingresa tus datos para continuar',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 40),

                        // Campo de correo electrónico con estilo moderno
                        Container(
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

                        // Mensaje de error para el email
                        if (_emailErrorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu contraseña';
                              }
                              return null;
                            },
                          ),
                        ),

                        // Mensaje de error para la contraseña
                        if (_passwordErrorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8.0,
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

                        const SizedBox(height: 30),

                        // Botón de inicio de sesión con efectos
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
                                          Color.fromARGB(255, 0, 150, 150),
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
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _login,
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
                                                'Iniciar Sesión',
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

                        const SizedBox(height: 20),

                        // Enlace para recuperar contraseña con estilo mejorado
                        TextButton(
                          onPressed: _isLoading ? null : _resetPassword,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 20,
                            ),
                          ),
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationThickness: 1.5,
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
