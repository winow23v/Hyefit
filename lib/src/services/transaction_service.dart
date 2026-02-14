import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client.dart';
import '../models/transaction.dart';

class TransactionService {
  final SupabaseClient _client = SupabaseConfig.client;

  String _requireSignedInUser(String requestedUserId) {
    final sessionUserId = _client.auth.currentUser?.id;
    if (sessionUserId == null) {
      throw StateError('로그인이 필요합니다.');
    }
    if (sessionUserId != requestedUserId) {
      throw ArgumentError('요청한 사용자 ID가 현재 세션과 일치하지 않습니다.');
    }
    return sessionUserId;
  }

  static String _dateOnly(DateTime date) {
    return date.toIso8601String().substring(0, 10);
  }

  Future<List<Transaction>> getTransactions({
    required String userId,
    DateTime? from,
    DateTime? to,
  }) async {
    final resolvedUserId = _requireSignedInUser(userId);
    var query = _client
        .from('transactions')
        .select()
        .eq('user_id', resolvedUserId);

    if (from != null) {
      query = query.gte('transaction_date', _dateOnly(from));
    }
    if (to != null) {
      query = query.lte('transaction_date', _dateOnly(to));
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
    final resolvedUserId = _requireSignedInUser(userId);
    final data = await _client
        .from('transactions')
        .select()
        .eq('user_id', resolvedUserId)
        .eq('user_card_id', userCardId)
        .gte('transaction_date', _dateOnly(from))
        .lte('transaction_date', _dateOnly(to))
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
    final resolvedUserId = _requireSignedInUser(userId);
    final normalizedCategory = category.trim();
    if (amount <= 0) {
      throw ArgumentError('amount는 0보다 커야 합니다.');
    }
    if (normalizedCategory.isEmpty) {
      throw ArgumentError('category는 비어 있을 수 없습니다.');
    }

    final data = await _client
        .from('transactions')
        .insert({
          'user_id': resolvedUserId,
          'user_card_id': userCardId,
          'amount': amount,
          'category': normalizedCategory,
          'memo': memo,
          'transaction_date': _dateOnly(transactionDate),
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
    final resolvedUserId = _requireSignedInUser(userId);
    final data = await _client
        .from('transactions')
        .select('amount')
        .eq('user_id', resolvedUserId)
        .eq('user_card_id', userCardId)
        .gte('transaction_date', _dateOnly(periodStart))
        .lte('transaction_date', _dateOnly(periodEnd));

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
    final resolvedUserId = _requireSignedInUser(userId);
    final data = await _client
        .from('transactions')
        .select('amount')
        .eq('user_id', resolvedUserId)
        .eq('user_card_id', userCardId)
        .eq('category', category)
        .gte('transaction_date', _dateOnly(periodStart))
        .lte('transaction_date', _dateOnly(periodEnd));

    int total = 0;
    for (final row in data) {
      total += row['amount'] as int;
    }
    return total;
  }
}
