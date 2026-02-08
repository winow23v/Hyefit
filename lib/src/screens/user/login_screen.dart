import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final rememberLogin = ref.read(rememberLoginProvider);

    await ref.read(authNotifierProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          rememberLogin: rememberLogin,
        );

    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) {
      final msg = _mapLoginError(authState.error.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _mapLoginError(String rawError) {
    final lower = rawError.toLowerCase();
    debugPrint('Login error raw: $rawError');
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials') ||
        lower.contains('email not found') ||
        lower.contains('wrong password')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    }
    if (lower.contains('email not confirmed') ||
        lower.contains('email_not_confirmed')) {
      return '이메일 인증 후 로그인해주세요. (인증 메일 제한이면 관리자 설정이 필요합니다)';
    }
    if (lower.contains('signups not allowed') ||
        lower.contains('signup is disabled')) {
      return '현재 회원가입/로그인이 비활성화되어 있습니다. 관리자에게 문의해주세요.';
    }
    if (lower.contains('too many requests') ||
        lower.contains('too_many_requests') ||
        lower.contains('over request rate limit') ||
        lower.contains('rate limit')) {
      return '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.';
    }
    if (lower.contains('user not found')) {
      return '가입 내역이 없는 이메일입니다.';
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('timed out') ||
        lower.contains('failed host lookup')) {
      return '네트워크 상태를 확인한 뒤 다시 시도해주세요.';
    }
    return '로그인에 실패했습니다. 잠시 후 다시 시도해주세요.';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final rememberLogin = ref.watch(rememberLoginProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 80),

                // 로고 영역
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('혜핏', style: AppTextStyles.heading1),
                      const SizedBox(height: 4),
                      Text(
                        '카드 혜택 자동 금융비서',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // 이메일
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: AppTextStyles.body1,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    hintText: 'example@email.com',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: AppColors.textHint,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요';
                    }
                    if (!value.contains('@')) {
                      return '올바른 이메일 형식이 아닙니다';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // 비밀번호
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: AppTextStyles.body1,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    hintText: '6자 이상',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: AppColors.textHint,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textHint,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요';
                    }
                    if (value.length < 6) {
                      return '비밀번호는 6자 이상이어야 합니다';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Checkbox(
                      value: rememberLogin,
                      onChanged: isLoading
                          ? null
                          : (value) {
                              ref
                                  .read(rememberLoginProvider.notifier)
                                  .state = value ?? false;
                            },
                    ),
                    Text(
                      '자동 로그인',
                      style: AppTextStyles.body2,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 로그인 버튼
                ElevatedButton(
                  onPressed: isLoading ? null : _handleLogin,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : const Text('로그인'),
                ),

                const SizedBox(height: 16),

                // 회원가입 링크
                TextButton(
                  onPressed: () => context.push('/user/signup'),
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.body2,
                      children: [
                        const TextSpan(text: '계정이 없으신가요? '),
                        TextSpan(
                          text: '회원가입',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 구분선
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppColors.divider),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppColors.divider),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 비회원 둘러보기 버튼
                OutlinedButton.icon(
                  onPressed: () {
                    ref
                        .read(authNotifierProvider.notifier)
                        .enterGuestMode();
                  },
                  icon: const Icon(Icons.explore_outlined),
                  label: const Text('비회원으로 둘러보기'),
                ),

                const SizedBox(height: 8),

                Text(
                  '데모 데이터로 앱을 체험할 수 있습니다',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textHint,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
