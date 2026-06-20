import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/app_models.dart';

/// Provides the singleton instance of the SupabaseService
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

/// Watches the Supabase Auth state changes.
/// This is the source of truth for whether a user is logged in.
final authStateProvider = StreamProvider<AuthState>((ref) {
  final service = ref.watch(supabaseServiceProvider);
  return service.authStateChanges;
});

/// Provides the current Supabase Session, derived from authStateProvider.
final sessionProvider = Provider<Session?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  return authState?.session ?? Supabase.instance.client.auth.currentSession;
});

/// Provides the current Supabase User, derived from sessionProvider.
final userProvider = Provider<User?>((ref) {
  final session = ref.watch(sessionProvider);
  return session?.user;
});

/// Provides the UserProfile for the currently authenticated user.
/// Fetches from the 'user_profiles' table whenever the user ID changes.
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return null;

  final service = ref.watch(supabaseServiceProvider);
  final profile = await service.getProfile(user.id);
  
  return profile;
});

/// A convenience provider to check if the user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(userProvider) != null;
});

/// A convenience provider to check if the user has completed onboarding.
final isOnboardingCompleteProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile?.onboardingComplete ?? false,
    orElse: () => false,
  );
});

/// Provides the AccountType (contractor, customer, or both) for the current user.
final userRoleProvider = Provider<AccountType?>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.maybeWhen(
    data: (profile) => profile?.accountType,
    orElse: () => null,
  );
});

/// AuthNotifier allows manual UI actions to interact with the Auth state via Riverpod.
class AuthNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> signOut() async {
    await ref.read(supabaseServiceProvider).signOut();
  }

  /// Updates the profile in Supabase and refreshes the userProfileProvider.
  Future<void> completeOnboarding(UserProfile updatedProfile) async {
    final service = ref.read(supabaseServiceProvider);
    await service.upsertProfile(updatedProfile);
    ref.invalidate(userProfileProvider);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, void>(() {
  return AuthNotifier();
});

/// Navigation State Logic for GoRouter redirection.
/// Used to centralize auth-gate logic (e.g. redirect to login if no session).
final authRedirectProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  final profileAsync = ref.watch(userProfileProvider);

  // Still loading auth state
  if (authState.isLoading) return null;

  final session = ref.read(sessionProvider);
  
  // No session -> must go to AuthScreen
  if (session == null) return '/auth';

  // Session exists, but profile not yet loaded or error
  if (profileAsync.isLoading) return null;
  
  final profile = profileAsync.value;
  
  // User is logged in but has no profile record yet (edge case) or not finished onboarding
  if (profile == null || !profile.onboardingComplete) {
    return '/onboarding';
  }

  // Already on onboarding but finished? Go to dashboard.
  // Logic here usually handled inside GoRouter's redirect based on current location.
  return null;
});