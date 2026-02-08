import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/card_provider.dart';

final _currencyFormat = NumberFormat('#,###', 'ko_KR');

class AdminCardListScreen extends ConsumerWidget {
  const AdminCardListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCards = ref.watch(allCardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('카드 관리'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: '웹 대량 등록',
            icon: const Icon(Icons.language_rounded),
            onPressed: () => context.push('/admin/cards/web-import'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => context.push('/admin/cards/add'),
        child: const Icon(Icons.add, color: AppColors.textPrimary),
      ),
      body: allCards.when(
        data: (cards) {
          if (cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.credit_card_off_rounded,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('등록된 카드가 없습니다', style: AppTextStyles.body1),
                  const SizedBox(height: 8),
                  Text('+ 버튼으로 새 카드를 추가하세요', style: AppTextStyles.body2),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              final color = _parseColor(card.imageColor);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () =>
                        context.push('/admin/cards/${card.id}/tiers'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.credit_card_rounded,
                              color: color,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card.cardName,
                                  style: AppTextStyles.body1.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${card.issuer} · 연회비 ${_currencyFormat.format(card.annualFee)}원',
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.error, size: 20),
                            onPressed: () =>
                                _confirmDelete(context, ref, card.id, card.cardName),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.textHint),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) =>
            Center(child: Text('오류: $e', style: AppTextStyles.body2)),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, String cardId, String cardName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('카드 삭제', style: AppTextStyles.heading3),
        content: Text(
          '"$cardName"을(를) 삭제하시겠습니까?\n이 카드의 혜택 규칙도 함께 삭제됩니다.',
          style: AppTextStyles.body2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final cardService = ref.read(cardServiceProvider);
              await cardService.deleteCardMaster(cardId);
              ref.invalidate(allCardsProvider);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
