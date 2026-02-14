import '../models/card_master.dart';
import '../models/card_benefit_tier.dart';
import '../models/card_tier_rule.dart';
import '../models/user_card.dart';
import '../models/transaction.dart';
import 'benefit_engine.dart';

/// 비회원 모드용 데모 데이터 (Tier 기반)
class DemoDataService {
  DemoDataService._();

  static const _guestUserId = 'guest-user-0000';

  static String get guestUserId => _guestUserId;

  // ── 카드 마스터 ──
  static final List<CardMaster> cards = [
    CardMaster(
      id: 'demo-card-001',
      cardName: '신한 Deep Dream',
      issuer: '신한카드',
      annualFee: 12000,
      annualFeeDomestic: 12000,
      annualFeeOverseas: 15000,
      imageColor: '#2563EB',
      brandOptions: const ['국내', 'Master', 'VISA'],
      mainBenefits: const ['외식 10% 캐시백', '교통 10% 캐시백', '편의점 10% 캐시백'],
      prevMonthSpendText: '직전 1개월 30만원 이상',
      createdAt: DateTime.now(),
      monthlyBenefitCap: 25000,
      baseBenefitRate: 0.5,
      baseBenefitType: 'cashback',
      description: '외식/교통/편의점 10% 캐시백',
    ),
    CardMaster(
      id: 'demo-card-002',
      cardName: 'KB 국민 My WE:SH',
      issuer: 'KB국민카드',
      annualFee: 15000,
      annualFeeDomestic: 15000,
      annualFeeOverseas: 15000,
      imageColor: '#DC2626',
      brandOptions: const ['국내', 'Master'],
      mainBenefits: const ['쇼핑 최대 5% 포인트', '마트 최대 5% 캐시백'],
      prevMonthSpendText: '직전 1개월 30만원 이상',
      createdAt: DateTime.now(),
      monthlyBenefitCap: 25000,
      baseBenefitRate: 0.3,
      baseBenefitType: 'point',
      description: '쇼핑/마트 최대 5% 포인트',
    ),
    CardMaster(
      id: 'demo-card-003',
      cardName: '삼성 taptap O',
      issuer: '삼성카드',
      annualFee: 10000,
      annualFeeDomestic: 10000,
      annualFeeOverseas: 10000,
      imageColor: '#7C3AED',
      brandOptions: const ['국내', 'Master'],
      mainBenefits: const ['간편결제 3~5% 캐시백'],
      prevMonthSpendText: '전월 실적 없음',
      createdAt: DateTime.now(),
      monthlyBenefitCap: 15000,
      baseBenefitRate: 0.5,
      baseBenefitType: 'cashback',
      description: '간편결제 3~5%',
    ),
  ];

  // ── Tier 규칙 (신한 Deep Dream) ──
  static final List<CardTierRule> _card1TierRules = [
    CardTierRule(
      id: 'demo-rule-001',
      tierId: 'demo-tier-001',
      category: '외식',
      benefitType: 'cashback',
      benefitRate: 10.0,
      maxBenefitAmount: 10000,
      priority: 1,
      createdAt: DateTime.now(),
    ),
    CardTierRule(
      id: 'demo-rule-002',
      tierId: 'demo-tier-001',
      category: '교통',
      benefitType: 'cashback',
      benefitRate: 10.0,
      maxBenefitAmount: 10000,
      priority: 2,
      createdAt: DateTime.now(),
    ),
    CardTierRule(
      id: 'demo-rule-003',
      tierId: 'demo-tier-001',
      category: '편의점',
      benefitType: 'cashback',
      benefitRate: 10.0,
      maxBenefitAmount: 5000,
      priority: 3,
      createdAt: DateTime.now(),
    ),
  ];

  // ── Tier 규칙 (KB My WE:SH - Tier 1: 30만 이상) ──
  static final List<CardTierRule> _card2Tier1Rules = [
    CardTierRule(
      id: 'demo-rule-004',
      tierId: 'demo-tier-002',
      category: '쇼핑',
      benefitType: 'point',
      benefitRate: 3.0,
      maxBenefitAmount: 10000,
      priority: 1,
      createdAt: DateTime.now(),
    ),
    CardTierRule(
      id: 'demo-rule-005',
      tierId: 'demo-tier-002',
      category: '마트',
      benefitType: 'cashback',
      benefitRate: 3.0,
      maxBenefitAmount: 8000,
      priority: 2,
      createdAt: DateTime.now(),
    ),
  ];

  // ── Tier 규칙 (KB My WE:SH - Tier 2: 50만 이상) ──
  static final List<CardTierRule> _card2Tier2Rules = [
    CardTierRule(
      id: 'demo-rule-006',
      tierId: 'demo-tier-003',
      category: '쇼핑',
      benefitType: 'point',
      benefitRate: 5.0,
      maxBenefitAmount: 15000,
      priority: 1,
      createdAt: DateTime.now(),
    ),
    CardTierRule(
      id: 'demo-rule-007',
      tierId: 'demo-tier-003',
      category: '마트',
      benefitType: 'cashback',
      benefitRate: 5.0,
      maxBenefitAmount: 10000,
      priority: 2,
      createdAt: DateTime.now(),
    ),
  ];

  // ── Tier 정보 ──
  static final List<CardBenefitTier> card1Tiers = [
    CardBenefitTier(
      id: 'demo-tier-001',
      cardId: 'demo-card-001',
      tierName: '30만원 이상',
      minPrevSpend: 300000,
      maxPrevSpend: null,
      tierOrder: 1,
      createdAt: DateTime.now(),
      rules: _card1TierRules,
    ),
  ];

  static final List<CardBenefitTier> card2Tiers = [
    CardBenefitTier(
      id: 'demo-tier-002',
      cardId: 'demo-card-002',
      tierName: '30만원 이상',
      minPrevSpend: 300000,
      maxPrevSpend: 499999,
      tierOrder: 1,
      createdAt: DateTime.now(),
      rules: _card2Tier1Rules,
    ),
    CardBenefitTier(
      id: 'demo-tier-003',
      cardId: 'demo-card-002',
      tierName: '50만원 이상',
      minPrevSpend: 500000,
      maxPrevSpend: null,
      tierOrder: 2,
      createdAt: DateTime.now(),
      rules: _card2Tier2Rules,
    ),
  ];

  static Map<String, List<CardBenefitTier>> get tiersByCardId => {
    'demo-card-001': card1Tiers,
    'demo-card-002': card2Tiers,
    'demo-card-003': [], // 삼성 taptap O는 Tier 없이 기본 혜택만
  };

  // ── 사용자 카드 ──
  static final List<UserCard> userCards = [
    UserCard(
      id: 'demo-uc-001',
      userId: _guestUserId,
      cardMasterId: 'demo-card-001',
      nickname: '월급카드',
      createdAt: DateTime.now(),
      cardMaster: cards[0],
    ),
    UserCard(
      id: 'demo-uc-002',
      userId: _guestUserId,
      cardMasterId: 'demo-card-002',
      nickname: '생활비카드',
      createdAt: DateTime.now(),
      cardMaster: cards[1],
    ),
  ];

  // ── 데모 소비 내역 (이번 달) ──
  static List<Transaction> get transactions {
    final now = DateTime.now();
    return [
      Transaction(
        id: 'demo-tx-001',
        userId: _guestUserId,
        userCardId: 'demo-uc-001',
        amount: 45000,
        category: '외식',
        memo: '팀 점심 회식',
        transactionDate: DateTime(now.year, now.month, now.day - 1),
        createdAt: DateTime.now(),
      ),
      Transaction(
        id: 'demo-tx-002',
        userId: _guestUserId,
        userCardId: 'demo-uc-001',
        amount: 62000,
        category: '교통',
        memo: '이번 달 교통비',
        transactionDate: DateTime(now.year, now.month, now.day - 3),
        createdAt: DateTime.now(),
      ),
      Transaction(
        id: 'demo-tx-003',
        userId: _guestUserId,
        userCardId: 'demo-uc-001',
        amount: 15000,
        category: '편의점',
        memo: '',
        transactionDate: DateTime(now.year, now.month, now.day - 5),
        createdAt: DateTime.now(),
      ),
      Transaction(
        id: 'demo-tx-004',
        userId: _guestUserId,
        userCardId: 'demo-uc-001',
        amount: 120000,
        category: '외식',
        memo: '가족 외식',
        transactionDate: DateTime(now.year, now.month, now.day - 7),
        createdAt: DateTime.now(),
      ),
      Transaction(
        id: 'demo-tx-005',
        userId: _guestUserId,
        userCardId: 'demo-uc-002',
        amount: 89000,
        category: '쇼핑',
        memo: '봄 옷 구매',
        transactionDate: DateTime(now.year, now.month, now.day - 2),
        createdAt: DateTime.now(),
      ),
      Transaction(
        id: 'demo-tx-006',
        userId: _guestUserId,
        userCardId: 'demo-uc-002',
        amount: 156000,
        category: '마트',
        memo: '주간 장보기',
        transactionDate: DateTime(now.year, now.month, now.day - 4),
        createdAt: DateTime.now(),
      ),
      Transaction(
        id: 'demo-tx-007',
        userId: _guestUserId,
        userCardId: 'demo-uc-002',
        amount: 210000,
        category: '쇼핑',
        memo: '생활용품',
        transactionDate: DateTime(now.year, now.month, now.day - 8),
        createdAt: DateTime.now(),
      ),
    ];
  }

  // ── 데모 혜택 계산 결과 (Tier 기반) ──
  static List<BenefitResult> get benefitResults {
    // 카드1: 신한 Deep Dream (당월 242,000원 / Tier 기준 300,000원)
    // → 전월 데이터 없음, 당월 누적으로 판단 → 미달 → 혜택 0원
    // → 기본 혜택 0.5% 적용: 242,000 × 0.5% = 1,210원
    final card1Spend = 45000 + 62000 + 15000 + 120000; // 242,000
    final card1Remaining = 300000 - card1Spend; // 58,000
    final card1BaseBenefit = (card1Spend * 0.5 / 100).round(); // 1,210

    // 카드2: KB My WE:SH (당월 455,000원)
    // → 전월 데이터 없음, 당월 455,000원 기준
    // → Tier 1 (30만~50만) 해당 → 쇼핑 3%, 마트 3%
    final card2Spend = 89000 + 156000 + 210000; // 455,000
    // 쇼핑 카테고리: 89,000 + 210,000 = 299,000원 × 3% = 8,970원
    final shoppingBenefit = (299000 * 3.0 / 100).round(); // 8,970
    // 마트 카테고리: 156,000원 × 3% = 4,680원
    final martBenefit = (156000 * 3.0 / 100).round(); // 4,680
    final card2TierBenefit = shoppingBenefit + martBenefit; // 13,650
    final card2BaseBenefit = (card2Spend * 0.3 / 100).round(); // 1,365
    final card2TotalBenefit = card2TierBenefit + card2BaseBenefit; // 15,015

    return [
      BenefitResult(
        userCard: userCards[0],
        cardMaster: cards[0],
        totalSpend: card1Spend,
        prevMonthSpend: 0,
        minMonthlySpend: 300000,
        remainingForBenefit: card1Remaining,
        currentBenefitRate: 0.5, // 기본 혜택률만
        estimatedBenefit: card1BaseBenefit,
        maxBenefit: 25000,
        progress: card1Spend / 300000,
        ruleDetails: [],
        activeTier: null, // Tier 미달
        nextTier: card1Tiers[0],
        remainingForNextTier: card1Remaining,
        monthlyBenefitCap: 25000,
        baseBenefit: card1BaseBenefit,
        allTiers: card1Tiers,
      ),
      BenefitResult(
        userCard: userCards[1],
        cardMaster: cards[1],
        totalSpend: card2Spend,
        prevMonthSpend: 0,
        minMonthlySpend: 300000,
        remainingForBenefit: 0,
        currentBenefitRate: 3.3, // 가중평균: 15,015 / 455,000 * 100
        estimatedBenefit: card2TotalBenefit,
        maxBenefit: 25000,
        progress: 1.0,
        ruleDetails: [
          RuleBenefitDetail(
            rule: _card2Tier1Rules[0],
            categorySpend: 299000,
            appliedRate: 3.0,
            calculatedBenefit: shoppingBenefit,
            remaining: 0,
            maxBenefitForRule: 10000,
          ),
          RuleBenefitDetail(
            rule: _card2Tier1Rules[1],
            categorySpend: 156000,
            appliedRate: 3.0,
            calculatedBenefit: martBenefit,
            remaining: 0,
            maxBenefitForRule: 8000,
          ),
        ],
        activeTier: card2Tiers[0], // Tier 1 활성
        nextTier: card2Tiers[1], // 다음: Tier 2 (50만 이상)
        remainingForNextTier: 500000 - card2Spend, // 45,000
        monthlyBenefitCap: 25000,
        baseBenefit: card2BaseBenefit,
        allTiers: card2Tiers,
      ),
    ];
  }
}
