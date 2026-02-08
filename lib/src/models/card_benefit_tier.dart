import 'card_tier_rule.dart';

class CardBenefitTier {
  final String id;
  final String cardId;
  final String tierName;
  final int minPrevSpend;
  final int? maxPrevSpend;
  final int tierOrder;
  final DateTime createdAt;
  final List<CardTierRule> rules;

  const CardBenefitTier({
    required this.id,
    required this.cardId,
    required this.tierName,
    required this.minPrevSpend,
    this.maxPrevSpend,
    required this.tierOrder,
    required this.createdAt,
    this.rules = const [],
  });

  /// 전월 실적이 이 Tier에 해당하는지 확인
  bool matchesPrevSpend(int prevMonthSpend) {
    if (prevMonthSpend < minPrevSpend) return false;
    if (maxPrevSpend != null && prevMonthSpend > maxPrevSpend!) return false;
    return true;
  }

  /// Supabase nested select 결과에서 파싱
  /// select('*, card_tier_rules(*)')
  factory CardBenefitTier.fromJson(Map<String, dynamic> json) {
    final rulesJson = json['card_tier_rules'] as List<dynamic>? ?? [];
    final rules = rulesJson
        .map((r) => CardTierRule.fromJson(r as Map<String, dynamic>))
        .toList();

    return CardBenefitTier(
      id: json['id'] as String,
      cardId: json['card_id'] as String,
      tierName: (json['tier_name'] as String?) ?? '',
      minPrevSpend: json['min_prev_spend'] as int,
      maxPrevSpend: json['max_prev_spend'] as int?,
      tierOrder: json['tier_order'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      rules: rules,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'card_id': cardId,
      'tier_name': tierName,
      'min_prev_spend': minPrevSpend,
      'max_prev_spend': maxPrevSpend,
      'tier_order': tierOrder,
    };
  }

  /// Tier 범위 표시 문자열
  String get spendRangeLabel {
    final min = _formatAmount(minPrevSpend);
    if (maxPrevSpend == null) {
      return '$min 이상';
    }
    final max = _formatAmount(maxPrevSpend!);
    return '$min ~ $max';
  }

  String _formatAmount(int amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(0)}만원';
    }
    return '$amount원';
  }
}
