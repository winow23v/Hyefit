import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// 게스트 모드 상태
final isGuestModeProvider = StateProvider<bool>((ref) => false);
final rememberLoginProvider = StateProvider<bool>((ref) => false);

final authBootstrapProvider = FutureProvider<void>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final rememberLogin = await authService.getRememberLogin();
  ref.read(rememberLoginProvider.notifier).state = rememberLogin;
  await authService.applyAutoLoginPreference(rememberLogin: rememberLogin);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  // auth stream을 구독해 변경 시 갱신되도록 유지
  ref.watch(authStateProvider);
  // 앱 시작 시 저장된 세션 사용자도 즉시 반영 (자동 로그인)
  return authService.currentUser;
});

/// 로그인 여부 (게스트 모드 포함)
final isLoggedInProvider = Provider<bool>((ref) {
  final isGuest = ref.watch(isGuestModeProvider);
  if (isGuest) return true;
  return ref.watch(currentUserProvider) != null;
});

/// 관리자 여부 (MVP: 이메일 기반)
const _adminEmails = ['winow23v@naver.com'];

final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  final isAdminByEmail = _adminEmails.contains(user.email);
  final metadata = user.appMetadata;
  final role = metadata['role']?.toString().toLowerCase();
  final isAdminByRole = role == 'admin';
  return isAdminByEmail || isAdminByRole;
});

final userNicknameProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final raw = user.userMetadata?['nickname'];
  if (raw is! String) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  return trimmed;
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;
  final Ref _ref;

  AuthNotifier(this._authService, this._ref)
    : super(const AsyncValue.data(null));

  Future<void> signIn({
    required String email,
    required String password,
    required bool rememberLogin,
  }) async {
    _ref.read(isGuestModeProvider.notifier).state = false;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authService.signIn(
        email: email,
        password: password,
        rememberLogin: rememberLogin,
      ),
    );
  }

  Future<void> signUp({
    required String nickname,
    required String email,
    required String password,
  }) async {
    _ref.read(isGuestModeProvider.notifier).state = false;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _authService.signUp(
        email: email,
        password: password,
        nickname: nickname,
      ),
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
