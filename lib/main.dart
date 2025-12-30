import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/api_config.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ .env file loaded successfully');
  } catch (e) {
    debugPrint('⚠️ Could not load .env file: $e');
    // Continue anyway - keys might be set via --dart-define
  }
  
  // Initialize API keys from dotenv
  ApiConfig.setApiKeys(
    gemini: dotenv.env['GEMINI_API_KEY'],
    groq: dotenv.env['GROQ_API_KEY'],
    openai: dotenv.env['OPENAI_API_KEY'],
  );
  
  // Debug: Print if keys are loaded
  debugPrint('🔑 GROQ_API_KEY: ${ApiConfig.groqApiKey.isNotEmpty ? "SET (${ApiConfig.groqApiKey.substring(0, 10)}...)" : "NOT SET"}');
  debugPrint('🔑 GEMINI_API_KEY: ${ApiConfig.geminiApiKey.isNotEmpty ? "SET" : "NOT SET"}');
  debugPrint('🔑 OPENAI_API_KEY: ${ApiConfig.openaiApiKey.isNotEmpty ? "SET" : "NOT SET"}');

  // Initialize Supabase
  await Supabase.initialize(
    url: ApiConfig.supabaseUrl,
    anonKey: ApiConfig.supabaseAnonKey,
  );

  // Initialize Notifications
  await NotificationService().initialize();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MeekApp());
}

/// Get the Supabase client instance
final supabase = Supabase.instance.client;

class MeekApp extends StatelessWidget {
  const MeekApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'MEEK - Quran Learning',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme.copyWith(
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                },
              ),
            ),
            darkTheme: AppTheme.darkTheme.copyWith(
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                },
              ),
            ),
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

/// Wrapper to handle authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Check if we have a valid session
        final session = supabase.auth.currentSession;
        
        if (session != null) {
          // User is logged in
          return const DashboardScreen();
        } else {
          // User is not logged in
          return const SignInScreen();
        }
      },
    );
  }
}
