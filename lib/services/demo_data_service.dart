import '../models/card_master.dart';
import '../models/card_benefit_rule.dart';
import '../models/user_card.dart';
import '../models/transaction.dart';
import 'benefit_engine.dart';

/// 비회원 모드용 데모 데이터
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
      imageColor: '#2563EB',
      createdAt: DateTime.now(),
    ),
    CardMaster(
      id: 'demo-card-002',
      cardName: 'KB 국민 My WE:SH',
      issuer: 'KB국민카드',
      annualFee: 15000,
      imageColor: '#DC2626',
      createdAt: DateTime.now(),
    ),
    CardMaster(
      id: 'demo-card-003',
      cardName: '삼성 taptap O',
      issuer: '삼성카드',
      annualFee: 10000,
      imageColor: '#7C3AED',
      createdAt: DateTime.now(),
    ),
  ];

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

  // ── 혜택 규칙 ──
  static final List<CardBenefitRule> benefitRules = [
    // 신한 Deep Dream
    CardBenefitRule(
      id: 'demo-rule-001',
      cardId: 'demo-card-001',
      category: '외식',
      minMonthlySpend: 300000,
      benefitType: 'cashback',
      benefitRate: 10.0,
      maxBenefitAmount: 10000,
      startDay: 1,
      endDay: 31,
      priority: 1,
      createdAt: DateTime.now(),
    ),
    CardBenefitRule(
      id: 'demo-rule-002',
      cardId: 'demo-card-001',
      category: '교통',
      minMonthlySpend: 300000,
      benefitType: 'cashback',
      benefitRate: 10.0,
      maxBenefitAmount: 10000,
      startDay: 1,
      endDay: 31,
      priority: 2,
      createdAt: DateTime.now(),
    ),
    CardBenefitRule(
      id: 'demo-rule-003',
      cardId: 'demo-card-001',
      category: '편의점',
      minMonthlySpend: 300000,
      benefitType: 'cashback',
      benefitRate: 10.0,
      maxBenefitAmount: 5000,
      startDay: 1,
      endDay: 31,
      priority: 3,
      createdAt: DateTime.now(),
    ),
    // KB My WE:SH
    CardBenefitRule(
      id: 'demo-rule-004',
      cardId: 'demo-card-002',
      category: '쇼핑',
      minMonthlySpend: 400000,
      benefitType: 'point',
      benefitRate: 5.0,
      maxBenefitAmount: 15000,
      startDay: 1,
      endDay: 31,
      priority: 1,
      createdAt: DateTime.now(),
    ),
    CardBenefitRule(
      id: 'demo-rule-005',
      cardId: 'demo-card-002',
      category: '마트',
      minMonthlySpend: 400000,
      benefitType: 'cashback',
      benefitRate: 5.0,
      maxBenefitAmount: 10000,
      startDay: 1,
      endDay: 31,
      priority: 2,
      createdAt: DateTime.now(),
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

  // ── 데모 혜택 계산 결과 ──
  static List<BenefitResult> get benefitResults {
    // 카드1: 신한 Deep Dream (총 242,000원 / 기준 300,000원)
    final card1Spend = 45000 + 62000 + 15000 + 120000; // 242,000
    final card1Remaining = 300000 - card1Spend; // 58,000

    // 카드2: KB My WE:SH (총 455,000원 / 기준 400,000원) → 혜택 활성!
    final card2Spend = 89000 + 156000 + 210000; // 455,000

    return [
      BenefitResult(
        userCard: userCards[0],
        totalSpend: card1Spend,
        minMonthlySpend: 300000,
        remainingForBenefit: card1Remaining,
        currentBenefitRate: 0,
        estimatedBenefit: 0,
        maxBenefit: 25000,
        progress: card1Spend / 300000,
        ruleDetails: [
          RuleBenefitDetail(
            rule: benefitRules[0],
            categorySpend: 165000,
            appliedRate: 0,
            calculatedBenefit: 0,
            remaining: card1Remaining,
          ),
          RuleBenefitDetail(
            rule: benefitRules[1],
            categorySpend: 62000,
            appliedRate: 0,
            calculatedBenefit: 0,
            remaining: card1Remaining,
          ),
          RuleBenefitDetail(
            rule: benefitRules[2],
            categorySpend: 15000,
            appliedRate: 0,
            calculatedBenefit: 0,
            remaining: card1Remaining,
          ),
        ],
      ),
      BenefitResult(
        userCard: userCards[1],
        totalSpend: card2Spend,
        minMonthlySpend: 400000,
        remainingForBenefit: 0,
        currentBenefitRate: 5.0,
        estimatedBenefit: 22700,
        maxBenefit: 25000,
        progress: 1.0,
        ruleDetails: [
          RuleBenefitDetail(
            rule: benefitRules[3],
            categorySpend: 299000,
            appliedRate: 5.0,
            calculatedBenefit: 14950,
            remaining: 0,
          ),
          RuleBenefitDetail(
            rule: benefitRules[4],
            categorySpend: 156000,
            appliedRate: 5.0,
            calculatedBenefit: 7800,
            remaining: 0,
          ),
        ],
      ),
    ];
  }
}
