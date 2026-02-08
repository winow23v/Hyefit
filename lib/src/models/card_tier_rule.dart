class CardTierRule {
  final String id;
  final String tierId;
  final String category;
  final String benefitType;
  final double benefitRate;
  final int maxBenefitAmount;
  final int priority;
  final DateTime createdAt;

  const CardTierRule({
    required this.id,
    required this.tierId,
    required this.category,
    required this.benefitType,
    required this.benefitRate,
    required this.maxBenefitAmount,
    required this.priority,
    required this.createdAt,
  });

  factory CardTierRule.fromJson(Map<String, dynamic> json) {
    return CardTierRule(
      id: json['id'] as String,
      tierId: json['tier_id'] as String,
      category: json['category'] as String,
      benefitType: (json['benefit_type'] as String?) ?? 'cashback',
      benefitRate: (json['benefit_rate'] as num).toDouble(),
      maxBenefitAmount: json['max_benefit_amount'] as int,
      priority: json['priority'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tier_id': tierId,
      'category': category,
      'benefit_type': benefitType,
      'benefit_rate': benefitRate,
      'max_benefit_amount': maxBenefitAmount,
      'priority': priority,
    };
  }

  String get benefitTypeLabel {
    switch (benefitType) {
      case 'cashback':
        return '캐시백';
      case 'point':
        return '포인트';
      case 'discount':
        return '할인';
      case 'mileage':
        return '마일리지';
      default:
        return benefitType;
    }
  }
}
