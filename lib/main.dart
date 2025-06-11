import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:alzalert/providers/alert_system_provider.dart';
import 'package:alzalert/providers/contacto_emergencia_provider.dart';
import 'package:alzalert/providers/medical_info_provider.dart';
import 'package:alzalert/screens/splash_screen.dart';
import 'package:alzalert/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';
import 'providers/location_history_provider.dart';
import 'package:geocoding/geocoding.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Solicitud de permisos
  var locationStatus = await Permission.location.request();
  if (!locationStatus.isGranted) {
    debugPrint(
      "Permiso de ubicación en primer plano denegado: $locationStatus",
    );
  }

  await [
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.locationWhenInUse,
  ].request();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ContactoEmergenciaProvider()),
        ChangeNotifierProvider(
          create: (_) => AlertSystemProvider(navigatorKey),
        ),
        ChangeNotifierProvider(create: (_) => LocationHistoryProvider()),
        ChangeNotifierProvider(create: (_) => MedicalInfoProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'alzalert',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      locale: const Locale('es', 'ES'),
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
    );
  }
}
