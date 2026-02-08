class CardMaster {
  final String id;
  final String cardName;
  final String issuer;
  final int annualFee;
  final String imageColor;
  final DateTime createdAt;
  // Tier 기반 스키마 추가 필드
  final int monthlyBenefitCap;
  final double baseBenefitRate;
  final String baseBenefitType;
  final String description;

  const CardMaster({
    required this.id,
    required this.cardName,
    required this.issuer,
    required this.annualFee,
    required this.imageColor,
    required this.createdAt,
    this.monthlyBenefitCap = 0,
    this.baseBenefitRate = 0,
    this.baseBenefitType = 'cashback',
    this.description = '',
  });

  factory CardMaster.fromJson(Map<String, dynamic> json) {
    return CardMaster(
      id: json['id'] as String,
      cardName: json['card_name'] as String,
      issuer: json['issuer'] as String,
      annualFee: json['annual_fee'] as int,
      imageColor: (json['image_color'] as String?) ?? '#7C83FD',
      createdAt: DateTime.parse(json['created_at'] as String),
      monthlyBenefitCap: (json['monthly_benefit_cap'] as int?) ?? 0,
      baseBenefitRate: ((json['base_benefit_rate'] as num?) ?? 0).toDouble(),
      baseBenefitType: (json['base_benefit_type'] as String?) ?? 'cashback',
      description: (json['description'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'card_name': cardName,
      'issuer': issuer,
      'annual_fee': annualFee,
      'image_color': imageColor,
      'monthly_benefit_cap': monthlyBenefitCap,
      'base_benefit_rate': baseBenefitRate,
      'base_benefit_type': baseBenefitType,
      'description': description,
    };
  }

  /// 월 최대 혜택 표시 문자열
  String get monthlyBenefitCapLabel {
    if (monthlyBenefitCap <= 0) return '한도 없음';
    if (monthlyBenefitCap >= 10000) {
      return '월 ${(monthlyBenefitCap / 10000).toStringAsFixed(0)}만원';
    }
    return '월 $monthlyBenefitCap원';
  }

  /// 기본 혜택률 표시 문자열
  String get baseBenefitLabel {
    if (baseBenefitRate <= 0) return '';
    return '전 가맹점 ${baseBenefitRate.toStringAsFixed(1)}%';
  }
}
