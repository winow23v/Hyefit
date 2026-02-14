import '../models/card_benefit_tier.dart';
import '../models/card_tier_rule.dart';
import '../models/card_master.dart';
import '../models/transaction.dart';
import '../models/user_card.dart';
import 'card_service.dart';
import 'transaction_service.dart';

/// 카드별 혜택 계산 결과 (Tier 기반)
class BenefitResult {
  final UserCard userCard;
  final CardMaster cardMaster;
  final int totalSpend; // 당월 총 소비액
  final int prevMonthSpend; // 전월 실적
  final int minMonthlySpend; // 현재 Tier 최소 실적 (호환용)
  final int remainingForBenefit; // 혜택까지 남은 금액 (호환용)
  final double currentBenefitRate; // 대표 혜택률
  final int estimatedBenefit; // 예상 혜택 금액
  final int maxBenefit; // 최대 혜택 (각 규칙별 합계)
  final double progress; // 0.0 ~ 1.0 (호환용)
  final List<RuleBenefitDetail> ruleDetails;

  // Tier 기반 추가 필드
  final CardBenefitTier? activeTier; // 현재 활성 Tier
  final CardBenefitTier? nextTier; // 다음 Tier
  final int? remainingForNextTier; // 다음 Tier까지 남은 실적
  final int monthlyBenefitCap; // 월 최대 혜택 한도
  final int baseBenefit; // 기본 혜택 (전 가맹점)
  final List<CardBenefitTier> allTiers; // 모든 Tier 정보

  const BenefitResult({
    required this.userCard,
    required this.cardMaster,
    required this.totalSpend,
    required this.prevMonthSpend,
    required this.minMonthlySpend,
    required this.remainingForBenefit,
    required this.currentBenefitRate,
    required this.estimatedBenefit,
    required this.maxBenefit,
    required this.progress,
    required this.ruleDetails,
    this.activeTier,
    this.nextTier,
    this.remainingForNextTier,
    this.monthlyBenefitCap = 0,
    this.baseBenefit = 0,
    this.allTiers = const [],
  });

  bool get isBenefitActive => activeTier != null;

  /// 월 한도 대비 사용률
  double get capUsageRate {
    if (monthlyBenefitCap <= 0) return 0;
    return (estimatedBenefit / monthlyBenefitCap).clamp(0.0, 1.0);
  }

  /// 남은 월 한도
  int get remainingCap {
    if (monthlyBenefitCap <= 0) return 0;
    return (monthlyBenefitCap - estimatedBenefit).clamp(0, monthlyBenefitCap);
  }
}

class RuleBenefitDetail {
  final CardTierRule rule;
  final int categorySpend;
  final double appliedRate;
  final int calculatedBenefit;
  final int remaining;
  final int maxBenefitForRule;

  const RuleBenefitDetail({
    required this.rule,
    required this.categorySpend,
    required this.appliedRate,
    required this.calculatedBenefit,
    required this.remaining,
    required this.maxBenefitForRule,
  });

  /// 규칙 한도 사용률
  double get ruleUsageRate {
    if (maxBenefitForRule <= 0) return 0;
    return (calculatedBenefit / maxBenefitForRule).clamp(0.0, 1.0);
  }
}

/// 혜택 계산 엔진 — Tier 기반 PRD 핵심 로직
class BenefitEngine {
  final CardService _cardService;
  final TransactionService _transactionService;

  BenefitEngine({
    required CardService cardService,
    required TransactionService transactionService,
  }) : _cardService = cardService,
       _transactionService = transactionService;

  /// 현재 공여기간의 시작/끝 날짜
  (DateTime, DateTime) getCurrentPeriod() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return (start, end);
  }

  /// 전월 공여기간의 시작/끝 날짜
  (DateTime, DateTime) getPreviousPeriod() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 1, 1);
    final end = DateTime(now.year, now.month, 0);
    return (start, end);
  }

  /// 단일 카드에 대한 혜택 계산 (Tier 기반)
  Future<BenefitResult> calculateForCard({
    required String userId,
    required UserCard userCard,
  }) async {
    final (periodStart, periodEnd) = getCurrentPeriod();
    final (prevStart, prevEnd) = getPreviousPeriod();

    // 1. 카드 마스터 정보 조회
    final cardMaster = await _cardService.getCard(userCard.cardMasterId);

    // 2. 이 카드의 모든 Tier 조회 (nested join으로 규칙 포함)
    final tiers = await _cardService.getBenefitTiers(userCard.cardMasterId);

    // 3. 전월/당월 거래 내역 조회 후 메모리 집계
    final previousPeriodTransactions = await _transactionService
        .getTransactionsByCard(
          userId: userId,
          userCardId: userCard.id,
          from: prevStart,
          to: prevEnd,
        );
    final currentPeriodTransactions = await _transactionService
        .getTransactionsByCard(
          userId: userId,
          userCardId: userCard.id,
          from: periodStart,
          to: periodEnd,
        );
    final prevMonthSpend = _sumTransactionAmounts(previousPeriodTransactions);
    final currentMonthSpend = _sumTransactionAmounts(currentPeriodTransactions);
    final categorySpendMap = _buildCategorySpendMap(currentPeriodTransactions);

    // Tier가 없으면 기본 혜택만 적용
    if (tiers.isEmpty) {
      final baseBenefit = cardMaster.baseBenefitRate > 0
          ? (currentMonthSpend * cardMaster.baseBenefitRate / 100).round()
          : 0;
      final cappedBaseBenefit = cardMaster.monthlyBenefitCap > 0
          ? baseBenefit.clamp(0, cardMaster.monthlyBenefitCap)
          : baseBenefit;
      final maxBenefit = cardMaster.monthlyBenefitCap > 0
          ? cardMaster.monthlyBenefitCap
          : cappedBaseBenefit;

      return BenefitResult(
        userCard: userCard,
        cardMaster: cardMaster,
        totalSpend: currentMonthSpend,
        prevMonthSpend: prevMonthSpend,
        minMonthlySpend: 0,
        remainingForBenefit: 0,
        currentBenefitRate: cardMaster.baseBenefitRate,
        estimatedBenefit: cappedBaseBenefit,
        maxBenefit: maxBenefit,
        progress: 1.0,
        ruleDetails: [],
        monthlyBenefitCap: cardMaster.monthlyBenefitCap,
        baseBenefit: cappedBaseBenefit,
        allTiers: [],
      );
    }

    // 5. Tier 판정
    // 1) 전월 실적 우선
    // 2) 전월 미충족 시 당월 실적 즉시 적용 기준도 허용
    final activeTierByPrev = _cardService.findMatchingTier(
      tiers: tiers,
      prevMonthSpend: prevMonthSpend,
    );
    final activeTierByCurrent = _cardService.findMatchingTier(
      tiers: tiers,
      prevMonthSpend: currentMonthSpend,
    );
    final activeTier = activeTierByPrev ?? activeTierByCurrent;
    final tierReferenceSpend = activeTierByPrev != null
        ? prevMonthSpend
        : currentMonthSpend;

    // 6. 다음 Tier 정보
    final sortedTiers = List<CardBenefitTier>.from(tiers)
      ..sort((a, b) => a.tierOrder.compareTo(b.tierOrder));
    final nextTier = activeTier != null
        ? _cardService.findNextTier(tiers: tiers, currentTier: activeTier)
        : sortedTiers.isNotEmpty
        ? sortedTiers.first
        : null;

    // 7. 다음 Tier까지 남은 실적
    int? remainingForNextTier;
    if (nextTier != null) {
      remainingForNextTier = nextTier.minPrevSpend - tierReferenceSpend;
      if (remainingForNextTier < 0) remainingForNextTier = 0;
    }

    // 8. 현재 Tier 최소 실적 및 남은 금액 계산
    final minMonthlySpend =
        activeTier?.minPrevSpend ?? nextTier?.minPrevSpend ?? 0;

    // remainingForBenefit:
    // - activeTier가 있으면 다음 Tier까지 남은 당월 사용액
    // - activeTier가 없으면 다음 달 혜택 진입을 위한 당월 사용액 기준
    int remaining;
    if (activeTier != null && nextTier != null) {
      // 혜택 받는 중 → 상위 Tier까지 당월 기준으로 계산
      final nextTierMinSpend = nextTier.minPrevSpend;
      remaining = nextTierMinSpend > tierReferenceSpend
          ? nextTierMinSpend - tierReferenceSpend
          : 0;
    } else {
      // 혜택 미활성 → 이번 달 사용액이 다음 달 혜택 조건을 얼마나 채웠는지
      remaining = minMonthlySpend > 0 && currentMonthSpend < minMonthlySpend
          ? minMonthlySpend - currentMonthSpend
          : 0;
    }

    // 9. 각 규칙별 혜택 계산
    final List<RuleBenefitDetail> ruleDetails = [];
    int totalBenefit = 0;
    int totalMaxBenefit = 0;

    if (activeTier != null) {
      final specificCategories = activeTier.rules
          .map((rule) => rule.category.trim().toLowerCase())
          .where((category) => !_isGeneralCategory(category))
          .toSet();
      final generalCategorySpend = categorySpendMap.entries
          .where(
            (entry) =>
                !specificCategories.contains(entry.key.trim().toLowerCase()),
          )
          .fold(0, (sum, entry) => sum + entry.value);
      var generalCategoryApplied = false;

      for (final rule in activeTier.rules) {
        // 카테고리별 당월 소비액
        // - 일반 카테고리(기타/전체)는 명시 카테고리를 제외한 잔여 사용액으로 계산
        final isGeneralCategory = _isGeneralCategory(rule.category);
        int categorySpend;
        if (isGeneralCategory) {
          categorySpend = generalCategoryApplied ? 0 : generalCategorySpend;
          generalCategoryApplied = true;
        } else {
          categorySpend = categorySpendMap[rule.category] ?? 0;
        }

        // 혜택 금액 계산
        int benefit = 0;
        if (categorySpend > 0) {
          benefit = (categorySpend * rule.benefitRate / 100).round();
          if (benefit > rule.maxBenefitAmount && rule.maxBenefitAmount > 0) {
            benefit = rule.maxBenefitAmount;
          }
        }

        totalBenefit += benefit;
        totalMaxBenefit += rule.maxBenefitAmount;

        ruleDetails.add(
          RuleBenefitDetail(
            rule: rule,
            categorySpend: categorySpend,
            appliedRate: rule.benefitRate,
            calculatedBenefit: benefit,
            remaining: 0,
            maxBenefitForRule: rule.maxBenefitAmount,
          ),
        );
      }
    }

    // 10. 기본 혜택 계산 (전 가맹점)
    int baseBenefit = 0;
    if (cardMaster.baseBenefitRate > 0) {
      baseBenefit = (currentMonthSpend * cardMaster.baseBenefitRate / 100)
          .round();
    }

    // 11. 총 혜택 (Tier 혜택 + 기본 혜택)
    int combinedBenefit = totalBenefit + baseBenefit;

    // 12. 월 한도 적용
    if (cardMaster.monthlyBenefitCap > 0 &&
        combinedBenefit > cardMaster.monthlyBenefitCap) {
      combinedBenefit = cardMaster.monthlyBenefitCap;
    }

    final hasUnlimitedRule =
        activeTier?.rules.any((rule) => rule.maxBenefitAmount <= 0) ?? false;
    final uncappedMaxBenefit = hasUnlimitedRule
        ? combinedBenefit
        : totalMaxBenefit + baseBenefit;
    final maxBenefit = cardMaster.monthlyBenefitCap > 0
        ? cardMaster.monthlyBenefitCap
        : uncappedMaxBenefit;

    // 13. 진행률 계산 (전월 실적 기준)
    double progress = 0;
    if (minMonthlySpend > 0) {
      progress = (tierReferenceSpend / minMonthlySpend).clamp(0.0, 1.0);
    } else if (activeTier != null) {
      progress = 1.0; // Tier가 있고 최소 실적이 0이면 100%
    }

    // 14. 대표 혜택률 계산
    double representativeRate = 0;
    if (ruleDetails.isNotEmpty) {
      final totalCatSpend = ruleDetails.fold(
        0,
        (sum, d) => sum + d.categorySpend,
      );
      if (totalCatSpend > 0) {
        representativeRate = totalBenefit / totalCatSpend * 100;
      } else if (activeTier != null && activeTier.rules.isNotEmpty) {
        representativeRate = activeTier.rules.first.benefitRate;
      }
    } else if (cardMaster.baseBenefitRate > 0) {
      representativeRate = cardMaster.baseBenefitRate;
    }

    return BenefitResult(
      userCard: userCard,
      cardMaster: cardMaster,
      totalSpend: currentMonthSpend,
      prevMonthSpend: prevMonthSpend,
      minMonthlySpend: minMonthlySpend,
      remainingForBenefit: remaining.clamp(0, minMonthlySpend),
      currentBenefitRate: representativeRate,
      estimatedBenefit: combinedBenefit,
      maxBenefit: maxBenefit,
      progress: progress,
      ruleDetails: ruleDetails,
      activeTier: activeTier,
      nextTier: nextTier,
      remainingForNextTier: remainingForNextTier,
      monthlyBenefitCap: cardMaster.monthlyBenefitCap,
      baseBenefit: baseBenefit,
      allTiers: tiers,
    );
  }

  static int _sumTransactionAmounts(List<Transaction> transactions) {
    return transactions.fold(0, (sum, tx) => sum + tx.amount);
  }

  static Map<String, int> _buildCategorySpendMap(
    List<Transaction> transactions,
  ) {
    final result = <String, int>{};
    for (final tx in transactions) {
      result[tx.category] = (result[tx.category] ?? 0) + tx.amount;
    }
    return result;
  }

  static bool _isGeneralCategory(String category) {
    final key = category.trim().toLowerCase();
    return key == '기타' || key == '전체' || key == 'all' || key == 'general';
  }

  /// 모든 사용자 카드에 대한 혜택 계산
  Future<List<BenefitResult>> calculateAll({
    required String userId,
    required List<UserCard> userCards,
  }) async {
    final results = <BenefitResult>[];
    for (final card in userCards) {
      final result = await calculateForCard(userId: userId, userCard: card);
      results.add(result);
    }
    return results;
  }

  /// 오늘 추천 카드 (혜택까지 가장 가까운 카드)
  BenefitResult? getRecommendedCard(List<BenefitResult> results) {
    if (results.isEmpty) return null;

    // 사용 이력이 있는 카드가 있다면 미사용(0원) 카드는 추천 우선순위에서 뒤로 보냄
    final cardsWithSpend = results.where((r) => r.totalSpend > 0).toList();
    final candidates = cardsWithSpend.isNotEmpty ? cardsWithSpend : results;

    // 1순위: 실제 예상 혜택이 발생하는 활성 카드
    final activeCards = candidates
        .where((r) => r.isBenefitActive && r.estimatedBenefit > 0)
        .toList();
    if (activeCards.isNotEmpty) {
      activeCards.sort(_compareActiveRecommendation);
      return activeCards.first;
    }

    // 2순위: 잠재 혜택 금액(혜택률+소비액+도달거리) 기준
    final sorted = List<BenefitResult>.from(candidates);
    sorted.sort(_comparePotentialRecommendation);
    return sorted.first;
  }

  static int _compareActiveRecommendation(BenefitResult a, BenefitResult b) {
    final aHasBenefit = a.estimatedBenefit > 0;
    final bHasBenefit = b.estimatedBenefit > 0;
    if (aHasBenefit != bHasBenefit) {
      return bHasBenefit ? 1 : -1;
    }

    var compare = b.estimatedBenefit.compareTo(a.estimatedBenefit);
    if (compare != 0) return compare;

    compare = b.totalSpend.compareTo(a.totalSpend);
    if (compare != 0) return compare;

    compare = b.currentBenefitRate.compareTo(a.currentBenefitRate);
    if (compare != 0) return compare;

    final aRemainForNext = a.remainingForNextTier ?? 1 << 30;
    final bRemainForNext = b.remainingForNextTier ?? 1 << 30;
    return aRemainForNext.compareTo(bRemainForNext);
  }

  static int _comparePotentialRecommendation(BenefitResult a, BenefitResult b) {
    var compare = _potentialBenefitAmount(
      b,
    ).compareTo(_potentialBenefitAmount(a));
    if (compare != 0) return compare;

    compare = a.remainingForBenefit.compareTo(b.remainingForBenefit);
    if (compare != 0) return compare;

    compare = b.totalSpend.compareTo(a.totalSpend);
    if (compare != 0) return compare;

    compare = b.currentBenefitRate.compareTo(a.currentBenefitRate);
    if (compare != 0) return compare;

    return b.estimatedBenefit.compareTo(a.estimatedBenefit);
  }

  static int _potentialBenefitAmount(BenefitResult result) {
    if (result.estimatedBenefit > 0) return result.estimatedBenefit;
    if (result.totalSpend <= 0) return 0;

    final tier = result.activeTier ?? result.nextTier;
    double maxRuleRate = 0;
    if (tier != null && tier.rules.isNotEmpty) {
      maxRuleRate = tier.rules
          .map((rule) => rule.benefitRate)
          .reduce((a, b) => a > b ? a : b);
    }

    var effectiveRate = result.currentBenefitRate;
    if (result.cardMaster.baseBenefitRate > effectiveRate) {
      effectiveRate = result.cardMaster.baseBenefitRate;
    }
    if (maxRuleRate > effectiveRate) {
      effectiveRate = maxRuleRate;
    }

    if (effectiveRate <= 0) return 0;
    final grossPotential = (result.totalSpend * effectiveRate / 100).round();

    // 목표 실적까지 남은 금액이 크면 잠재 혜택 점수를 보정
    if (result.remainingForBenefit <= 0) return grossPotential;
    final readiness = 1.0 / (1.0 + (result.remainingForBenefit / 100000.0));
    return (grossPotential * readiness).round();
  }

  /// 이번 달 총 절약 금액
  int getTotalSavings(List<BenefitResult> results) {
    return results.fold(0, (sum, r) => sum + r.estimatedBenefit);
  }

  /// 카테고리별 최적 카드 추천
  BenefitResult? getBestCardForCategory({
    required List<BenefitResult> results,
    required String category,
  }) {
    if (results.isEmpty) return null;

    // 해당 카테고리에서 가장 높은 혜택률을 가진 카드
    BenefitResult? bestCard;
    double bestRate = 0;

    for (final result in results) {
      if (!result.isBenefitActive) continue;

      for (final detail in result.ruleDetails) {
        if (detail.rule.category == category && detail.appliedRate > bestRate) {
          bestRate = detail.appliedRate;
          bestCard = result;
        }
      }
    }

    return bestCard;
  }
}
