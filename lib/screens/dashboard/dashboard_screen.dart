import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/benefit_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/benefit_progress_card.dart';
import '../../widgets/recommended_card_widget.dart';

final _currencyFormat = NumberFormat('#,###', 'ko_KR');
final _monthFormat = DateFormat('yyyy년 M월', 'ko_KR');

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final benefitResults = ref.watch(benefitResultsProvider);
    final recommended = ref.watch(recommendedCardProvider);
    final totalSavings = ref.watch(totalSavingsProvider);
    final refreshDashboard = ref.watch(dashboardRefreshProvider);
    final now = DateTime.now();

    final isGuest = ref.watch(isGuestModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('혜핏'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: '카드 관리',
            onPressed: () => context.push('/admin/cards'),
          ),
          IconButton(
            icon: Icon(
              isGuest ? Icons.login_rounded : Icons.logout_rounded,
            ),
            tooltip: isGuest ? '로그인하기' : '로그아웃',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => refreshDashboard(),
        color: AppColors.primary,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // 게스트 모드 배너
            if (isGuest)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.info,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '데모 모드입니다. 회원가입하면 실제 데이터를 관리할 수 있어요.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // 이번 달 절약 금액
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _monthFormat.format(now),
                      style: AppTextStyles.body2,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _currencyFormat.format(totalSavings),
                          style: AppTextStyles.heading1.copyWith(
                            color: AppColors.success,
                            fontSize: 32,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '원 절약',
                            style: AppTextStyles.body1.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 오늘의 추천 카드
            if (recommended != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('오늘의 추천 카드', style: AppTextStyles.heading3),
              ),
              const SizedBox(height: 12),
              RecommendedCardWidget(result: recommended),
              const SizedBox(height: 24),
            ],

            // 카드별 혜택 진행률
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('카드별 혜택 현황', style: AppTextStyles.heading3),
            ),
            const SizedBox(height: 8),

            benefitResults.when(
              data: (results) {
                if (results.isEmpty) {
                  return _buildEmptyState();
                }
                return Column(
                  children: results
                      .map((r) => BenefitProgressCard(result: r))
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '데이터를 불러올 수 없습니다',
                        style: AppTextStyles.body1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$error',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.credit_card_off_rounded,
            size: 48,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            '등록된 카드가 없습니다',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '카드 탭에서 카드를 등록해보세요',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
