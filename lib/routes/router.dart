import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_providers.dart';
import '../screens/auth_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/jobs_screen.dart';
import '../screens/marketplace_screen.dart';
import '../screens/tax_pot_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/marketplace_job_screen.dart';
import '../screens/job_detail_screen.dart';
import '../screens/invoice_screen.dart';
import '../screens/contractor_profile_screen.dart';
import '../screens/admin_disputes_screen.dart';
import '../screens/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profileState = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthRefreshNotifier(ref),
    redirect: (context, state) {
      final session = authState.value;
      final profile = profileState.value;
      final isLoggingIn = state.matchedLocation == '/auth';

      // 1. Session check
      if (session == null) {
        return isLoggingIn ? null : '/auth';
      }

      // 2. Profile loading check
      if (profileState.isLoading) return null;

      // 3. Onboarding check
      if (profile != null && !profile.onboardingComplete) {
        if (state.matchedLocation == '/onboarding') return null;
        return '/onboarding';
      }

      // 4. Authenticated & Onboarded - prevent going back to login
      if (isLoggingIn || state.matchedLocation == '/') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/jobs',
        builder: (context, state) => const JobsScreen(),
        routes: [
          GoRoute(
            path: ':jobId',
            builder: (context, state) {
              final jobId = state.pathParameters['jobId']!;
              return JobDetailScreen(jobId: jobId);
            },
            routes: [
              GoRoute(
                path: 'invoice',
                builder: (context, state) {
                  final jobId = state.pathParameters['jobId']!;
                  return InvoiceScreen(jobId: jobId);
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/marketplace',
        builder: (context, state) => const MarketplaceScreen(),
        routes: [
          GoRoute(
            path: 'job/:jobId',
            builder: (context, state) {
              final jobId = state.pathParameters['jobId']!;
              return MarketplaceJobScreen(jobId: jobId);
            },
          ),
          GoRoute(
            path: 'contractor/:contractorId',
            builder: (context, state) {
              final contractorId = state.pathParameters['contractorId']!;
              return ContractorProfileScreen(contractorId: contractorId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/tax-pot',
        builder: (context, state) => const TaxPotScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/admin/disputes',
        builder: (context, state) => const AdminDisputesScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});

/// Notifier that triggers GoRouter refresh on auth or profile state changes.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(userProfileProvider, (_, __) => notifyListeners());
  }
}