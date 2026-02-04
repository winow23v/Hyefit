import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// 게스트 모드 상태
final isGuestModeProvider = StateProvider<bool>((ref) => false);

final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (state) => state.session?.user);
});

/// 로그인 여부 (게스트 모드 포함)
final isLoggedInProvider = Provider<bool>((ref) {
  final isGuest = ref.watch(isGuestModeProvider);
  if (isGuest) return true;
  return ref.watch(currentUserProvider) != null;
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authService.signIn(email: email, password: password),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authService.signUp(email: email, password: password),
    );
  }

  void enterGuestMode() {
    _ref.read(isGuestModeProvider.notifier).state = true;
    state = const AsyncValue.data(null);
  }

  Future<void> signOut() async {
    // 게스트 모드 해제
    _ref.read(isGuestModeProvider.notifier).state = false;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _authService.signOut());
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider), ref);
});
