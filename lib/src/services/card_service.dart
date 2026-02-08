import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client.dart';
import '../models/card_master.dart';
import '../models/card_benefit_tier.dart';
import '../models/card_tier_rule.dart';
import '../models/user_card.dart';
import '../models/user_card_status.dart';

class CardService {
  final SupabaseClient _client = SupabaseConfig.client;

  // ── 카드 마스터 (시스템 데이터) ──

  Future<List<CardMaster>> getAllCards() async {
    final data = await _client.from('card_master').select().order('card_name');
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

  // ── Tier 기반 혜택 조회 ──

  /// 카드의 모든 Tier와 각 Tier의 규칙을 nested join으로 조회
  Future<List<CardBenefitTier>> getBenefitTiers(String cardId) async {
    final data = await _client
        .from('card_benefit_tiers')
        .select('*, card_tier_rules(*)')
        .eq('card_id', cardId)
        .order('tier_order');
    return data.map((e) => CardBenefitTier.fromJson(e)).toList();
  }

  /// 전월 실적에 맞는 Tier 찾기
  CardBenefitTier? findMatchingTier({
    required List<CardBenefitTier> tiers,
    required int prevMonthSpend,
  }) {
    if (tiers.isEmpty) return null;

    // tier_order 역순으로 정렬 (높은 Tier부터 확인)
    final sorted = List<CardBenefitTier>.from(tiers)
      ..sort((a, b) => b.tierOrder.compareTo(a.tierOrder));

    for (final tier in sorted) {
      if (tier.matchesPrevSpend(prevMonthSpend)) {
        return tier;
      }
    }

    // 매칭되는 Tier가 없으면 가장 낮은 Tier 반환 (기본 혜택)
    return tiers.first;
  }

  /// 다음 Tier 정보 조회
  CardBenefitTier? findNextTier({
    required List<CardBenefitTier> tiers,
    required CardBenefitTier currentTier,
  }) {
    final sorted = List<CardBenefitTier>.from(tiers)
      ..sort((a, b) => a.tierOrder.compareTo(b.tierOrder));

    final currentIndex = sorted.indexWhere((t) => t.id == currentTier.id);
    if (currentIndex == -1 || currentIndex >= sorted.length - 1) {
      return null; // 이미 최고 Tier
    }
    return sorted[currentIndex + 1];
  }

  // ── 카드 마스터 관리 (Admin) ──

  Future<CardMaster> addCardMaster({
    required String cardName,
    required String issuer,
    required int annualFee,
    String imageColor = '#7C83FD',
    int monthlyBenefitCap = 0,
    double baseBenefitRate = 0,
    String baseBenefitType = 'cashback',
    String description = '',
  }) async {
    final data = await _client
        .from('card_master')
        .insert({
          'card_name': cardName,
          'issuer': issuer,
          'annual_fee': annualFee,
          'image_color': imageColor,
          'monthly_benefit_cap': monthlyBenefitCap,
          'base_benefit_rate': baseBenefitRate,
          'base_benefit_type': baseBenefitType,
          'description': description,
        })
        .select()
        .single();
    return CardMaster.fromJson(data);
  }

  Future<CardMaster> updateCardMaster({
    required String cardId,
    String? cardName,
    String? issuer,
    int? annualFee,
    String? imageColor,
    int? monthlyBenefitCap,
    double? baseBenefitRate,
    String? baseBenefitType,
    String? description,
  }) async {
    final updates = <String, dynamic>{};
    if (cardName != null) updates['card_name'] = cardName;
    if (issuer != null) updates['issuer'] = issuer;
    if (annualFee != null) updates['annual_fee'] = annualFee;
    if (imageColor != null) updates['image_color'] = imageColor;
    if (monthlyBenefitCap != null) {
      updates['monthly_benefit_cap'] = monthlyBenefitCap;
    }
    if (baseBenefitRate != null) updates['base_benefit_rate'] = baseBenefitRate;
    if (baseBenefitType != null) updates['base_benefit_type'] = baseBenefitType;
    if (description != null) updates['description'] = description;

    final data = await _client
        .from('card_master')
        .update(updates)
        .eq('id', cardId)
        .select()
        .single();
    return CardMaster.fromJson(data);
  }

  Future<void> deleteCardMaster(String cardId) async {
    await _client.from('card_master').delete().eq('id', cardId);
  }

  // ── Tier 관리 (Admin) ──

  Future<CardBenefitTier> addBenefitTier({
    required String cardId,
    required String tierName,
    required int minPrevSpend,
    int? maxPrevSpend,
    required int tierOrder,
  }) async {
    final data = await _client
        .from('card_benefit_tiers')
        .insert({
          'card_id': cardId,
          'tier_name': tierName,
          'min_prev_spend': minPrevSpend,
          'max_prev_spend': maxPrevSpend,
          'tier_order': tierOrder,
        })
        .select('*, card_tier_rules(*)')
        .single();
    return CardBenefitTier.fromJson(data);
  }

  Future<void> deleteBenefitTier(String tierId) async {
    await _client.from('card_benefit_tiers').delete().eq('id', tierId);
  }

  // ── Tier Rule 관리 (Admin) ──

  Future<CardTierRule> addTierRule({
    required String tierId,
    required String category,
    String benefitType = 'cashback',
    required double benefitRate,
    required int maxBenefitAmount,
    int priority = 0,
  }) async {
    final data = await _client
        .from('card_tier_rules')
        .insert({
          'tier_id': tierId,
          'category': category,
          'benefit_type': benefitType,
          'benefit_rate': benefitRate,
          'max_benefit_amount': maxBenefitAmount,
          'priority': priority,
        })
        .select()
        .single();
    return CardTierRule.fromJson(data);
  }

  Future<void> deleteTierRule(String ruleId) async {
    await _client.from('card_tier_rules').delete().eq('id', ruleId);
  }

  // ── JSON 일괄 등록 ──

  /// 카드 데이터를 JSON으로 등록/수정(동일 카드명+카드사 기준 upsert)
  Future<CardMaster> importCardFromJson(Map<String, dynamic> json) async {
    final imported = await importCardsFromJson([json]);
    if (imported.isEmpty) {
      throw StateError('카드 import 결과가 비어 있습니다.');
    }
    return imported.first;
  }

  Future<List<CardMaster>> importCardsFromJson(
    List<Map<String, dynamic>> cardsJson,
  ) async {
    final normalizedCards = _normalizeImportCards(cardsJson);

    try {
      return await _importCardsViaRpc(normalizedCards);
    } on PostgrestException catch (e) {
      // 신규 RPC 미적용 환경(구 스키마)에서는 기존 방식으로 폴백
      final lower = e.message.toLowerCase();
      final isMissingRpc =
          e.code == 'PGRST202' ||
          lower.contains('could not find the function') ||
          lower.contains('upsert_cards_from_json');
      if (!isMissingRpc) rethrow;

      final imported = <CardMaster>[];
      for (final cardJson in normalizedCards) {
        imported.add(await _importCardFromJsonLegacy(cardJson));
      }
      return imported;
    }
  }

  Future<List<CardMaster>> _importCardsViaRpc(
    List<Map<String, dynamic>> normalizedCards,
  ) async {
    final result = await _client.rpc(
      'upsert_cards_from_json',
      params: {'p_cards': normalizedCards},
    );

    if (result is! List) {
      throw StateError('RPC 응답 형식이 올바르지 않습니다.');
    }

    final ids = <String>[];
    for (final row in result) {
      if (row is! Map) continue;
      final id = row['card_id']?.toString();
      if (id == null || id.isEmpty) continue;
      ids.add(id);
    }

    if (ids.isEmpty) return [];

    final rows = await _client.from('card_master').select().inFilter('id', ids);

    final byId = <String, CardMaster>{};
    for (final row in rows) {
      final card = CardMaster.fromJson(row);
      byId[card.id] = card;
    }

    final imported = <CardMaster>[];
    for (final id in ids) {
      final card = byId[id];
      if (card != null) imported.add(card);
    }
    return imported;
  }

  Future<CardMaster> _importCardFromJsonLegacy(
    Map<String, dynamic> normalizedJson,
  ) async {
    final cardName = (normalizedJson['card_name'] ?? '').toString().trim();
    final issuer = (normalizedJson['issuer'] ?? '').toString().trim();
    if (cardName.isEmpty || issuer.isEmpty) {
      throw ArgumentError('card_name, issuer는 필수입니다.');
    }

    final annualFee = _toInt(normalizedJson['annual_fee']);
    final imageColor = _normalizeColor(
      (normalizedJson['image_color'] ?? '#7C83FD').toString(),
    );
    final monthlyBenefitCap = _toInt(normalizedJson['monthly_benefit_cap']);
    final baseBenefitRate = _toDouble(normalizedJson['base_benefit_rate']);
    final baseBenefitType = _normalizeBenefitType(
      (normalizedJson['base_benefit_type'] ?? 'cashback').toString(),
    );
    final description = (normalizedJson['description'] ?? '').toString().trim();

    final existingRows = await _client
        .from('card_master')
        .select('id')
        .eq('card_name', cardName)
        .eq('issuer', issuer)
        .limit(1);

    CardMaster cardMaster;
    if (existingRows.isEmpty) {
      cardMaster = await addCardMaster(
        cardName: cardName,
        issuer: issuer,
        annualFee: annualFee,
        imageColor: imageColor,
        monthlyBenefitCap: monthlyBenefitCap,
        baseBenefitRate: baseBenefitRate,
        baseBenefitType: baseBenefitType,
        description: description,
      );
    } else {
      final existingId = existingRows.first['id'] as String;
      cardMaster = await updateCardMaster(
        cardId: existingId,
        cardName: cardName,
        issuer: issuer,
        annualFee: annualFee,
        imageColor: imageColor,
        monthlyBenefitCap: monthlyBenefitCap,
        baseBenefitRate: baseBenefitRate,
        baseBenefitType: baseBenefitType,
        description: description,
      );

      await _client
          .from('card_benefit_tiers')
          .delete()
          .eq('card_id', cardMaster.id);
    }

    final tiers = (normalizedJson['tiers'] as List<dynamic>? ?? const []);
    for (var i = 0; i < tiers.length; i++) {
      final tierJson = Map<String, dynamic>.from(tiers[i] as Map);
      final tier = await addBenefitTier(
        cardId: cardMaster.id,
        tierName: (tierJson['tier_name'] ?? '').toString(),
        minPrevSpend: _toInt(tierJson['min_prev_spend']),
        maxPrevSpend: _toNullableInt(tierJson['max_prev_spend']),
        tierOrder: _toInt(tierJson['tier_order'], fallback: i + 1),
      );

      final rules = tierJson['rules'] as List<dynamic>? ?? const [];
      for (var j = 0; j < rules.length; j++) {
        final ruleJson = Map<String, dynamic>.from(rules[j] as Map);
        await addTierRule(
          tierId: tier.id,
          category: _normalizeCategory(
            (ruleJson['category'] ?? '기타').toString(),
          ),
          benefitType: _normalizeBenefitType(
            (ruleJson['benefit_type'] ?? 'cashback').toString(),
          ),
          benefitRate: _toDouble(ruleJson['benefit_rate']),
          maxBenefitAmount: _toInt(ruleJson['max_benefit_amount']),
          priority: _toInt(ruleJson['priority'], fallback: j + 1),
        );
      }
    }

    return cardMaster;
  }

  static List<Map<String, dynamic>> _normalizeImportCards(
    List<Map<String, dynamic>> cardsJson,
  ) {
    if (cardsJson.isEmpty) {
      throw ArgumentError('등록할 카드 데이터가 없습니다.');
    }
    return cardsJson.map(_normalizeImportCardJson).toList();
  }

  static Map<String, dynamic> _normalizeImportCardJson(
    Map<String, dynamic> rawCard,
  ) {
    final cardName = (rawCard['card_name'] ?? '').toString().trim();
    final issuer = (rawCard['issuer'] ?? '').toString().trim();
    if (cardName.isEmpty || issuer.isEmpty) {
      throw ArgumentError('card_name, issuer는 필수입니다.');
    }

    final tiersRaw = rawCard['tiers'];
    if (tiersRaw is! List || tiersRaw.isEmpty) {
      throw ArgumentError('$cardName: tiers를 1개 이상 입력해주세요.');
    }

    final tierRows = <Map<String, dynamic>>[];
    for (var tierIndex = 0; tierIndex < tiersRaw.length; tierIndex++) {
      final tierRaw = tiersRaw[tierIndex];
      if (tierRaw is! Map) {
        throw ArgumentError('$cardName ${tierIndex + 1}번째 tier 형식이 잘못되었습니다.');
      }

      final tier = Map<String, dynamic>.from(tierRaw);
      final minPrevSpend = _toInt(tier['min_prev_spend']);
      var maxPrevSpend = _toNullableInt(tier['max_prev_spend']);
      if (maxPrevSpend != null && maxPrevSpend < minPrevSpend) {
        throw ArgumentError(
          '$cardName ${tierIndex + 1}번째 tier: 실적 구간이 잘못되었습니다.',
        );
      }

      final rulesRaw = tier['rules'];
      if (rulesRaw is! List || rulesRaw.isEmpty) {
        throw ArgumentError(
          '$cardName ${tierIndex + 1}번째 tier: rules를 1개 이상 입력해주세요.',
        );
      }

      final ruleMap = <String, Map<String, dynamic>>{};
      for (var ruleIndex = 0; ruleIndex < rulesRaw.length; ruleIndex++) {
        final ruleRaw = rulesRaw[ruleIndex];
        if (ruleRaw is! Map) {
          throw ArgumentError(
            '$cardName ${tierIndex + 1}번째 tier ${ruleIndex + 1}번째 rule 형식이 잘못되었습니다.',
          );
        }

        final rule = Map<String, dynamic>.from(ruleRaw);
        final category = _normalizeCategory(
          (rule['category'] ?? '기타').toString(),
        );
        final benefitType = _normalizeBenefitType(
          (rule['benefit_type'] ?? 'cashback').toString(),
        );
        final benefitRate = _toDouble(rule['benefit_rate']);
        final maxBenefitAmount = _toInt(rule['max_benefit_amount']);
        var priority = _toInt(rule['priority'], fallback: ruleIndex + 1);

        if (benefitRate < 0) {
          throw ArgumentError(
            '$cardName ${tierIndex + 1}번째 tier ${ruleIndex + 1}번째 rule: benefit_rate는 0 이상이어야 합니다.',
          );
        }
        if (maxBenefitAmount < 0) {
          throw ArgumentError(
            '$cardName ${tierIndex + 1}번째 tier ${ruleIndex + 1}번째 rule: max_benefit_amount는 0 이상이어야 합니다.',
          );
        }
        if (priority <= 0) priority = ruleIndex + 1;

        final dedupeKey = '$category::$priority';
        ruleMap[dedupeKey] = {
          'category': category,
          'benefit_type': benefitType,
          'benefit_rate': benefitRate,
          'max_benefit_amount': maxBenefitAmount,
          'priority': priority,
        };
      }

      final normalizedRules = ruleMap.values.toList()
        ..sort(
          (a, b) => (a['priority'] as int).compareTo(b['priority'] as int),
        );

      tierRows.add({
        'tier_name': (tier['tier_name'] ?? '').toString().trim(),
        'min_prev_spend': minPrevSpend,
        'max_prev_spend': maxPrevSpend,
        'rules': normalizedRules,
      });
    }

    tierRows.sort((a, b) {
      final minCmp = (a['min_prev_spend'] as int).compareTo(
        b['min_prev_spend'] as int,
      );
      if (minCmp != 0) return minCmp;
      final aMax = a['max_prev_spend'] as int?;
      final bMax = b['max_prev_spend'] as int?;
      if (aMax == null && bMax == null) return 0;
      if (aMax == null) return 1;
      if (bMax == null) return -1;
      return aMax.compareTo(bMax);
    });

    for (var i = 0; i < tierRows.length; i++) {
      final current = tierRows[i];
      final currentMin = current['min_prev_spend'] as int;
      var currentMax = current['max_prev_spend'] as int?;

      if (i < tierRows.length - 1) {
        final nextMin = tierRows[i + 1]['min_prev_spend'] as int;
        if (nextMin <= currentMin) {
          throw ArgumentError('$cardName: tier 최소 실적은 오름차순이어야 합니다.');
        }
        if (currentMax == null || currentMax >= nextMin) {
          currentMax = nextMin - 1;
        }
      }

      if (currentMax != null && currentMax < currentMin) {
        throw ArgumentError('$cardName: tier 실적 구간이 잘못되었습니다.');
      }

      current['max_prev_spend'] = currentMax;
      final tierName = (current['tier_name'] as String).trim();
      current['tier_name'] = tierName.isEmpty
          ? _buildTierName(currentMin, currentMax)
          : tierName;
      current['tier_order'] = i + 1;
    }

    return {
      'card_name': cardName,
      'issuer': issuer,
      'annual_fee': _toInt(rawCard['annual_fee']),
      'image_color': _normalizeColor(
        (rawCard['image_color'] ?? '#7C83FD').toString(),
      ),
      'monthly_benefit_cap': _toInt(rawCard['monthly_benefit_cap']),
      'base_benefit_rate': _toDouble(rawCard['base_benefit_rate']),
      'base_benefit_type': _normalizeBenefitType(
        (rawCard['base_benefit_type'] ?? 'cashback').toString(),
      ),
      'description': (rawCard['description'] ?? '').toString().trim(),
      'tiers': tierRows,
    };
  }

  static String _buildTierName(int minPrevSpend, int? maxPrevSpend) {
    if (maxPrevSpend != null && maxPrevSpend == minPrevSpend - 1) {
      return '조건없음';
    }
    if (minPrevSpend <= 0) {
      if (maxPrevSpend == null) return '조건없음';
      return '0원 ~ ${_formatWon(maxPrevSpend)}';
    }
    if (maxPrevSpend == null) {
      return '${_formatWon(minPrevSpend)} 이상';
    }
    return '${_formatWon(minPrevSpend)} ~ ${_formatWon(maxPrevSpend)}';
  }

  static String _formatWon(int amount) {
    if (amount % 10000 == 0) {
      return '${amount ~/ 10000}만원';
    }
    return '$amount원';
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) {
      final clean = value.replaceAll(',', '').trim();
      return int.tryParse(clean) ?? fallback;
    }
    return fallback;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isEmpty) return null;
    return _toInt(value);
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) {
      final clean = value.replaceAll(',', '').trim();
      return double.tryParse(clean) ?? fallback;
    }
    return fallback;
  }

  static String _normalizeColor(String value) {
    final trimmed = value.trim();
    final hex = trimmed.startsWith('#') ? trimmed : '#$trimmed';
    if (RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex)) return hex;
    return '#7C83FD';
  }

  static String _normalizeCategory(String raw) {
    final key = raw.trim().toLowerCase();
    const map = {
      '식비': '외식',
      'food': '외식',
      'restaurant': '외식',
      '푸드': '외식',
      'cafe': '카페',
      'coffee': '카페',
      '커피': '카페',
      '대중교통': '교통',
      'transport': '교통',
      'transit': '교통',
      '통신': '생활',
      '공과금': '생활',
      'life': '생활',
      'utility': '생활',
      'ott': '디지털구독',
      'subscription': '디지털구독',
      '구독': '디지털구독',
      'streaming': '디지털구독',
      'shopping': '쇼핑',
      'store': '쇼핑',
      'convenience': '편의점',
      'conveniencestore': '편의점',
      'online': '온라인쇼핑',
      'online_shopping': '온라인쇼핑',
      'mart': '마트',
      'grocery': '마트',
      'traditional': '전통시장',
      '시장': '전통시장',
      'overseas': '해외',
      'foreign': '해외',
      '해외결제': '해외',
      'installment': '무이자할부',
      '할부': '무이자할부',
      'gas': '주유',
      '기름': '주유',
      'culture': '문화',
      'movie': '문화',
      '영화': '문화',
      'delivery': '배달앱',
      '배달': '배달앱',
      'etc': '기타',
      'other': '기타',
    };
    return map[key] ?? raw.trim();
  }

  static String _normalizeBenefitType(String raw) {
    final key = raw.trim().toLowerCase();
    const allowed = {'cashback', 'point', 'discount', 'mileage'};
    if (allowed.contains(key)) return key;
    return 'cashback';
  }

  // ── 사용자 카드 ──

  Future<List<UserCard>> getUserCards(String userId) async {
    try {
      final data = await _client
          .from('user_cards')
          .select('*, card_master(*)')
          .eq('user_id', userId)
          .order('display_order')
          .order('created_at');
      return data.map((e) => UserCard.fromJson(e)).toList();
    } on PostgrestException catch (_) {
      final data = await _client
          .from('user_cards')
          .select('*, card_master(*)')
          .eq('user_id', userId)
          .order('created_at');
      return data.map((e) => UserCard.fromJson(e)).toList();
    }
  }

  Future<UserCard> addUserCard({
    required String userId,
    required String cardMasterId,
    String? cardName,
    String? issuer,
    String? nickname,
  }) async {
    final resolvedCardMasterId = await _resolveCardMasterId(
      cardMasterId: cardMasterId,
      cardName: cardName,
      issuer: issuer,
    );

    try {
      final latestOrder = await _client
          .from('user_cards')
          .select('display_order')
          .eq('user_id', userId)
          .order('display_order', ascending: false)
          .limit(1)
          .maybeSingle();
      final nextOrder = latestOrder == null
          ? 0
          : ((latestOrder['display_order'] as int?) ?? 0) + 1;

      final data = await _client
          .from('user_cards')
          .insert({
            'user_id': userId,
            'card_master_id': resolvedCardMasterId,
            'nickname': nickname,
            'display_order': nextOrder,
          })
          .select('*, card_master(*)')
          .single();
      return UserCard.fromJson(data);
    } on PostgrestException catch (_) {
      final data = await _client
          .from('user_cards')
          .insert({
            'user_id': userId,
            'card_master_id': resolvedCardMasterId,
            'nickname': nickname,
          })
          .select('*, card_master(*)')
          .single();
      return UserCard.fromJson(data);
    }
  }

  Future<String> _resolveCardMasterId({
    required String cardMasterId,
    String? cardName,
    String? issuer,
  }) async {
    final byId = await _client
        .from('card_master')
        .select('id')
        .eq('id', cardMasterId)
        .maybeSingle();
    if (byId != null) {
      return byId['id'] as String;
    }

    final normalizedCardName = cardName?.trim() ?? '';
    final normalizedIssuer = issuer?.trim() ?? '';
    if (normalizedCardName.isNotEmpty && normalizedIssuer.isNotEmpty) {
      final byNameIssuer = await _client
          .from('card_master')
          .select('id')
          .eq('card_name', normalizedCardName)
          .eq('issuer', normalizedIssuer)
          .maybeSingle();
      if (byNameIssuer != null) {
        return byNameIssuer['id'] as String;
      }
    }

    throw StateError('선택한 카드가 카드 마스터에 없습니다. 카드 목록을 새로고침 후 다시 시도해주세요.');
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

  Future<void> reorderUserCards({
    required String userId,
    required List<String> orderedUserCardIds,
  }) async {
    try {
      for (var i = 0; i < orderedUserCardIds.length; i++) {
        await _client
            .from('user_cards')
            .update({'display_order': i})
            .eq('id', orderedUserCardIds[i])
            .eq('user_id', userId);
      }
    } on PostgrestException catch (_) {
      // display_order 컬럼이 없는 구버전 스키마에서는 로컬 정렬만 유지
    }
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
        .upsert({
          'user_card_id': userCardId,
          'current_spend': currentSpend,
          'current_benefit': currentBenefit,
          'period_start': periodStart.toIso8601String().substring(0, 10),
          'period_end': periodEnd.toIso8601String().substring(0, 10),
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_card_id,period_start')
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
