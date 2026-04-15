import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  try {
    await Firebase.initializeApp();
    // Initialiser les notifications
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Erreur d\'initialisation Firebase: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salles - Groupe Al Omrane',
      debugShowCheckedModeBanner: false,
      theme: AlOmraneTheme.lightTheme,
      home: SplashScreen(
        nextScreen: FutureBuilder<bool>(
          future: AuthService().isLoggedIn(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return snapshot.data! ? const HomeScreen() : const LoginScreen();
            }
            return const Scaffold();
          },
        ),
      ),
    );
  }
}
