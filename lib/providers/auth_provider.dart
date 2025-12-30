import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Authentication Provider - Manages user auth state
class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _onboardingCompleted = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;
  bool get onboardingCompleted => _onboardingCompleted;

  AuthProvider() {
    _initialize();
  }

  void _initialize() {
    _user = _supabase.auth.currentUser;
    
    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
      
      if (_user != null) {
        _checkOnboardingStatus();
      }
    });
  }

  Future<void> _checkOnboardingStatus() async {
    if (_user == null) return;
    
    try {
      final response = await _supabase
          .from('profiles')
          .select('onboarding_completed')
          .eq('id', _user!.id)
          .single();
      
      _onboardingCompleted = response['onboarding_completed'] ?? false;
      notifyListeners();
    } catch (e) {
      // Profile might not exist yet
      _onboardingCompleted = false;
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Sign in failed');
      }
    } on AuthException catch (e) {
      _setError(e.message);
      rethrow;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Sign up failed');
      }
    } on AuthException catch (e) {
      _setError(e.message);
      rethrow;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      const webClientId = 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
      const iosClientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Missing Google auth tokens');
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      await _supabase.auth.signOut();
      _user = null;
      _onboardingCompleted = false;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Complete onboarding
  Future<void> completeOnboarding({
    required String name,
    String? madhab,
    bool? notificationsEnabled,
  }) async {
    if (_user == null) return;
    
    _setLoading(true);
    
    try {
      await _supabase.from('profiles').upsert({
        'id': _user!.id,
        'name': name,
        'madhab': madhab ?? 'hanafi',
        'notifications_enabled': notificationsEnabled ?? true,
        'onboarding_completed': true,
      });
      
      _onboardingCompleted = true;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? name,
    String? madhab,
    bool? notificationsEnabled,
  }) async {
    if (_user == null) return;

    _setLoading(true);

    try {
      final updates = <String, dynamic>{
        'id': _user!.id,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (madhab != null) updates['madhab'] = madhab;
      if (notificationsEnabled != null) {
        updates['notifications_enabled'] = notificationsEnabled;
      }

      await _supabase.from('profiles').upsert(updates);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
