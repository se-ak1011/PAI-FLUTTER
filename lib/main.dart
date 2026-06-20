import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/env.dart';
import 'routes/router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with constants from server-emitted Env
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  // Lock orientation to portrait for a consistent mobile experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style to match branding
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: PAIApp(),
    ),
  );
}

/// Root Application widget for PAI (Personal Assistant for Trades).
/// Sets up the GoRouter for navigation and applies the Material 3 AppTheme.
class PAIApp extends ConsumerWidget {
  const PAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'PAI - Trade Assistant',
      debugShowCheckedModeBanner: false,
      
      // Theme Configuration using Material 3 design system
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // GoRouter Configuration for navigation and role-based redirection
      routerConfig: router,
    );
  }
}

/// Global client access point for quick access to the Supabase instance.
/// Core operations are abstracted in lib/services/supabase_service.dart,
/// but this client is occasionally used for simple on-the-fly queries or auth checks.
final supabase = Supabase.instance.client;