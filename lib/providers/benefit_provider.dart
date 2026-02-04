import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/benefit_engine.dart';
import '../services/demo_data_service.dart';
import 'card_provider.dart';
import 'transaction_provider.dart';
import 'auth_provider.dart';

final benefitEngineProvider = Provider<BenefitEngine>((ref) {
  return BenefitEngine(
    cardService: ref.watch(cardServiceProvider),
    transactionService: ref.watch(transactionServiceProvider),
  );
});

final benefitResultsProvider =
    FutureProvider<List<BenefitResult>>((ref) async {
  final isGuest = ref.watch(isGuestModeProvider);
  if (isGuest) return DemoDataService.benefitResults;

  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final userCards = ref.watch(userCardsProvider);
  final engine = ref.watch(benefitEngineProvider);

  final cards = userCards.valueOrNull ?? [];
  if (cards.isEmpty) return [];

  // 거래 내역이 바뀌면 혜택도 재계산
  ref.watch(monthlyTransactionsProvider);

  return engine.calculateAll(userId: user.id, userCards: cards);
});

final recommendedCardProvider = Provider<BenefitResult?>((ref) {
  final results = ref.watch(benefitResultsProvider);
  final engine = ref.watch(benefitEngineProvider);
  return results.whenOrNull(
    data: (data) => engine.getRecommendedCard(data),
  );
});

final totalSavingsProvider = Provider<int>((ref) {
  final results = ref.watch(benefitResultsProvider);
  final engine = ref.watch(benefitEngineProvider);
  return results.whenOrNull(
        data: (data) => engine.getTotalSavings(data),
      ) ??
      0;
});
