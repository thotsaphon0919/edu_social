import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (appState.loading) {
      return const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.school_rounded, color: Colors.white, size: 72),
              SizedBox(height: 16),
              Text('EduSocial',
                  style: TextStyle(
                      color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              SizedBox(height: 24),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      );
    }

    return appState.currentUser == null ? const LoginScreen() : const HomeScreen();
  }
}
