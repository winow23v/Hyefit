import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/card_benefit_tier.dart';
import '../models/card_master.dart';

final _currencyFormat = NumberFormat('#,###', 'ko_KR');

class CardDetailMetaFormatter {
  CardDetailMetaFormatter._();

  static String formatCurrency(int amount) => _currencyFormat.format(amount);

  static String annualFeeLabel(CardMaster? cardMaster) {
    if (cardMaster == null) return '없음';
    final domestic = cardMaster.displayAnnualFeeDomestic;
    final overseas = cardMaster.displayAnnualFeeOverseas;
    if (domestic <= 0 && overseas <= 0) return '없음';
    return '국내 ${formatCurrency(domestic)}원, 해외 ${formatCurrency(overseas)}원';
  }

  static String brandLabel(CardMaster? cardMaster) {
    if (cardMaster == null || cardMaster.brandOptions.isEmpty) {
      return '정보 없음';
    }
    return cardMaster.brandOptions.join('/');
  }

  static List<String> mainBenefitLines(
    CardMaster? cardMaster,
    List<CardBenefitTier> tiers,
  ) {
    if (cardMaster != null && cardMaster.mainBenefits.isNotEmpty) {
      // 중복 제거: 괄호 포함된 상세 설명만 유지하고 간단한 설명 제거
      final benefits = cardMaster.mainBenefits;
      final filtered = <String>[];
      final seen = <String>{};

      for (final benefit in benefits) {
        // 괄호가 있는 항목 우선 (상세 설명)
        if (benefit.contains('[') || benefit.contains('(')) {
          filtered.add(benefit);
          // 핵심 키워드 추출 (예: "배달앱", "카페" 등)
          final keywords = benefit.replaceAll(RegExp(r'[\[\]\(\)]'), '')
              .split(RegExp(r'[/,\s]+'))
              .where((w) => w.length > 1)
              .take(3);
          seen.addAll(keywords);
        }
      }

      // 괄호 없는 간단한 항목은 중복 체크 후 추가
      for (final benefit in benefits) {
        if (!benefit.contains('[') && !benefit.contains('(')) {
          final isDuplicate = seen.any((keyword) =>
            benefit.contains(keyword) && keyword.length > 2
          );
          if (!isDuplicate) {
            filtered.add(benefit);
          }
        }
      }

      return filtered.take(4).toList(); // 최대 4줄로 제한
    }

    final lines = <String>{};
    final sortedTiers = List<CardBenefitTier>.from(tiers)
      ..sort((a, b) => a.tierOrder.compareTo(b.tierOrder));
    for (final tier in sortedTiers) {
      final sorted = List.of(tier.rules)
        ..sort((a, b) => a.priority.compareTo(b.priority));
      for (final rule in sorted) {
        final rateText = rule.benefitRate % 1 == 0
            ? rule.benefitRate.toStringAsFixed(0)
            : rule.benefitRate.toStringAsFixed(1);
        lines.add(
          '${rule.category} $rateText% ${rule.benefitTypeLabel} (${tierConditionText(tier)})',
        );
      }
    }

    if (lines.isNotEmpty) return lines.take(8).toList();
    if (cardMaster != null && cardMaster.description.trim().isNotEmpty) {
      return [cardMaster.description.trim()];
    }
    return const ['등록된 혜택 정보 없음'];
  }

  static String prevMonthSpendText(
    CardMaster? cardMaster,
    List<CardBenefitTier> tiers,
  ) {
    if (cardMaster != null && cardMaster.prevMonthSpendText.trim().isNotEmpty) {
      return cardMaster.prevMonthSpendText.trim();
    }

    int? requiredSpend;
    for (final tier in tiers) {
      if (tier.minPrevSpend <= 0) continue;
      if (requiredSpend == null || tier.minPrevSpend < requiredSpend) {
        requiredSpend = tier.minPrevSpend;
      }
    }

    if (requiredSpend == null || requiredSpend <= 0) return '조건 없음';
    return '직전 1개월 ${formatCurrency(requiredSpend)}원 이상';
  }

  static String tierConditionText(CardBenefitTier tier) {
    if (tier.minPrevSpend <= 0 && tier.maxPrevSpend == null) {
      return '전월 실적 조건 없음';
    }
    if (tier.maxPrevSpend == null) {
      return '전월 ${formatCurrency(tier.minPrevSpend)}원 이상';
    }

    // 최대값이 너무 크거나 비현실적이면 "이상"으로 표시
    if (tier.maxPrevSpend! >= 10000000) { // 1천만원 이상이면
      return '전월 ${formatCurrency(tier.minPrevSpend)}원 이상';
    }

    return '전월 ${formatCurrency(tier.minPrevSpend)}~${formatCurrency(tier.maxPrevSpend!)}원';
  }
}

class CardDetailMetaTable extends StatelessWidget {
  final String annualFee;
  final String brand;
  final String mainBenefits;
  final EdgeInsetsGeometry padding;

  const CardDetailMetaTable({
    super.key,
    required this.annualFee,
    required this.brand,
    required this.mainBenefits,
    this.padding = const EdgeInsets.fromLTRB(2, 8, 2, 0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: Column(
        children: [
          _infoRow('연회비', annualFee),
          const SizedBox(height: 12),
          _infoRow('브랜드', brand),
          const SizedBox(height: 12),
          _infoRow('주요혜택', mainBenefits),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
