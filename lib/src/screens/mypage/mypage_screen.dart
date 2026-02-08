import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../card/card_add_screen.dart';

const _adminWebLocalPathUrl = 'http://<맥북IP>:8080/card-admin';

class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestModeProvider);
    final user = ref.watch(currentUserProvider);
    final nickname = ref.watch(userNicknameProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final displayName = isGuest ? '게스트' : (nickname ?? user?.email ?? '사용자');
    final accountLabel = isGuest
        ? '데모 모드로 이용 중'
        : (isAdmin ? '관리자' : '혜핏 회원');

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 프로필 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 28,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        accountLabel,
                        style: AppTextStyles.body2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 카드 메뉴 (로그인 사용자)
          if (!isGuest) ...[
            Text('카드', style: AppTextStyles.caption),
            const SizedBox(height: 8),

            _MenuTile(
              icon: Icons.add_card_rounded,
              label: '내 카드 추가',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => const CardAddScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            if (isAdmin) ...[
              const SizedBox(height: 8),
              _MenuTile(
                icon: Icons.language_rounded,
                label: '카드 관리 (웹)',
                onTap: () => _showWebAdminGuideDialog(context),
              ),
            ],

            const SizedBox(height: 24),
          ],

          Text('계정', style: AppTextStyles.caption),
          const SizedBox(height: 8),

          _MenuTile(
            icon: isGuest ? Icons.login_rounded : Icons.logout_rounded,
            label: isGuest ? '로그인하기' : '로그아웃',
            onTap: () {
              ref.read(authNotifierProvider.notifier).signOut();
            },
          ),

          const SizedBox(height: 40),

          // 앱 버전
          Center(
            child: Text(
              '혜핏 v1.0.0',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showWebAdminGuideDialog(BuildContext context) async {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          const Icon(Icons.language_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          const Text('카드 관리 (웹)', style: AppTextStyles.heading3),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                _adminWebLocalPathUrl,
                style: AppTextStyles.body2.copyWith(
                  fontFamily: 'monospace',
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(
              const ClipboardData(text: _adminWebLocalPathUrl),
            );
            if (!ctx.mounted) return;
            ScaffoldMessenger.of(ctx).showSnackBar(
              const SnackBar(
                content: Text('URL이 복사되었습니다'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: const Text('URL 복사'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('닫기'),
        ),
      ],
    ),
  );
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: AppTextStyles.body1),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
