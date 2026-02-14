import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../services/benefit_engine.dart';

final _currencyFormat = NumberFormat('#,###', 'ko_KR');

class RecommendedCardWidget extends StatelessWidget {
  final BenefitResult result;

  const RecommendedCardWidget({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.primaryDark.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '오늘의 추천',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            result.userCard.displayName,
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 4),
          if (result.userCard.cardMaster != null)
            Text(
              result.userCard.cardMaster!.issuer,
              style: AppTextStyles.body2,
            ),
          const SizedBox(height: 16),
          if (result.isBenefitActive)
            _buildInfoRow(
              '예상 혜택',
              '${_currencyFormat.format(result.estimatedBenefit)}원',
              AppColors.success,
            )
          else if (result.remainingForBenefit > 0)
            _buildInfoRow(
              '다음 달 혜택까지',
              '${_currencyFormat.format(result.remainingForBenefit)}원 더 필요',
              AppColors.info,
            )
          else
            _buildInfoRow(
              '다음 달 혜택',
              '적용 예정',
              AppColors.success,
            ),
          const SizedBox(height: 8),
          _buildInfoRow(
            '이번 달 사용',
            '${_currencyFormat.format(result.totalSpend)}원',
            AppColors.textPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body2),
        Text(
          value,
          style: AppTextStyles.numberSmall.copyWith(color: valueColor),
        ),
      ],
    );
  }
}
