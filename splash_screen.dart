import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkNavigation();
  }

  Future<void> _checkNavigation() async {
    // Wait for the auth state to be initialized by Riverpod/Supabase
    // We use a small delay to ensure smooth transition and allow the providers to settle
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;

    final user = ref.read(userProvider);
    
    if (user == null) {
      // User is not signed in
      context.go('/auth');
      return;
    }

    // Use ref.refresh and await to ensure we have the latest profile from the DB
    final profileAsync = await ref.read(userProfileProvider.future);

    if (!mounted) return;

    if (profileAsync == null) {
      // Something went wrong or profile doesn't exist yet; force re-auth or onboarding
      context.go('/auth');
      return;
    }

    if (!profileAsync.onboardingComplete) {
      // User is authenticated but hasn't finished the onboarding flow
      context.go('/onboarding');
    } else {
      // Fully authenticated and onboarded
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryNavy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // PAI Logo representation 
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.brandPrimary,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.construction,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'PAI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Personal Assistant for Trades',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 64),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brandPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}