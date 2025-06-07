import 'package:flutter/material.dart';
import 'package:alzalert/screens/auth/login_screen.dart';
import 'package:alzalert/screens/auth/register_screen.dart';
import 'package:alzalert/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: screenSize.width,
        height: screenSize.height,
        decoration: BoxDecoration(color: AppTheme.background),
        child: Stack(
          fit: StackFit.expand,
          children: [
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
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 120,
                      height: 100,
                      fit: BoxFit.fill,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Bienvenido a AlzAlert',
                      style: Theme.of(context).textTheme.displayMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Una aplicación para el seguimiento y cuidado de personas con Alzheimer avanzado',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    Center(
                      child: Container(
                        width: screenSize.width * 0.7,
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
                              color: AppTheme.primaryBlue.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        width: screenSize.width * 0.7,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppTheme.primaryBlue,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Registrarse',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
