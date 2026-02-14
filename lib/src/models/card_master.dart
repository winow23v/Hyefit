class CardMaster {
  final String id;
  final String cardName;
  final String issuer;
  final int annualFee;
  final int annualFeeDomestic;
  final int annualFeeOverseas;
  final String imageColor;
  final String cardImageUrl;
  final List<String> brandOptions;
  final List<String> mainBenefits;
  final String prevMonthSpendText;
  final DateTime createdAt;
  // Tier 기반 스키마 추가 필드
  final int monthlyBenefitCap;
  final double baseBenefitRate;
  final String baseBenefitType;
  final String description;
  final String? officialUrl;

  const CardMaster({
    required this.id,
    required this.cardName,
    required this.issuer,
    required this.annualFee,
    this.annualFeeDomestic = 0,
    this.annualFeeOverseas = 0,
    required this.imageColor,
    this.cardImageUrl = '',
    this.brandOptions = const [],
    this.mainBenefits = const [],
    this.prevMonthSpendText = '',
    required this.createdAt,
    this.monthlyBenefitCap = 0,
    this.baseBenefitRate = 0,
    this.baseBenefitType = 'cashback',
    this.description = '',
    this.officialUrl,
  });

  factory CardMaster.fromJson(Map<String, dynamic> json) {
    return CardMaster(
      id: json['id'] as String,
      cardName: json['card_name'] as String,
      issuer: json['issuer'] as String,
      annualFee: (json['annual_fee'] as num?)?.toInt() ?? 0,
      annualFeeDomestic: (json['annual_fee_domestic'] as num?)?.toInt() ?? 0,
      annualFeeOverseas: (json['annual_fee_overseas'] as num?)?.toInt() ?? 0,
      imageColor: (json['image_color'] as String?) ?? '#7C83FD',
      cardImageUrl: (json['card_image_url'] as String?) ?? '',
      brandOptions: _parseStringList(json['brand_options']),
      mainBenefits: _parseStringList(json['main_benefits']),
      prevMonthSpendText: (json['prev_month_spend_text'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      monthlyBenefitCap: (json['monthly_benefit_cap'] as int?) ?? 0,
      baseBenefitRate: ((json['base_benefit_rate'] as num?) ?? 0).toDouble(),
      baseBenefitType: (json['base_benefit_type'] as String?) ?? 'cashback',
      description: (json['description'] as String?) ?? '',
      officialUrl: json['official_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'card_name': cardName,
      'issuer': issuer,
      'annual_fee': annualFee,
      'annual_fee_domestic': annualFeeDomestic,
      'annual_fee_overseas': annualFeeOverseas,
      'image_color': imageColor,
      'card_image_url': cardImageUrl,
      'brand_options': brandOptions,
      'main_benefits': mainBenefits,
      'prev_month_spend_text': prevMonthSpendText,
      'monthly_benefit_cap': monthlyBenefitCap,
      'base_benefit_rate': baseBenefitRate,
      'base_benefit_type': baseBenefitType,
      'description': description,
    };
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(RegExp(r'[,/\n|]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  int get displayAnnualFeeDomestic =>
      annualFeeDomestic > 0 ? annualFeeDomestic : annualFee;

  int get displayAnnualFeeOverseas =>
      annualFeeOverseas > 0 ? annualFeeOverseas : displayAnnualFeeDomestic;

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

  /// 카드사 공식 URL (없으면 카드별 검색 URL 반환)
  String get cardOfficialUrl {
    // DB에 저장된 URL이 있으면 우선 사용
    if (officialUrl != null && officialUrl!.isNotEmpty) {
      return officialUrl!;
    }

    // 카드사별 검색 페이지로 이동
    final issuerLower = issuer.toLowerCase();
    final searchQuery = Uri.encodeComponent('$issuer $cardName 카드 혜택');

    if (issuerLower.contains('kb') || issuerLower.contains('국민')) {
      // KB국민카드: 사이트 내 검색
      return 'https://card.kbcard.com/CRD/DVIEW/HCAMCXSRCHC0001?mainCC=a&searchWord=${Uri.encodeComponent(cardName)}';
    } else if (issuerLower.contains('하나')) {
      // 하나카드: 카드 찾기
      return 'https://www.hanacard.co.kr/OPI/OPICS0101.web.do';
    } else if (issuerLower.contains('신한')) {
      // 신한카드: 사이트 내 검색
      return 'https://www.shinhancard.com/pconts/html/search/searchResultCreditCard.html?searchWord=${Uri.encodeComponent(cardName)}';
    } else if (issuerLower.contains('삼성')) {
      // 삼성카드: 카드 찾기
      return 'https://www.samsungcard.com/personal/card/search/UHPPCA0101M0.jsp?keyword=${Uri.encodeComponent(cardName)}';
    } else if (issuerLower.contains('현대')) {
      // 현대카드: 카드 찾기
      return 'https://www.hyundaicard.com/cpc/cr/CPCCR0202_01.hc?searchWord=${Uri.encodeComponent(cardName)}';
    } else if (issuerLower.contains('롯데')) {
      // 롯데카드: 검색
      return 'https://www.lottecard.co.kr/app/LPCDAAZ_V100.lc?kwd=${Uri.encodeComponent(cardName)}';
    } else if (issuerLower.contains('우리')) {
      // 우리카드: 검색
      return 'https://www.wooricard.com/dcps/cpc/search/list.do?query=${Uri.encodeComponent(cardName)}';
    } else if (issuerLower.contains('nh') || issuerLower.contains('농협')) {
      // NH농협카드: 카드 찾기
      return 'https://card.nonghyup.com/retrieve.cms?searchStr=${Uri.encodeComponent(cardName)}';
    } else if (issuerLower.contains('bc')) {
      // BC카드: 검색
      return 'https://www.bccard.com/app/card/CCONAC0100M.do?searchWord=${Uri.encodeComponent(cardName)}';
    }

    // 기본값: Google 검색으로 카드 혜택 찾기
    return 'https://www.google.com/search?q=$searchQuery';
  }
}
