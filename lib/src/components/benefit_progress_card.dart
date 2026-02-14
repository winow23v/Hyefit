import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'card_thumbnail.dart';
import '../services/benefit_engine.dart';

final _currencyFormat = NumberFormat('#,###', 'ko_KR');

class BenefitProgressCard extends StatelessWidget {
  final BenefitResult result;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  const BenefitProgressCard({
    super.key,
    required this.result,
    this.onTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = _parseColor(
      result.userCard.cardMaster?.imageColor ?? '#7C83FD',
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardColor.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카드 이름 + 발급사
            Row(
              children: [
                CardThumbnail(
                  cardMaster: result.userCard.cardMaster,
                  width: 28,
                  height: 28,
                  borderRadius: 8,
                  iconSize: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.userCard.displayName,
                    style: AppTextStyles.heading3,
                  ),
                ),
                if (result.isBenefitActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '혜택 받는 중',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
              ],
            ),

            if (result.userCard.cardMaster != null) ...[
              const SizedBox(height: 4),
              Text(
                result.userCard.cardMaster!.issuer,
                style: AppTextStyles.caption,
              ),
            ],

            const SizedBox(height: 16),

            // 진행 바
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: result.progress,
                minHeight: 8,
                backgroundColor: AppColors.cardLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  result.isBenefitActive ? AppColors.success : AppColors.primary,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 소비 / 기준 금액
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_currencyFormat.format(result.totalSpend)}원',
                  style: AppTextStyles.numberSmall.copyWith(color: AppColors.primary),
                ),
                Text(
                  '/ ${_currencyFormat.format(result.minMonthlySpend)}원',
                  style: AppTextStyles.body2,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // 혜택까지 남은 금액 or 예상 혜택
            if (!result.isBenefitActive && result.remainingForBenefit > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '다음 달 혜택을 위해\n이번 달 ${_currencyFormat.format(result.remainingForBenefit)}원 더 사용하세요',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.info,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else if (!result.isBenefitActive && result.remainingForBenefit == 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '다음 달부터 혜택 적용 예정',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '이번 달 받을 혜택 ${_currencyFormat.format(result.estimatedBenefit)}원',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
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
