import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/card_master.dart';
import '../../providers/card_provider.dart';

class CardListScreen extends ConsumerWidget {
  const CardListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userCards = ref.watch(userCardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 카드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: '카드 추가',
            onPressed: () => _showAddCardDialog(context, ref),
          ),
        ],
      ),
      body: userCards.when(
        data: (cards) {
          if (cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.credit_card_rounded,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '등록된 카드가 없습니다',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _showAddCardDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('카드 추가하기'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              final cardColor = _parseColor(
                card.cardMaster?.imageColor ?? '#7C83FD',
              );

              return Dismissible(
                key: ValueKey(card.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: Text(
                        '카드 삭제',
                        style: AppTextStyles.heading3,
                      ),
                      content: Text(
                        '${card.displayName}을(를) 삭제하시겠습니까?\n관련 소비 내역도 함께 삭제됩니다.',
                        style: AppTextStyles.body2,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) {
                  ref
                      .read(userCardsProvider.notifier)
                      .removeCard(card.id);
                },
                child: GestureDetector(
                  onTap: () => context.push('/cards/${card.id}'),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cardColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.credit_card_rounded,
                            color: cardColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.displayName,
                                style: AppTextStyles.body1.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (card.cardMaster != null)
                                Text(
                                  '${card.cardMaster!.issuer} · ${card.cardMaster!.cardName}',
                                  style: AppTextStyles.caption,
                                ),
                            ],
                          ),
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
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => Center(
          child: Text('오류: $error', style: AppTextStyles.body2),
        ),
      ),
    );
  }

  void _showAddCardDialog(BuildContext context, WidgetRef ref) {
    final allCards = ref.read(allCardsProvider);
    final nicknameController = TextEditingController();
    CardMaster? selectedCard;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('카드 추가', style: AppTextStyles.heading3),
                  const SizedBox(height: 20),

                  allCards.when(
                    data: (cards) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<CardMaster>(
                            decoration: const InputDecoration(
                              labelText: '카드 선택',
                            ),
                            dropdownColor: AppColors.card,
                            style: AppTextStyles.body1,
                            items: cards.map((card) {
                              return DropdownMenuItem(
                                value: card,
                                child: Text(
                                  '${card.issuer} - ${card.cardName}',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setSheetState(() => selectedCard = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: nicknameController,
                            style: AppTextStyles.body1,
                            decoration: const InputDecoration(
                              labelText: '별명 (선택)',
                              hintText: '예: 월급카드, 교통카드',
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: selectedCard == null
                                ? null
                                : () {
                                    ref
                                        .read(userCardsProvider.notifier)
                                        .addCard(
                                          cardMasterId: selectedCard!.id,
                                          nickname: nicknameController
                                                  .text.isNotEmpty
                                              ? nicknameController.text
                                              : null,
                                        );
                                    Navigator.pop(ctx);
                                  },
                            child: const Text('추가'),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                    error: (e, _) => Text('오류: $e'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
