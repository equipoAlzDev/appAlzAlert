import 'package:flutter/material.dart';
import 'package:alzalert/screens/auth/welcome_screen.dart';
import 'package:alzalert/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToWelcome();
  }

  _navigateToWelcome() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBlue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fmd_good_outlined,
              size: 100,
              color: AppTheme.primaryWhite,
            ),
            const SizedBox(height: 24),
            Text(
              'AlzAlert',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AppTheme.primaryWhite,
                fontWeight: FontWeight.bold,
                fontSize: 30,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Cuidando a quienes más importan',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.primaryWhite,
                fontSize: 23,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
