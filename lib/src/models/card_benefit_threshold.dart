class CardBenefitThreshold {
  final String id;
  final String benefitRuleId;
  final int minSpendAmount;
  final int? maxSpendAmount;
  final double benefitRate;

  const CardBenefitThreshold({
    required this.id,
    required this.benefitRuleId,
    required this.minSpendAmount,
    this.maxSpendAmount,
    required this.benefitRate,
  });

  factory CardBenefitThreshold.fromJson(Map<String, dynamic> json) {
    return CardBenefitThreshold(
      id: json['id'] as String,
      benefitRuleId: json['benefit_rule_id'] as String,
      minSpendAmount: json['min_spend_amount'] as int,
      maxSpendAmount: json['max_spend_amount'] as int?,
      benefitRate: (json['benefit_rate'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'benefit_rule_id': benefitRuleId,
      'min_spend_amount': minSpendAmount,
      'max_spend_amount': maxSpendAmount,
      'benefit_rate': benefitRate,
    };
  }
}
