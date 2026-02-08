import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/demo_data_service.dart';
import 'auth_provider.dart';

final transactionServiceProvider =
    Provider<TransactionService>((ref) => TransactionService());

/// 이번 달 거래 내역
final monthlyTransactionsProvider =
    AsyncNotifierProvider<MonthlyTransactionsNotifier, List<Transaction>>(
  MonthlyTransactionsNotifier.new,
);

class MonthlyTransactionsNotifier extends AsyncNotifier<List<Transaction>> {
  @override
  Future<List<Transaction>> build() async {
    final isGuest = ref.watch(isGuestModeProvider);
    if (isGuest) return DemoDataService.transactions;

    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    final service = ref.watch(transactionServiceProvider);
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month + 1, 0);

    return service.getTransactions(
      userId: user.id,
      from: from,
      to: to,
    );
  }

  Future<void> addTransaction({
    required String userCardId,
    required int amount,
    required String category,
    String? memo,
    required DateTime transactionDate,
  }) async {
    final isGuest = ref.read(isGuestModeProvider);

    if (isGuest) {
      // 게스트 모드: 로컬 메모리에 추가
      final currentData = state.valueOrNull ?? [];
      final newTx = Transaction(
        id: 'guest-tx-${DateTime.now().millisecondsSinceEpoch}',
        userId: DemoDataService.guestUserId,
        userCardId: userCardId,
        amount: amount,
        category: category,
        memo: memo,
        transactionDate: transactionDate,
        createdAt: DateTime.now(),
      );
      state = AsyncData([newTx, ...currentData]);
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final service = ref.read(transactionServiceProvider);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await service.addTransaction(
        userId: user.id,
        userCardId: userCardId,
        amount: amount,
        category: category,
        memo: memo,
        transactionDate: transactionDate,
      );
      final now = DateTime.now();
      return service.getTransactions(
        userId: user.id,
        from: DateTime(now.year, now.month, 1),
        to: DateTime(now.year, now.month + 1, 0),
      );
    });
  }

  Future<void> deleteTransaction(String transactionId) async {
    final isGuest = ref.read(isGuestModeProvider);
    if (isGuest) {
      final currentData = state.valueOrNull ?? DemoDataService.transactions;
      state = AsyncData(
        currentData.where((tx) => tx.id != transactionId).toList(),
      );
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final service = ref.read(transactionServiceProvider);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await service.deleteTransaction(transactionId);
      final now = DateTime.now();
      return service.getTransactions(
        userId: user.id,
        from: DateTime(now.year, now.month, 1),
        to: DateTime(now.year, now.month + 1, 0),
      );
    });
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
