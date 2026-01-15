import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'email': email,
      },
    );
    
    // Check if there's an error in the response
    if (response.user == null) {
      final errorMsg = response.session == null 
          ? 'Failed to create account. Please check your email and try again.'
          : 'Account created but email confirmation may be required.';
      throw Exception(errorMsg);
    }
    
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    if (response.user == null) {
      throw Exception('Invalid email or password');
    }
    
    return response;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  bool get isAuthenticated => currentUser != null;
}

