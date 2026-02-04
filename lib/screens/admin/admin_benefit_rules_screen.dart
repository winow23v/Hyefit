import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/categories.dart';
import '../../models/card_benefit_rule.dart';
import '../../models/card_master.dart';
import '../../providers/card_provider.dart';
import '../../widgets/category_chip.dart';

final _currencyFormat = NumberFormat('#,###', 'ko_KR');

/// 카드별 혜택 규칙을 조회 + 추가 + 삭제하는 Provider
final _benefitRulesForCardProvider =
    FutureProvider.family<List<CardBenefitRule>, String>((ref, cardId) async {
  final cardService = ref.watch(cardServiceProvider);
  return cardService.getBenefitRules(cardId);
});

class AdminBenefitRulesScreen extends ConsumerWidget {
  final String cardId;

  const AdminBenefitRulesScreen({super.key, required this.cardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCards = ref.watch(allCardsProvider);
    final rules = ref.watch(_benefitRulesForCardProvider(cardId));

    final CardMaster? card = allCards.whenOrNull(
      data: (cards) =>
          cards.where((c) => c.id == cardId).firstOrNull,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(card?.cardName ?? '혜택 규칙'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddRuleSheet(context, ref),
        child: const Icon(Icons.add, color: AppColors.textPrimary),
      ),
      body: rules.when(
        data: (ruleList) {
          if (ruleList.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rule_rounded,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('등록된 혜택 규칙이 없습니다', style: AppTextStyles.body1),
                  const SizedBox(height: 8),
                  Text('+ 버튼으로 혜택을 추가하세요', style: AppTextStyles.body2),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ruleList.length,
            itemBuilder: (context, index) {
              final rule = ruleList[index];
              final cat = Categories.findByKey(rule.category);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(cat.icon, size: 18, color: cat.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cat.label,
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${rule.benefitTypeLabel} ${rule.benefitRate}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cat.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () =>
                              _confirmDeleteRule(context, ref, rule.id),
                          child: const Icon(Icons.close_rounded,
                              size: 18, color: AppColors.textHint),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _infoRow(
                      '전월 실적 기준',
                      '${_currencyFormat.format(rule.minMonthlySpend)}원 이상',
                    ),
                    _infoRow(
                      '월 최대 혜택',
                      '${_currencyFormat.format(rule.maxBenefitAmount)}원',
                    ),
                    _infoRow('우선순위', '${rule.priority}'),
                  ],
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          Text(value,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  void _showAddRuleSheet(BuildContext context, WidgetRef ref) {
    String? selectedCategory;
    final minSpendController = TextEditingController(text: '300000');
    final rateController = TextEditingController(text: '5');
    final maxBenefitController = TextEditingController(text: '10000');
    final priorityController = TextEditingController(text: '1');
    String benefitType = 'cashback';

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('혜택 규칙 추가', style: AppTextStyles.heading3),
                    const SizedBox(height: 20),

                    // 카테고리
                    Text('카테고리', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    CategoryChipGroup(
                      selectedKey: selectedCategory,
                      onSelected: (key) {
                        setSheetState(() => selectedCategory = key);
                      },
                    ),
                    const SizedBox(height: 16),

                    // 혜택 유형
                    Text('혜택 유형', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _typeChip(
                          label: '캐시백',
                          isSelected: benefitType == 'cashback',
                          onTap: () => setSheetState(
                              () => benefitType = 'cashback'),
                        ),
                        const SizedBox(width: 8),
                        _typeChip(
                          label: '포인트',
                          isSelected: benefitType == 'point',
                          onTap: () =>
                              setSheetState(() => benefitType = 'point'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 전월 실적
                    TextFormField(
                      controller: minSpendController,
                      style: AppTextStyles.body1,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: const InputDecoration(
                        labelText: '전월 실적 기준',
                        suffixText: '원',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 혜택률
                    TextFormField(
                      controller: rateController,
                      style: AppTextStyles.body1,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: '혜택률',
                        suffixText: '%',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 최대 혜택
                    TextFormField(
                      controller: maxBenefitController,
                      style: AppTextStyles.body1,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: const InputDecoration(
                        labelText: '월 최대 혜택',
                        suffixText: '원',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 우선순위
                    TextFormField(
                      controller: priorityController,
                      style: AppTextStyles.body1,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: const InputDecoration(
                        labelText: '우선순위 (숫자가 낮을수록 높음)',
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: selectedCategory == null
                          ? null
                          : () async {
                              try {
                                final cardService =
                                    ref.read(cardServiceProvider);
                                await cardService.addBenefitRule(
                                  cardId: cardId,
                                  category: selectedCategory!,
                                  minMonthlySpend: int.parse(
                                      minSpendController.text),
                                  benefitType: benefitType,
                                  benefitRate: double.parse(
                                      rateController.text),
                                  maxBenefitAmount: int.parse(
                                      maxBenefitController.text),
                                  priority: int.parse(
                                      priorityController.text),
                                );
                                ref.invalidate(
                                    _benefitRulesForCardProvider(
                                        cardId));
                                if (ctx.mounted) Navigator.pop(ctx);
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('추가 실패: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                      child: const Text('추가'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _typeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.cardLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _confirmDeleteRule(
      BuildContext context, WidgetRef ref, String ruleId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('규칙 삭제', style: AppTextStyles.heading3),
        content: Text('이 혜택 규칙을 삭제하시겠습니까?', style: AppTextStyles.body2),
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
              await cardService.deleteBenefitRule(ruleId);
              ref.invalidate(_benefitRulesForCardProvider(cardId));
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
