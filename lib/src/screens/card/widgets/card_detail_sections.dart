import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/card_thumbnail.dart';
import '../../../components/card_detail_meta.dart';
import '../../../core/constants/categories.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/card_benefit_tier.dart';
import '../../../models/card_master.dart';
import '../../../models/card_tier_rule.dart';

class CardDetailSummaryCard extends StatelessWidget {
  final CardMaster? cardMaster;
  final String fallbackTitle;
  final EdgeInsetsGeometry margin;

  const CardDetailSummaryCard({
    super.key,
    required this.cardMaster,
    required this.fallbackTitle,
    this.margin = const EdgeInsets.fromLTRB(16, 16, 16, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CardThumbnail(
            cardMaster: cardMaster,
            width: 64,
            height: 64,
            borderRadius: 10,
            iconSize: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cardMaster?.issuer ?? '', style: AppTextStyles.body2),
                const SizedBox(height: 2),
                Text(
                  cardMaster?.cardName ?? fallbackTitle,
                  style: AppTextStyles.heading3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CardDetailInfoSection extends StatelessWidget {
  final CardMaster? cardMaster;
  final AsyncValue<List<CardBenefitTier>> tiersAsync;

  const CardDetailInfoSection({
    super.key,
    required this.cardMaster,
    required this.tiersAsync,
  });

  @override
  Widget build(BuildContext context) {
    if (cardMaster == null) return const SizedBox.shrink();

    return tiersAsync.when(
      data: (tiers) {
        final benefitLines = CardDetailMetaFormatter.mainBenefitLines(
          cardMaster,
          tiers,
        );
        final prevSpendText = CardDetailMetaFormatter.prevMonthSpendText(
          cardMaster,
          tiers,
        );

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: CardDetailMetaTable(
            annualFee: CardDetailMetaFormatter.annualFeeLabel(cardMaster),
            brand: CardDetailMetaFormatter.brandLabel(cardMaster),
            mainBenefits: benefitLines.join('\n'),
            prevMonthSpend: prevSpendText,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class CardDetailBenefitSection extends StatelessWidget {
  final AsyncValue<List<CardBenefitTier>> tiersAsync;

  const CardDetailBenefitSection({super.key, required this.tiersAsync});

  @override
  Widget build(BuildContext context) {
    return tiersAsync.when(
      data: (tiers) {
        final items = _buildBenefitItems(tiers);
        if (items.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '아직 등록된 혜택이 없어요',
              style: AppTextStyles.body2.copyWith(color: AppColors.textHint),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: items.map((item) {
              final hasLimit = item.maxBenefitAmount > 0;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: item.category.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.category.icon,
                        size: 18,
                        color: item.category.color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.category.label,
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.rule.benefitTypeLabel} ${item.rateLabel}${hasLimit ? ' · 월 최대 ${CardDetailMetaFormatter.formatCurrency(item.maxBenefitAmount)}원' : ''}',
                            style: AppTextStyles.body2,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.conditionLabel,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, __) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '혜택 정보를 불러올 수 없어요',
          style: AppTextStyles.body2.copyWith(color: AppColors.error),
        ),
      ),
    );
  }

  List<_BenefitListItem> _buildBenefitItems(List<CardBenefitTier> tiers) {
    final items = <_BenefitListItem>[];
    final sortedTiers = List<CardBenefitTier>.from(tiers)
      ..sort((a, b) => a.tierOrder.compareTo(b.tierOrder));

    for (final tier in sortedTiers) {
      final sortedRules = List.of(tier.rules)
        ..sort((a, b) => a.priority.compareTo(b.priority));
      for (final rule in sortedRules) {
        if (rule.category.trim().isEmpty) continue;
        items.add(
          _BenefitListItem(
            category: Categories.findByKey(rule.category),
            rule: rule,
            conditionLabel: CardDetailMetaFormatter.tierConditionText(tier),
          ),
        );
      }
    }
    return items;
  }
}

class CardDetailSpendConditionSection extends StatelessWidget {
  final AsyncValue<List<CardBenefitTier>> tiersAsync;

  const CardDetailSpendConditionSection({super.key, required this.tiersAsync});

  @override
  Widget build(BuildContext context) {
    return tiersAsync.when(
      data: (tiers) {
        if (tiers.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '실적 조건 없이 혜택 적용',
              style: AppTextStyles.body2.copyWith(color: AppColors.textHint),
            ),
          );
        }

        final sorted = List<CardBenefitTier>.from(tiers)
          ..sort((a, b) => a.tierOrder.compareTo(b.tierOrder));

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sorted.map((tier) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  '• ${CardDetailMetaFormatter.tierConditionText(tier)}',
                  style: AppTextStyles.body2,
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _BenefitListItem {
  final SpendCategory category;
  final CardTierRule rule;
  final String conditionLabel;

  _BenefitListItem({
    required this.category,
    required this.rule,
    required this.conditionLabel,
  });

  String get rateLabel => rule.benefitRate % 1 == 0
      ? '${rule.benefitRate.toStringAsFixed(0)}%'
      : '${rule.benefitRate.toStringAsFixed(1)}%';

  int get maxBenefitAmount => rule.maxBenefitAmount;
}
