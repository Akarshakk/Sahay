import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/ashoka_chakra.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  Future<void> _navigateToLogin() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryRed,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Indian Flag Colors Logo with Ashoka Chakra
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF9933), // Saffron
                    Color(0xFFFFFFFF), // White
                    Color(0xFF138808), // Green
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: AshokaChakra(
                  size: 70,
                  color: Color(0xFF000080), // Navy Blue
                ),
              ),
            ).animate()
              .fadeIn(duration: 800.ms)
              .scale(delay: 200.ms)
              .then()
              .shimmer(duration: 1500.ms),
            
            const SizedBox(height: 40),
            
            const Text(
              'Sahay',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ).animate()
              .fadeIn(delay: 400.ms, duration: 800.ms)
              .slideY(begin: 0.3, end: 0),
            
            const SizedBox(height: 12),
            
            Text(
              'Your Lifeline in Emergencies',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                letterSpacing: 1,
              ),
            ).animate()
              .fadeIn(delay: 600.ms, duration: 800.ms),
            
            const SizedBox(height: 60),
            
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ).animate()
              .fadeIn(delay: 1000.ms),
          ],
        ),
      ),
    );
  }
}
