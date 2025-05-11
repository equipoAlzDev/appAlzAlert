import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:alzalert/screens/home/home_screen.dart';
import 'package:alzalert/theme/app_theme.dart';

import '../../providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _emailErrorMessage;
  String? _passwordErrorMessage;

  final _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
              _emailErrorMessage = 'No existe una cuenta con este correo electrónico.';
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
              _passwordErrorMessage = 'Demasiados intentos fallidos. Intenta más tarde.';
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
          const SnackBar(content: Text('Se ha enviado un correo para restablecer tu contraseña')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Bienvenido de nuevo',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresa tus datos para continuar',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                
                // Campo de correo electrónico
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu correo electrónico';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Ingresa un correo electrónico válido';
                    }
                    return null;
                  },
                ),
                
                // Mensaje de error para el email
                if (_emailErrorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _emailErrorMessage!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Campo de contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu contraseña';
                    }
                    return null;
                  },
                ),
                
                // Mensaje de error para la contraseña
                if (_passwordErrorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _passwordErrorMessage!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading 
                      ? const CircularProgressIndicator()
                      : const Text('Iniciar Sesión'),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}