import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/supabase/supabase_client.dart';

class AuthService {
  final GoTrueClient _auth = SupabaseConfig.auth;
  static const _rememberLoginKey = 'remember_login';

  User? get currentUser => _auth.currentUser;
  String? get userId => currentUser?.id;
  bool get isLoggedIn => currentUser != null;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    return await _auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: SupabaseConfig.emailRedirectUrl,
      data: {
        'nickname': nickname,
      },
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
    required bool rememberLogin,
  }) async {
    final response = await _auth.signInWithPassword(
      email: email,
      password: password,
    );
    await setRememberLogin(rememberLogin);
    return response;
  }

  Future<void> signOut() async {
    await setRememberLogin(false);
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  Future<void> setRememberLogin(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberLoginKey, value);
  }

  Future<bool> getRememberLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberLoginKey) ?? false;
  }

  Future<void> applyAutoLoginPreference({required bool rememberLogin}) async {
    if (rememberLogin) return;
    if (currentUser == null) return;
    try {
      await _auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      await _auth.signOut();
    }
  }
}
