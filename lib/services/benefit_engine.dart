import '../models/card_benefit_rule.dart';
import '../models/user_card.dart';
import 'card_service.dart';
import 'transaction_service.dart';

/// 카드별 혜택 계산 결과
class BenefitResult {
  final UserCard userCard;
  final int totalSpend;
  final int minMonthlySpend;
  final int remainingForBenefit;
  final double currentBenefitRate;
  final int estimatedBenefit;
  final int maxBenefit;
  final double progress; // 0.0 ~ 1.0
  final List<RuleBenefitDetail> ruleDetails;

  const BenefitResult({
    required this.userCard,
    required this.totalSpend,
    required this.minMonthlySpend,
    required this.remainingForBenefit,
    required this.currentBenefitRate,
    required this.estimatedBenefit,
    required this.maxBenefit,
    required this.progress,
    required this.ruleDetails,
  });

  bool get isBenefitActive => totalSpend >= minMonthlySpend;
}

class RuleBenefitDetail {
  final CardBenefitRule rule;
  final int categorySpend;
  final double appliedRate;
  final int calculatedBenefit;
  final int remaining;

  const RuleBenefitDetail({
    required this.rule,
    required this.categorySpend,
    required this.appliedRate,
    required this.calculatedBenefit,
    required this.remaining,
  });
}

/// 혜택 계산 엔진 — PRD 핵심 로직
class BenefitEngine {
  final CardService _cardService;
  final TransactionService _transactionService;

  BenefitEngine({
    required CardService cardService,
    required TransactionService transactionService,
  })  : _cardService = cardService,
        _transactionService = transactionService;

  /// 현재 공여기간의 시작/끝 날짜
  (DateTime, DateTime) getCurrentPeriod() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return (start, end);
  }

  /// 단일 카드에 대한 혜택 계산
  Future<BenefitResult> calculateForCard({
    required String userId,
    required UserCard userCard,
  }) async {
    final (periodStart, periodEnd) = getCurrentPeriod();

    // 1. 이 카드의 혜택 규칙 조회
    final rules = await _cardService.getBenefitRules(
      userCard.cardMasterId,
    );

    if (rules.isEmpty) {
      return BenefitResult(
        userCard: userCard,
        totalSpend: 0,
        minMonthlySpend: 0,
        remainingForBenefit: 0,
        currentBenefitRate: 0,
        estimatedBenefit: 0,
        maxBenefit: 0,
        progress: 0,
        ruleDetails: [],
      );
    }

    // 2. 전월 실적 기준 (가장 높은 기준)
    final minMonthlySpend =
        rules.map((r) => r.minMonthlySpend).reduce((a, b) => a > b ? a : b);

    // 3. 총 소비액 조회
    final totalSpend = await _transactionService.getMonthlySpend(
      userId: userId,
      userCardId: userCard.id,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );

    // 4. 혜택 활성 여부
    final isActive = totalSpend >= minMonthlySpend;
    final remaining =
        isActive ? 0 : minMonthlySpend - totalSpend;

    // 5. 각 규칙별 혜택 계산
    final List<RuleBenefitDetail> ruleDetails = [];
    int totalBenefit = 0;
    int totalMaxBenefit = 0;

    for (final rule in rules) {
      // 카테고리별 소비액
      final categorySpend =
          await _transactionService.getMonthlyCategorySpend(
        userId: userId,
        userCardId: userCard.id,
        category: rule.category,
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      // 구간별 혜택률 조회
      final thresholds =
          await _cardService.getThresholds(rule.id);

      double appliedRate = rule.benefitRate;

      // threshold가 있으면 매칭
      if (thresholds.isNotEmpty && isActive) {
        for (final t in thresholds) {
          if (totalSpend >= t.minSpendAmount) {
            if (t.maxSpendAmount == null ||
                totalSpend <= t.maxSpendAmount!) {
              appliedRate = t.benefitRate;
            }
          }
        }
      }

      // 혜택 금액 계산
      int benefit = 0;
      if (isActive) {
        benefit = (categorySpend * appliedRate / 100).round();
        if (benefit > rule.maxBenefitAmount) {
          benefit = rule.maxBenefitAmount;
        }
      }

      totalBenefit += benefit;
      totalMaxBenefit += rule.maxBenefitAmount;

      ruleDetails.add(RuleBenefitDetail(
        rule: rule,
        categorySpend: categorySpend,
        appliedRate: isActive ? appliedRate : 0,
        calculatedBenefit: benefit,
        remaining: isActive
            ? 0
            : minMonthlySpend - totalSpend,
      ));
    }

    // 6. 진행률 계산
    double progress = minMonthlySpend > 0
        ? (totalSpend / minMonthlySpend).clamp(0.0, 1.0)
        : 0.0;

    return BenefitResult(
      userCard: userCard,
      totalSpend: totalSpend,
      minMonthlySpend: minMonthlySpend,
      remainingForBenefit: remaining,
      currentBenefitRate: ruleDetails.isNotEmpty
          ? ruleDetails.first.appliedRate
          : 0,
      estimatedBenefit: totalBenefit,
      maxBenefit: totalMaxBenefit,
      progress: progress,
      ruleDetails: ruleDetails,
    );
  }

  /// 모든 사용자 카드에 대한 혜택 계산
  Future<List<BenefitResult>> calculateAll({
    required String userId,
    required List<UserCard> userCards,
  }) async {
    final results = <BenefitResult>[];
    for (final card in userCards) {
      final result = await calculateForCard(
        userId: userId,
        userCard: card,
      );
      results.add(result);
    }
    return results;
  }

  /// 오늘 추천 카드 (혜택까지 가장 가까운 카드)
  BenefitResult? getRecommendedCard(List<BenefitResult> results) {
    if (results.isEmpty) return null;

    // 1순위: 혜택 활성 중 예상 혜택 가장 큰 카드
    final activeCards =
        results.where((r) => r.isBenefitActive).toList();
    if (activeCards.isNotEmpty) {
      activeCards.sort(
          (a, b) => b.estimatedBenefit.compareTo(a.estimatedBenefit));
      return activeCards.first;
    }

    // 2순위: 혜택까지 남은 금액이 가장 적은 카드
    final sorted = List<BenefitResult>.from(results);
    sorted.sort(
        (a, b) => a.remainingForBenefit.compareTo(b.remainingForBenefit));
    return sorted.first;
  }

  /// 이번 달 총 절약 금액
  int getTotalSavings(List<BenefitResult> results) {
    return results.fold(0, (sum, r) => sum + r.estimatedBenefit);
  }
}
