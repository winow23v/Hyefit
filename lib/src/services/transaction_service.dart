import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client.dart';
import '../models/transaction.dart';

class TransactionService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<Transaction>> getTransactions({
    required String userId,
    DateTime? from,
    DateTime? to,
  }) async {
    var query = _client
        .from('transactions')
        .select()
        .eq('user_id', userId);

    if (from != null) {
      query = query.gte(
          'transaction_date', from.toIso8601String().substring(0, 10));
    }
    if (to != null) {
      query = query.lte(
          'transaction_date', to.toIso8601String().substring(0, 10));
    }

    final data = await query.order('transaction_date', ascending: false);
    return data.map((e) => Transaction.fromJson(e)).toList();
  }

  Future<List<Transaction>> getTransactionsByCard({
    required String userId,
    required String userCardId,
    required DateTime from,
    required DateTime to,
  }) async {
    final data = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .eq('user_card_id', userCardId)
        .gte('transaction_date', from.toIso8601String().substring(0, 10))
        .lte('transaction_date', to.toIso8601String().substring(0, 10))
        .order('transaction_date', ascending: false);
    return data.map((e) => Transaction.fromJson(e)).toList();
  }

  Future<Transaction> addTransaction({
    required String userId,
    required String userCardId,
    required int amount,
    required String category,
    String? memo,
    required DateTime transactionDate,
  }) async {
    final data = await _client
        .from('transactions')
        .insert({
          'user_id': userId,
          'user_card_id': userCardId,
          'amount': amount,
          'category': category,
          'memo': memo,
          'transaction_date':
              transactionDate.toIso8601String().substring(0, 10),
        })
        .select()
        .single();
    return Transaction.fromJson(data);
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _client.from('transactions').delete().eq('id', transactionId);
  }

  Future<int> getMonthlySpend({
    required String userId,
    required String userCardId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final data = await _client
        .from('transactions')
        .select('amount')
        .eq('user_id', userId)
        .eq('user_card_id', userCardId)
        .gte('transaction_date',
            periodStart.toIso8601String().substring(0, 10))
        .lte('transaction_date',
            periodEnd.toIso8601String().substring(0, 10));

    int total = 0;
    for (final row in data) {
      total += row['amount'] as int;
    }
    return total;
  }

  Future<int> getMonthlyCategorySpend({
    required String userId,
    required String userCardId,
    required String category,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final data = await _client
        .from('transactions')
        .select('amount')
        .eq('user_id', userId)
        .eq('user_card_id', userCardId)
        .eq('category', category)
        .gte('transaction_date',
            periodStart.toIso8601String().substring(0, 10))
        .lte('transaction_date',
            periodEnd.toIso8601String().substring(0, 10));

    int total = 0;
    for (final row in data) {
      total += row['amount'] as int;
    }
    return total;
  }
}
