import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authNotifierProvider.notifier).signUp(
          nickname: _nicknameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) {
      final displayMsg = _mapSignUpError(authState.error.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayMsg),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      // 이메일 확인 안내 다이얼로그
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          icon: const Icon(
            Icons.mark_email_read_rounded,
            color: AppColors.success,
            size: 48,
          ),
          title: Text('가입 완료!', style: AppTextStyles.heading3),
          content: Text(
            '${_emailController.text.trim()}으로 인증 메일을 보냈습니다.\n\n'
            '메일함에서 인증 링크를 클릭한 후 로그인해주세요.\n\n'
            '(스팸함도 확인해주세요)',
            style: AppTextStyles.body2,
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.pop();
              },
              child: const Text('로그인 화면으로'),
            ),
          ],
        ),
      );
    }
  }

  String _mapSignUpError(String rawError) {
    final lower = rawError.toLowerCase();
    if (lower.contains('already registered') ||
        lower.contains('already exists') ||
        lower.contains('user_already_exists')) {
      return '이미 가입된 이메일입니다. 로그인해주세요.';
    }
    if (lower.contains('invalid') && lower.contains('email')) {
      return '유효하지 않은 이메일 주소입니다.';
    }
    if (lower.contains('weak password') ||
        lower.contains('password should be at least') ||
        lower.contains('password must be at least')) {
      return '비밀번호가 너무 짧습니다. 6자 이상 입력해주세요.';
    }
    if (lower.contains('signups not allowed') ||
        lower.contains('signup is disabled')) {
      return '현재 회원가입이 비활성화되어 있습니다. 관리자에게 문의해주세요.';
    }
    if (lower.contains('email address not authorized')) {
      return '현재 메일 발송 설정으로는 해당 주소 인증이 불가합니다. 관리자 설정이 필요합니다.';
    }
    if (lower.contains('rate limit') ||
        lower.contains('too many requests') ||
        lower.contains('request this after')) {
      return '인증메일 발송 제한에 걸렸습니다. 잠시 후 다시 시도해주세요.';
    }
    if (lower.contains('redirect') && lower.contains('not allowed')) {
      return '인증 링크 설정에 문제가 있습니다. 잠시 후 다시 시도해주세요.';
    }
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('failed host lookup') ||
        lower.contains('timed out')) {
      return '네트워크 상태를 확인한 뒤 다시 시도해주세요.';
    }
    return '회원가입에 실패했습니다. 잠시 후 다시 시도해주세요.';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                Text(
                  '혜핏에 오신 것을 환영합니다',
                  style: AppTextStyles.heading2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '닉네임과 이메일로 간편하게 가입하세요',
                  style: AppTextStyles.body2,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                TextFormField(
                  controller: _nicknameController,
                  autocorrect: false,
                  style: AppTextStyles.body1,
                  decoration: const InputDecoration(
                    labelText: '닉네임',
                    hintText: '예: 아끼자',
                    prefixIcon: Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.textHint,
                    ),
                  ),
                  validator: (value) {
                    final nickname = value?.trim() ?? '';
                    if (nickname.isEmpty) {
                      return '닉네임을 입력해주세요';
                    }
                    if (nickname.length < 2) {
                      return '닉네임은 2자 이상이어야 합니다';
                    }
                    if (nickname.length > 20) {
                      return '닉네임은 20자 이하로 입력해주세요';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

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

                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  style: AppTextStyles.body1,
                  decoration: const InputDecoration(
                    labelText: '비밀번호 확인',
                    hintText: '비밀번호를 다시 입력',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: AppColors.textHint,
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return '비밀번호가 일치하지 않습니다';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: isLoading ? null : _handleSignUp,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : const Text('가입하기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
