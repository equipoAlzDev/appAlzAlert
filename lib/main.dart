import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:alzalert/providers/alert_system_provider.dart';
import 'package:alzalert/providers/contacto_emergencia_provider.dart';
import 'package:alzalert/screens/splash_screen.dart';
import 'package:alzalert/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Solicitar permiso de ubicación en primer plano
  var locationStatus = await Permission.location.request();
  if (locationStatus.isGranted) {
  debugPrint("Permiso de ubicación en primer plano concedido.");
  } else {
    debugPrint("Permiso de ubicación en primer plano denegado: $locationStatus");
    // Considerar informar al usuario que la funcionalidad de ubicación no funcionará
  }

  // Solicitar permiso de ubicación en segundo plano (opcional, pero necesario para alertas en background)
  // Es mejor solicitarlo cuando la funcionalidad de fondo es explícitamente necesaria.
  // Aquí lo añadimos según la declaración en AndroidManifest.xml
  /* var backgroundLocationStatus = await Permission.locationBackground.request();
  if (backgroundLocationStatus.isGranted) {
   debugPrint("Permiso de ubicación en segundo plano concedido.");
  } else {
   debugPrint("Permiso de ubicación en segundo plano denegado: $backgroundLocationStatus");
   // Considerar informar al usuario. La alerta en segundo plano podría no funcionar.
  } */
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ContactoEmergenciaProvider()),
        ChangeNotifierProvider(create: (_) => AlertSystemProvider(navigatorKey)),
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
      supportedLocales: const [
        Locale('es', 'ES'), // Español
        Locale('en', 'US'), // Inglés (opcional)
      ],
      locale: const Locale('es', 'ES'),
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
    );
  }
}

