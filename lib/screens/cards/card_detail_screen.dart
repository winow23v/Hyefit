import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/card_provider.dart';
import '../../providers/benefit_provider.dart';
import '../../widgets/benefit_progress_card.dart';

class CardDetailScreen extends ConsumerWidget {
  final String userCardId;

  const CardDetailScreen({super.key, required this.userCardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userCards = ref.watch(userCardsProvider);
    final benefitResults = ref.watch(benefitResultsProvider);

    return userCards.when(
      data: (cards) {
        final card = cards.where((c) => c.id == userCardId).firstOrNull;
        if (card == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('카드 상세')),
            body: const Center(child: Text('카드를 찾을 수 없습니다')),
          );
        }

        final result = benefitResults.whenOrNull(
          data: (results) =>
              results.where((r) => r.userCard.id == userCardId).firstOrNull,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(card.displayName),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: '별명 수정',
                onPressed: () =>
                    _showEditNicknameDialog(context, ref, card.id, card.nickname),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              // 카드 정보
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (card.cardMaster != null) ...[
                      Text(
                        card.cardMaster!.cardName,
                        style: AppTextStyles.heading3,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.cardMaster!.issuer,
                        style: AppTextStyles.body2,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '연회비 ${card.cardMaster!.annualFee > 0 ? '${card.cardMaster!.annualFee}원' : '없음'}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                    if (card.nickname != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '별명: ${card.nickname}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 혜택 진행 현황
              if (result != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '이번 달 혜택 현황',
                    style: AppTextStyles.heading3,
                  ),
                ),
                const SizedBox(height: 8),
                BenefitProgressCard(result: result),
              ],
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('카드 상세')),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('카드 상세')),
        body: Center(child: Text('오류: $error')),
      ),
    );
  }

  void _showEditNicknameDialog(
    BuildContext context,
    WidgetRef ref,
    String cardId,
    String? currentNickname,
  ) {
    final controller = TextEditingController(text: currentNickname ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('별명 수정', style: AppTextStyles.heading3),
        content: TextFormField(
          controller: controller,
          style: AppTextStyles.body1,
          decoration: const InputDecoration(
            hintText: '예: 월급카드',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(userCardsProvider.notifier).updateNickname(
                      userCardId: cardId,
                      nickname: controller.text,
                    );
              }
              Navigator.pop(ctx);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
