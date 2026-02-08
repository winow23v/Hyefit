import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'benefit_provider.dart';
import 'card_provider.dart';
import 'transaction_provider.dart';

/// 대시보드에서 필요한 데이터를 한 번에 refresh
final dashboardRefreshProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    ref.invalidate(userCardsProvider);
    ref.invalidate(monthlyTransactionsProvider);
    ref.invalidate(benefitResultsProvider);
  };
});
