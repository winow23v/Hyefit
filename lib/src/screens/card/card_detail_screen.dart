import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/benefit_provider.dart';
import '../../providers/card_provider.dart';
import '../../components/benefit_progress_card.dart';
import 'widgets/card_detail_sections.dart';

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
        final tiersAsync = ref.watch(cardTiersProvider(card.cardMasterId));

        return Scaffold(
          appBar: AppBar(
            title: const Text('상세보기'),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: '별명 수정',
                onPressed: () => _showEditNicknameDialog(
                  context,
                  ref,
                  card.id,
                  card.nickname,
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              CardDetailSummaryCard(
                cardMaster: card.cardMaster,
                fallbackTitle: card.displayName,
              ),
              CardDetailInfoSection(
                cardMaster: card.cardMaster,
                tiersAsync: tiersAsync,
              ),
              if (result != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('이번 달 혜택 현황', style: AppTextStyles.heading3),
                ),
                const SizedBox(height: 8),
                BenefitProgressCard(result: result),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                child: Text('주요 혜택', style: AppTextStyles.heading3),
              ),
              CardDetailBenefitSection(tiersAsync: tiersAsync),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                child: Text('실적 조건', style: AppTextStyles.heading3),
              ),
              CardDetailSpendConditionSection(tiersAsync: tiersAsync),
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
          decoration: const InputDecoration(hintText: '예: 월급카드'),
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
                ref
                    .read(userCardsProvider.notifier)
                    .updateNickname(
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
