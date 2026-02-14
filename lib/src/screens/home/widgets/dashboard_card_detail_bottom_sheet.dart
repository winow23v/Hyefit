import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/card_detail_meta.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/card_provider.dart';
import '../../../services/benefit_engine.dart';
import '../../card/widgets/card_detail_sections.dart';

class DashboardCardDetailBottomSheet extends ConsumerWidget {
  final BenefitResult result;

  const DashboardCardDetailBottomSheet({super.key, required this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardMaster = result.userCard.cardMaster;
    final tiersAsync = ref.watch(
      cardTiersProvider(result.userCard.cardMasterId),
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textHint.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text('상세보기', style: AppTextStyles.heading2)),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 24),
                  onPressed: () => Navigator.pop(context),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              children: [
                CardDetailSummaryCard(
                  cardMaster: cardMaster,
                  fallbackTitle: result.userCard.displayName,
                  margin: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                tiersAsync.when(
                  data: (tiers) {
                    final benefitLines =
                        CardDetailMetaFormatter.mainBenefitLines(
                          cardMaster,
                          tiers,
                        );

                    return CardDetailMetaTable(
                      annualFee: CardDetailMetaFormatter.annualFeeLabel(
                        cardMaster,
                      ),
                      brand: CardDetailMetaFormatter.brandLabel(cardMaster),
                      mainBenefits: benefitLines.join('\n'),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  error: (_, __) => CardDetailMetaTable(
                    annualFee: CardDetailMetaFormatter.annualFeeLabel(
                      cardMaster,
                    ),
                    brand: CardDetailMetaFormatter.brandLabel(cardMaster),
                    mainBenefits: cardMaster?.description.isNotEmpty == true
                        ? cardMaster!.description
                        : '혜택 정보를 불러올 수 없어요',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
