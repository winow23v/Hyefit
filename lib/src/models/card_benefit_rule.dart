class CardBenefitRule {
  final String id;
  final String cardId;
  final String category;
  final int minMonthlySpend;
  final String benefitType;
  final double benefitRate;
  final int maxBenefitAmount;
  final int startDay;
  final int endDay;
  final int priority;
  final DateTime createdAt;

  const CardBenefitRule({
    required this.id,
    required this.cardId,
    required this.category,
    required this.minMonthlySpend,
    required this.benefitType,
    required this.benefitRate,
    required this.maxBenefitAmount,
    required this.startDay,
    required this.endDay,
    required this.priority,
    required this.createdAt,
  });

  factory CardBenefitRule.fromJson(Map<String, dynamic> json) {
    return CardBenefitRule(
      id: json['id'] as String,
      cardId: json['card_id'] as String,
      category: json['category'] as String,
      minMonthlySpend: json['min_monthly_spend'] as int,
      benefitType: json['benefit_type'] as String,
      benefitRate: (json['benefit_rate'] as num).toDouble(),
      maxBenefitAmount: json['max_benefit_amount'] as int,
      startDay: json['start_day'] as int,
      endDay: json['end_day'] as int,
      priority: json['priority'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'card_id': cardId,
      'category': category,
      'min_monthly_spend': minMonthlySpend,
      'benefit_type': benefitType,
      'benefit_rate': benefitRate,
      'max_benefit_amount': maxBenefitAmount,
      'start_day': startDay,
      'end_day': endDay,
      'priority': priority,
    };
  }

  String get benefitTypeLabel =>
      benefitType == 'cashback' ? '캐시백' : '포인트';
}
