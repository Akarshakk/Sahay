import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAPcssmJOlJfdxF2pu70rsPt60ntyiZkP8",
        authDomain: "sahay-ai-project.firebaseapp.com",
        projectId: "sahay-ai-project",
        storageBucket: "sahay-ai-project.firebasestorage.app",
        messagingSenderId: "604284185347",
        appId: "1:604284185347:web:0b8449f458bc19b6eb1736",
        measurementId: "G-3WS49GSX5S",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(
    const ProviderScope(
      child: SahayApp(),
    ),
  );
}

class SahayApp extends StatelessWidget {
  const SahayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sahay - Crisis Response',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
