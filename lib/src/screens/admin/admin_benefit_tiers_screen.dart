import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/categories.dart';
import '../../models/card_benefit_tier.dart';
import '../../models/card_tier_rule.dart';
import '../../models/card_master.dart';
import '../../providers/card_provider.dart';
import '../../components/category_chip.dart';

final _currencyFormat = NumberFormat('#,###', 'ko_KR');

/// 카드별 Tier 목록을 조회하는 Provider
final _benefitTiersForCardProvider =
    FutureProvider.family<List<CardBenefitTier>, String>((ref, cardId) async {
  final cardService = ref.watch(cardServiceProvider);
  return cardService.getBenefitTiers(cardId);
});

class AdminBenefitTiersScreen extends ConsumerWidget {
  final String cardId;

  const AdminBenefitTiersScreen({super.key, required this.cardId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCards = ref.watch(allCardsProvider);
    final tiers = ref.watch(_benefitTiersForCardProvider(cardId));

    final CardMaster? card = allCards.whenOrNull(
      data: (cards) => cards.where((c) => c.id == cardId).firstOrNull,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(card?.cardName ?? '혜택 Tier'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddTierSheet(context, ref),
        child: const Icon(Icons.add, color: AppColors.textPrimary),
      ),
      body: tiers.when(
        data: (tierList) {
          if (tierList.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.layers_rounded, size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('등록된 Tier가 없습니다', style: AppTextStyles.body1),
                  const SizedBox(height: 8),
                  Text('+ 버튼으로 Tier를 추가하세요', style: AppTextStyles.body2),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tierList.length,
            itemBuilder: (context, index) {
              final tier = tierList[index];
              return _TierCard(
                tier: tier,
                cardId: cardId,
                onAddRule: () => _showAddRuleSheet(context, ref, tier.id),
                onDeleteTier: () => _confirmDeleteTier(context, ref, tier.id),
                onDeleteRule: (ruleId) =>
                    _confirmDeleteRule(context, ref, ruleId),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) =>
            Center(child: Text('오류: $e', style: AppTextStyles.body2)),
      ),
    );
  }

  void _showAddTierSheet(BuildContext context, WidgetRef ref) {
    final tierNameController = TextEditingController();
    final minSpendController = TextEditingController(text: '300000');
    final maxSpendController = TextEditingController();
    final tierOrderController = TextEditingController(text: '1');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
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
                Text('Tier 추가', style: AppTextStyles.heading3),
                const SizedBox(height: 20),
                TextFormField(
                  controller: tierNameController,
                  style: AppTextStyles.body1,
                  decoration: const InputDecoration(
                    labelText: 'Tier 이름',
                    hintText: '예: 30만원 이상',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: minSpendController,
                  style: AppTextStyles.body1,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: '최소 전월 실적',
                    suffixText: '원',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: maxSpendController,
                  style: AppTextStyles.body1,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: '최대 전월 실적 (비워두면 무제한)',
                    suffixText: '원',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: tierOrderController,
                  style: AppTextStyles.body1,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Tier 순서 (숫자가 높을수록 상위)',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final cardService = ref.read(cardServiceProvider);
                      await cardService.addBenefitTier(
                        cardId: cardId,
                        tierName: tierNameController.text.isEmpty
                            ? '${minSpendController.text}원 이상'
                            : tierNameController.text,
                        minPrevSpend: int.parse(minSpendController.text),
                        maxPrevSpend: maxSpendController.text.isEmpty
                            ? null
                            : int.parse(maxSpendController.text),
                        tierOrder: int.parse(tierOrderController.text),
                      );
                      ref.invalidate(_benefitTiersForCardProvider(cardId));
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
  }

  void _showAddRuleSheet(BuildContext context, WidgetRef ref, String tierId) {
    String? selectedCategory;
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
                    Text('카테고리', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    CategoryChipGroup(
                      selectedKey: selectedCategory,
                      onSelected: (key) {
                        setSheetState(() => selectedCategory = key);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('혜택 유형', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _typeChip(
                          label: '캐시백',
                          isSelected: benefitType == 'cashback',
                          onTap: () =>
                              setSheetState(() => benefitType = 'cashback'),
                        ),
                        const SizedBox(width: 8),
                        _typeChip(
                          label: '포인트',
                          isSelected: benefitType == 'point',
                          onTap: () =>
                              setSheetState(() => benefitType = 'point'),
                        ),
                        const SizedBox(width: 8),
                        _typeChip(
                          label: '할인',
                          isSelected: benefitType == 'discount',
                          onTap: () =>
                              setSheetState(() => benefitType = 'discount'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                    TextFormField(
                      controller: maxBenefitController,
                      style: AppTextStyles.body1,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: '월 최대 혜택',
                        suffixText: '원',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priorityController,
                      style: AppTextStyles.body1,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                                final cardService = ref.read(cardServiceProvider);
                                await cardService.addTierRule(
                                  tierId: tierId,
                                  category: selectedCategory!,
                                  benefitType: benefitType,
                                  benefitRate: double.parse(rateController.text),
                                  maxBenefitAmount:
                                      int.parse(maxBenefitController.text),
                                  priority: int.parse(priorityController.text),
                                );
                                ref.invalidate(_benefitTiersForCardProvider(cardId));
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

  void _confirmDeleteTier(BuildContext context, WidgetRef ref, String tierId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Tier 삭제', style: AppTextStyles.heading3),
        content: Text('이 Tier와 모든 규칙을 삭제하시겠습니까?', style: AppTextStyles.body2),
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
              await cardService.deleteBenefitTier(tierId);
              ref.invalidate(_benefitTiersForCardProvider(cardId));
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRule(BuildContext context, WidgetRef ref, String ruleId) {
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
              await cardService.deleteTierRule(ruleId);
              ref.invalidate(_benefitTiersForCardProvider(cardId));
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  final CardBenefitTier tier;
  final String cardId;
  final VoidCallback onAddRule;
  final VoidCallback onDeleteTier;
  final void Function(String ruleId) onDeleteRule;

  const _TierCard({
    required this.tier,
    required this.cardId,
    required this.onAddRule,
    required this.onDeleteTier,
    required this.onDeleteRule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tier 헤더
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(Icons.layers_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.tierName,
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        tier.spendRangeLabel,
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded,
                      color: AppColors.primary),
                  onPressed: onAddRule,
                  tooltip: '규칙 추가',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                  onPressed: onDeleteTier,
                  tooltip: 'Tier 삭제',
                ),
              ],
            ),
          ),

          // 규칙 목록
          if (tier.rules.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('등록된 규칙이 없습니다', style: AppTextStyles.body2),
            )
          else
            ...tier.rules.map((rule) => _RuleRow(
                  rule: rule,
                  onDelete: () => onDeleteRule(rule.id),
                )),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final CardTierRule rule;
  final VoidCallback onDelete;

  const _RuleRow({required this.rule, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cat = Categories.findByKey(rule.category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.cardLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(cat.icon, size: 18, color: cat.color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.label, style: AppTextStyles.body2),
                Text(
                  '${rule.benefitTypeLabel} ${rule.benefitRate}% (최대 ${_currencyFormat.format(rule.maxBenefitAmount)}원)',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}
