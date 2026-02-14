import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/card_provider.dart';

class AdminCardWebImportScreen extends ConsumerStatefulWidget {
  const AdminCardWebImportScreen({super.key});

  @override
  ConsumerState<AdminCardWebImportScreen> createState() =>
      _AdminCardWebImportScreenState();
}

class _AdminCardWebImportScreenState
    extends ConsumerState<AdminCardWebImportScreen> {
  final _jsonController = TextEditingController(text: _sampleImportJson);
  bool _isSubmitting = false;
  String _statusMessage = '';
  bool _statusError = false;
  int _lastParsedCount = 0;

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _parseInputCards(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('JSON을 입력해주세요.');
    }

    final decoded = jsonDecode(trimmed);

    List<dynamic> cardList;
    if (decoded is List) {
      cardList = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final cardsField = decoded['cards'];
      if (cardsField is List) {
        cardList = cardsField;
      } else {
        cardList = [decoded];
      }
    } else {
      throw const FormatException('카드 JSON 형식이 아닙니다.');
    }

    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < cardList.length; i++) {
      final row = cardList[i];
      if (row is! Map) {
        throw FormatException('${i + 1}번째 카드 데이터가 객체 형식이 아닙니다.');
      }
      result.add(Map<String, dynamic>.from(row));
    }
    return result;
  }

  String? _validateCards(List<Map<String, dynamic>> cards) {
    if (cards.isEmpty) return '등록할 카드가 없습니다.';

    for (var i = 0; i < cards.length; i++) {
      final card = cards[i];
      final cardName = (card['card_name'] ?? '').toString().trim();
      final issuer = (card['issuer'] ?? '').toString().trim();
      if (cardName.isEmpty || issuer.isEmpty) {
        return '${i + 1}번째 카드: card_name, issuer는 필수입니다.';
      }

      final tiers = card['tiers'];
      if (tiers is! List || tiers.isEmpty) {
        return '$cardName: tiers를 1개 이상 입력해주세요.';
      }

      for (var t = 0; t < tiers.length; t++) {
        final tier = tiers[t];
        if (tier is! Map) {
          return '$cardName ${t + 1}번째 tier 형식이 잘못되었습니다.';
        }
        final tierJson = Map<String, dynamic>.from(tier);
        final rules = tierJson['rules'];
        if (rules is! List || rules.isEmpty) {
          return '$cardName ${t + 1}번째 tier: rules를 1개 이상 입력해주세요.';
        }
        for (var r = 0; r < rules.length; r++) {
          final rule = rules[r];
          if (rule is! Map) {
            return '$cardName ${t + 1}번째 tier ${r + 1}번째 rule 형식이 잘못되었습니다.';
          }
          final ruleJson = Map<String, dynamic>.from(rule);
          final category = (ruleJson['category'] ?? '').toString().trim();
          if (category.isEmpty) {
            return '$cardName ${t + 1}번째 tier ${r + 1}번째 rule: category는 필수입니다.';
          }
        }
      }
    }

    return null;
  }

  Future<void> _validateJsonOnly() async {
    try {
      final cards = _parseInputCards(_jsonController.text);
      final error = _validateCards(cards);
      if (error != null) {
        setState(() {
          _statusError = true;
          _statusMessage = error;
          _lastParsedCount = 0;
        });
        return;
      }
      setState(() {
        _statusError = false;
        _statusMessage = '검증 통과: ${cards.length}개 카드 등록 가능';
        _lastParsedCount = cards.length;
      });
    } catch (e) {
      setState(() {
        _statusError = true;
        _statusMessage = 'JSON 검증 실패: $e';
        _lastParsedCount = 0;
      });
    }
  }

  Future<void> _importCards() async {
    if (_isSubmitting) return;

    List<Map<String, dynamic>> cards;
    try {
      cards = _parseInputCards(_jsonController.text);
      final validationError = _validateCards(cards);
      if (validationError != null) {
        setState(() {
          _statusError = true;
          _statusMessage = validationError;
          _lastParsedCount = 0;
        });
        return;
      }
    } catch (e) {
      setState(() {
        _statusError = true;
        _statusMessage = 'JSON 파싱 실패: $e';
        _lastParsedCount = 0;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusError = false;
      _statusMessage = 'DB 반영 중...';
      _lastParsedCount = cards.length;
    });

    try {
      final service = ref.read(cardServiceProvider);
      final imported = await service.importCardsFromJson(cards);
      ref.invalidate(allCardsProvider);
      if (!mounted) return;
      setState(() {
        _statusError = false;
        _statusMessage = '완료: ${imported.length}개 카드가 DB에 반영되었습니다.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('카드 ${imported.length}개 등록 완료'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusError = true;
        _statusMessage = '등록 실패: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('등록 실패: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('카드 마스터 웹 등록'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 1180 ? 1180.0 : 860.0;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('대량 등록 안내', style: AppTextStyles.heading3),
                          const SizedBox(height: 10),
                          Text(
                            '카드 라운지 등 외부 정보를 정리한 JSON을 붙여넣어 카드/혜택을 한 번에 등록합니다.\n'
                            '동일 카드명+카드사 데이터가 있으면 기존 Tier/Rule을 덮어씁니다.',
                            style: AppTextStyles.body2,
                          ),
                          if (!kIsWeb) ...[
                            const SizedBox(height: 8),
                            Text(
                              '웹에서 사용하면 입력이 더 편합니다.',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _jsonController.text = _sampleImportJson;
                              _statusMessage = '예시 JSON을 불러왔습니다.';
                              _statusError = false;
                            });
                          },
                          icon: const Icon(Icons.data_object_rounded),
                          label: const Text('예시 불러오기'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              const ClipboardData(text: _sampleImportJson),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('예시 JSON을 복사했습니다')),
                            );
                          },
                          icon: const Icon(Icons.copy_all_rounded),
                          label: const Text('예시 복사'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _validateJsonOnly,
                          icon: const Icon(Icons.checklist_rounded),
                          label: const Text('JSON 검증'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _importCards,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textPrimary,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload_rounded),
                          label: Text(_isSubmitting ? '등록 중...' : 'DB 등록'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_statusMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _statusError
                              ? AppColors.error.withValues(alpha: 0.15)
                              : AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _statusMessage,
                          style: AppTextStyles.body2.copyWith(
                            color: _statusError
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ),
                    if (_lastParsedCount > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '대상 카드 수: $_lastParsedCount개',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text('등록 JSON', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Container(
                      height: 460,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _jsonController,
                        expands: true,
                        minLines: null,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: AppTextStyles.body2.copyWith(
                          fontFamily: 'monospace',
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '[{...}]',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '권장 카테고리: 외식, 카페, 교통, 생활, 디지털구독, 쇼핑, 온라인쇼핑, 편의점, 마트, 전통시장, 해외, 무이자할부, 주유, 문화, 배달앱, 기타',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

const _sampleImportJson = '''
[
  {
    "card_name": "토스 교통 플러스",
    "issuer": "토스카드",
    "annual_fee": 0,
    "annual_fee_domestic": 0,
    "annual_fee_overseas": 0,
    "image_color": "#2563EB",
    "card_image_url": "assets/cards/toss_transport_plus.png",
    "brand_options": ["국내", "Master"],
    "main_benefits": [
      "버스/지하철 10% 할인",
      "편의점 5% 할인"
    ],
    "prev_month_spend_text": "직전 1개월 30만원 이상",
    "monthly_benefit_cap": 30000,
    "base_benefit_rate": 0,
    "base_benefit_type": "discount",
    "description": "카드 라운지 참고 등록 예시",
    "tiers": [
      {
        "tier_name": "30만원 이상",
        "min_prev_spend": 300000,
        "max_prev_spend": 699999,
        "tier_order": 1,
        "rules": [
          {
            "category": "교통",
            "benefit_type": "discount",
            "benefit_rate": 10,
            "max_benefit_amount": 12000,
            "priority": 1
          },
          {
            "category": "편의점",
            "benefit_type": "discount",
            "benefit_rate": 5,
            "max_benefit_amount": 5000,
            "priority": 2
          }
        ]
      },
      {
        "tier_name": "70만원 이상",
        "min_prev_spend": 700000,
        "max_prev_spend": null,
        "tier_order": 2,
        "rules": [
          {
            "category": "교통",
            "benefit_type": "discount",
            "benefit_rate": 15,
            "max_benefit_amount": 20000,
            "priority": 1
          }
        ]
      }
    ]
  }
]
''';
