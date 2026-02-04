import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client.dart';
import '../models/card_master.dart';
import '../models/card_benefit_rule.dart';
import '../models/card_benefit_threshold.dart';
import '../models/user_card.dart';
import '../models/user_card_status.dart';

class CardService {
  final SupabaseClient _client = SupabaseConfig.client;

  // ── 카드 마스터 (시스템 데이터) ──

  Future<List<CardMaster>> getAllCards() async {
    final data = await _client
        .from('card_master')
        .select()
        .order('card_name');
    return data.map((e) => CardMaster.fromJson(e)).toList();
  }

  Future<CardMaster> getCard(String cardId) async {
    final data = await _client
        .from('card_master')
        .select()
        .eq('id', cardId)
        .single();
    return CardMaster.fromJson(data);
  }

  // ── 카드 혜택 규칙 ──

  Future<List<CardBenefitRule>> getBenefitRules(String cardId) async {
    final data = await _client
        .from('card_benefit_rules')
        .select()
        .eq('card_id', cardId)
        .order('priority');
    return data.map((e) => CardBenefitRule.fromJson(e)).toList();
  }

  Future<List<CardBenefitThreshold>> getThresholds(
      String benefitRuleId) async {
    final data = await _client
        .from('card_benefit_thresholds')
        .select()
        .eq('benefit_rule_id', benefitRuleId)
        .order('min_spend_amount');
    return data.map((e) => CardBenefitThreshold.fromJson(e)).toList();
  }

  // ── 카드 마스터 관리 (Admin) ──

  Future<CardMaster> addCardMaster({
    required String cardName,
    required String issuer,
    required int annualFee,
    String imageColor = '#7C83FD',
  }) async {
    final data = await _client
        .from('card_master')
        .insert({
          'card_name': cardName,
          'issuer': issuer,
          'annual_fee': annualFee,
          'image_color': imageColor,
        })
        .select()
        .single();
    return CardMaster.fromJson(data);
  }

  Future<void> deleteCardMaster(String cardId) async {
    await _client.from('card_master').delete().eq('id', cardId);
  }

  // ── 혜택 규칙 관리 (Admin) ──

  Future<CardBenefitRule> addBenefitRule({
    required String cardId,
    required String category,
    required int minMonthlySpend,
    String benefitType = 'cashback',
    required double benefitRate,
    required int maxBenefitAmount,
    int priority = 0,
  }) async {
    final data = await _client
        .from('card_benefit_rules')
        .insert({
          'card_id': cardId,
          'category': category,
          'min_monthly_spend': minMonthlySpend,
          'benefit_type': benefitType,
          'benefit_rate': benefitRate,
          'max_benefit_amount': maxBenefitAmount,
          'priority': priority,
        })
        .select()
        .single();
    return CardBenefitRule.fromJson(data);
  }

  Future<void> deleteBenefitRule(String ruleId) async {
    await _client.from('card_benefit_rules').delete().eq('id', ruleId);
  }

  // ── 사용자 카드 ──

  Future<List<UserCard>> getUserCards(String userId) async {
    final data = await _client
        .from('user_cards')
        .select('*, card_master(*)')
        .eq('user_id', userId)
        .order('created_at');
    return data.map((e) => UserCard.fromJson(e)).toList();
  }

  Future<UserCard> addUserCard({
    required String userId,
    required String cardMasterId,
    String? nickname,
  }) async {
    final data = await _client
        .from('user_cards')
        .insert({
          'user_id': userId,
          'card_master_id': cardMasterId,
          'nickname': nickname,
        })
        .select('*, card_master(*)')
        .single();
    return UserCard.fromJson(data);
  }

  Future<UserCard> updateUserCardNickname({
    required String userCardId,
    required String nickname,
  }) async {
    final data = await _client
        .from('user_cards')
        .update({'nickname': nickname})
        .eq('id', userCardId)
        .select('*, card_master(*)')
        .single();
    return UserCard.fromJson(data);
  }

  Future<void> removeUserCard(String userCardId) async {
    await _client.from('user_cards').delete().eq('id', userCardId);
  }

  // ── 사용자 카드 상태 ──

  Future<UserCardStatus?> getCardStatus({
    required String userCardId,
    required DateTime periodStart,
  }) async {
    final data = await _client
        .from('user_card_status')
        .select()
        .eq('user_card_id', userCardId)
        .eq('period_start', periodStart.toIso8601String().substring(0, 10))
        .maybeSingle();
    return data != null ? UserCardStatus.fromJson(data) : null;
  }

  Future<UserCardStatus> upsertCardStatus({
    required String userCardId,
    required int currentSpend,
    required int currentBenefit,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    final data = await _client
        .from('user_card_status')
        .upsert(
          {
            'user_card_id': userCardId,
            'current_spend': currentSpend,
            'current_benefit': currentBenefit,
            'period_start': periodStart.toIso8601String().substring(0, 10),
            'period_end': periodEnd.toIso8601String().substring(0, 10),
            'updated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'user_card_id,period_start',
        )
        .select()
        .single();
    return UserCardStatus.fromJson(data);
  }

  Future<List<UserCardStatus>> getAllCardStatuses(String userId) async {
    final userCards = await getUserCards(userId);
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month, 1);

    final List<UserCardStatus> statuses = [];
    for (final card in userCards) {
      final status = await getCardStatus(
        userCardId: card.id,
        periodStart: periodStart,
      );
      if (status != null) {
        statuses.add(status);
      }
    }
    return statuses;
  }
}
