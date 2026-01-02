import 'package:flutter/material.dart';
import 'package:belanja_praktis/data/repositories/auth_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Add a small delay to ensure the splash screen is visible/rendered
    // and to allow other initializations to settle.
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final auth = GetIt.I<AuthRepository>();
    try {
      final isLoggedIn = await auth.isLoggedIn();
      
      if (!mounted) return;

      if (isLoggedIn) {
        context.go('/');
      } else {
        context.go('/login');
      }
    } catch (e) {
      // Fallback to login on error
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
