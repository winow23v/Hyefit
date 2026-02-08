class UserCardStatus {
  final String id;
  final String userCardId;
  final int currentSpend;
  final int currentBenefit;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime updatedAt;

  const UserCardStatus({
    required this.id,
    required this.userCardId,
    required this.currentSpend,
    required this.currentBenefit,
    required this.periodStart,
    required this.periodEnd,
    required this.updatedAt,
  });

  factory UserCardStatus.fromJson(Map<String, dynamic> json) {
    return UserCardStatus(
      id: json['id'] as String,
      userCardId: json['user_card_id'] as String,
      currentSpend: json['current_spend'] as int,
      currentBenefit: json['current_benefit'] as int,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_card_id': userCardId,
      'current_spend': currentSpend,
      'current_benefit': currentBenefit,
      'period_start': periodStart.toIso8601String().substring(0, 10),
      'period_end': periodEnd.toIso8601String().substring(0, 10),
    };
  }
}
