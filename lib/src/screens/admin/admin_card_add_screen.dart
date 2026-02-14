import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/categories.dart';
import '../../providers/card_provider.dart';
import '../../components/category_chip.dart';

class AdminCardAddScreen extends ConsumerStatefulWidget {
  const AdminCardAddScreen({super.key});

  @override
  ConsumerState<AdminCardAddScreen> createState() => _AdminCardAddScreenState();
}

class _AdminCardAddScreenState extends ConsumerState<AdminCardAddScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1: 카드 기본 정보
  final _nameController = TextEditingController();
  final _issuerController = TextEditingController();
  final _feeDomesticController = TextEditingController(text: '0');
  final _feeOverseasController = TextEditingController(text: '0');
  final _brandsController = TextEditingController(text: '국내, Master');
  final _mainBenefitsController = TextEditingController();
  final _prevMonthSpendController = TextEditingController();
  final _cardImageUrlController = TextEditingController();
  final _benefitCapController = TextEditingController(text: '10000');
  final _baseRateController = TextEditingController(text: '0');
  final _descriptionController = TextEditingController();
  String _selectedColor = '#7C83FD';
  String _baseBenefitType = 'cashback';

  // Step 2: Tier 목록
  final List<_TierData> _tiers = [];

  static const _colorOptions = [
    '#7C83FD',
    '#2563EB',
    '#DC2626',
    '#7C3AED',
    '#059669',
    '#D97706',
    '#E11D48',
    '#6366F1',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    _feeDomesticController.dispose();
    _feeOverseasController.dispose();
    _brandsController.dispose();
    _mainBenefitsController.dispose();
    _prevMonthSpendController.dispose();
    _cardImageUrlController.dispose();
    _benefitCapController.dispose();
    _baseRateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    try {
      final cardJson = _buildCardJson();
      final cardService = ref.read(cardServiceProvider);
      await cardService.importCardFromJson(cardJson);

      ref.invalidate(allCardsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('카드가 추가되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('추가 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Map<String, dynamic> _buildCardJson() {
    return {
      'card_name': _nameController.text.trim(),
      'issuer': _issuerController.text.trim(),
      'annual_fee': int.parse(_feeDomesticController.text.replaceAll(',', '')),
      'annual_fee_domestic': int.parse(
        _feeDomesticController.text.replaceAll(',', ''),
      ),
      'annual_fee_overseas': int.parse(
        _feeOverseasController.text.replaceAll(',', ''),
      ),
      'image_color': _selectedColor,
      'card_image_url': _cardImageUrlController.text.trim(),
      'brand_options': _splitLinesOrComma(_brandsController.text),
      'main_benefits': _splitLinesOrComma(_mainBenefitsController.text),
      'prev_month_spend_text': _prevMonthSpendController.text.trim(),
      'monthly_benefit_cap': int.parse(
        _benefitCapController.text.replaceAll(',', ''),
      ),
      'base_benefit_rate': double.parse(_baseRateController.text),
      'base_benefit_type': _baseBenefitType,
      'description': _descriptionController.text.trim(),
      'tiers': _tiers.map((tier) => tier.toJson()).toList(),
    };
  }

  List<String> _splitLinesOrComma(String raw) {
    return raw
        .split(RegExp(r'[\n,|/]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 카드 추가'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildCurrentStepContent(),
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.cardLight, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _stepDot(0, '기본정보'),
          _stepLine(0),
          _stepDot(1, 'Tier'),
          _stepLine(1),
          _stepDot(2, '확인'),
        ],
      ),
    );
  }

  Widget _stepDot(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.primary
                : isActive
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.cardLight,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive || isCompleted
                  ? AppColors.primary
                  : AppColors.cardLight,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppColors.primary : AppColors.textHint,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(int step) {
    final isCompleted = _currentStep > step;
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isCompleted ? AppColors.primary : AppColors.cardLight,
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1BasicInfo();
      case 1:
        return _buildStep2Tiers();
      case 2:
        return _buildStep3Review();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1BasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('카드 기본 정보', style: AppTextStyles.heading3),
        const SizedBox(height: 20),

        TextFormField(
          controller: _nameController,
          style: AppTextStyles.body1,
          decoration: const InputDecoration(
            labelText: '카드 이름 *',
            hintText: '예: Deep Dream 체크',
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _issuerController,
          style: AppTextStyles.body1,
          decoration: const InputDecoration(
            labelText: '카드사 *',
            hintText: '예: 신한카드',
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _feeDomesticController,
                style: AppTextStyles.body1,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '국내 연회비',
                  suffixText: '원',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _feeOverseasController,
                style: AppTextStyles.body1,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '해외 연회비',
                  suffixText: '원',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _brandsController,
          style: AppTextStyles.body1,
          decoration: const InputDecoration(
            labelText: '브랜드',
            hintText: '예: 국내, Master, JCB',
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _cardImageUrlController,
          style: AppTextStyles.body1,
          decoration: const InputDecoration(
            labelText: '카드 이미지 URL (선택)',
            hintText: 'https://... 또는 assets/cards/파일명.png',
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _mainBenefitsController,
          style: AppTextStyles.body1,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: '주요혜택 요약',
            hintText: '줄바꿈/쉼표로 여러 줄 입력',
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _prevMonthSpendController,
          style: AppTextStyles.body1,
          decoration: const InputDecoration(
            labelText: '전월실적 문구',
            hintText: '예: 직전 1개월 30만원 이상',
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _benefitCapController,
          style: AppTextStyles.body1,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: '월 최대 혜택',
            suffixText: '원',
          ),
        ),
        const SizedBox(height: 16),

        TextFormField(
          controller: _baseRateController,
          style: AppTextStyles.body1,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: '기본 혜택률',
            suffixText: '%',
          ),
        ),
        const SizedBox(height: 16),

        Text('기본 혜택 유형', style: AppTextStyles.label),
        const SizedBox(height: 8),
        Row(
          children: [
            _typeChip(
              label: '캐시백',
              isSelected: _baseBenefitType == 'cashback',
              onTap: () => setState(() => _baseBenefitType = 'cashback'),
            ),
            const SizedBox(width: 8),
            _typeChip(
              label: '포인트',
              isSelected: _baseBenefitType == 'point',
              onTap: () => setState(() => _baseBenefitType = 'point'),
            ),
            const SizedBox(width: 8),
            _typeChip(
              label: '할인',
              isSelected: _baseBenefitType == 'discount',
              onTap: () => setState(() => _baseBenefitType = 'discount'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Text('카드 색상', style: AppTextStyles.label),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colorOptions.map((hex) {
            final color = _parseColor(hex);
            final isSelected = _selectedColor == hex;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = hex),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: AppColors.textPrimary, width: 3)
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        TextFormField(
          controller: _descriptionController,
          style: AppTextStyles.body1,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: '카드 설명',
            hintText: '예: 외식/편의점/카페 10% 적립',
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Tiers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('혜택 Tier 설정', style: AppTextStyles.heading3),
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
              ),
              onPressed: _addTier,
              tooltip: 'Tier 추가',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('전월 실적 구간별로 다른 혜택을 설정할 수 있습니다', style: AppTextStyles.body2),
        const SizedBox(height: 20),

        if (_tiers.isEmpty)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.layers_rounded, size: 64, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('Tier를 추가해주세요', style: AppTextStyles.body2),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _addTier,
                  icon: const Icon(Icons.add),
                  label: const Text('첫 Tier 추가'),
                ),
              ],
            ),
          )
        else
          ..._tiers.asMap().entries.map((entry) {
            final index = entry.key;
            final tier = entry.value;
            return _TierCard(
              tier: tier,
              tierNumber: index + 1,
              onDelete: () => _removeTier(index),
              onAddRule: () => _addRuleToTier(index),
              onDeleteRule: (ruleIndex) =>
                  _removeRuleFromTier(index, ruleIndex),
            );
          }),
      ],
    );
  }

  Widget _buildStep3Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('최종 확인', style: AppTextStyles.heading3),
        const SizedBox(height: 20),

        _reviewSection('카드 정보', [
          _reviewItem('이름', _nameController.text),
          _reviewItem('카드사', _issuerController.text),
          _reviewItem(
            '연회비',
            '국내 ${_feeDomesticController.text}원, 해외 ${_feeOverseasController.text}원',
          ),
          _reviewItem('브랜드', _brandsController.text),
          _reviewItem('주요혜택', _mainBenefitsController.text),
          _reviewItem('전월실적', _prevMonthSpendController.text),
          _reviewItem('월 최대 혜택', '${_benefitCapController.text}원'),
          _reviewItem(
            '기본 혜택',
            '${_baseRateController.text}% ($_baseBenefitType)',
          ),
        ]),

        const SizedBox(height: 24),

        _reviewSection('Tier 및 혜택', [
          ..._tiers.asMap().entries.expand((entry) {
            final tierNum = entry.key + 1;
            final tier = entry.value;
            return [
              _reviewItem(
                'Tier $tierNum',
                tier.tierName.isEmpty
                    ? '${tier.minPrevSpend}원 이상'
                    : tier.tierName,
              ),
              ...tier.rules.asMap().entries.map((ruleEntry) {
                final rule = ruleEntry.value;
                final cat = Categories.findByKey(rule.category);
                return Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _reviewItem(
                    '  • ${cat.label}',
                    '${rule.benefitRate}% (최대 ${rule.maxBenefitAmount}원)',
                  ),
                );
              }),
            ];
          }),
        ]),
      ],
    );
  }

  Widget _reviewSection(String title, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  Widget _reviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: AppTextStyles.body2)),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body2.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardLight, width: 1)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                child: const Text('이전'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleNextOrSubmit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textPrimary,
                      ),
                    )
                  : Text(_currentStep == 2 ? '카드 추가' : '다음'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNextOrSubmit() {
    if (_currentStep == 0) {
      if (_nameController.text.trim().isEmpty ||
          _issuerController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('카드 이름과 카드사를 입력해주세요'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 1) {
      if (_tiers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('최소 1개의 Tier를 추가해주세요'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      setState(() => _currentStep++);
    } else if (_currentStep == 2) {
      _handleSubmit();
    }
  }

  void _addTier() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final tierNameController = TextEditingController();
        final minSpendController = TextEditingController(text: '300000');
        final maxSpendController = TextEditingController();

        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Tier 추가', style: AppTextStyles.heading3),
                const SizedBox(height: 20),
                TextFormField(
                  controller: tierNameController,
                  style: AppTextStyles.body1,
                  decoration: const InputDecoration(
                    labelText: 'Tier 이름 (선택)',
                    hintText: '예: 30만원 이상',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: minSpendController,
                  style: AppTextStyles.body1,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: '최소 전월 실적',
                    suffixText: '원',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: maxSpendController,
                  style: AppTextStyles.body1,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: '최대 전월 실적 (비워두면 무제한)',
                    suffixText: '원',
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _tiers.add(
                        _TierData(
                          tierName: tierNameController.text,
                          minPrevSpend: int.parse(minSpendController.text),
                          maxPrevSpend: maxSpendController.text.isEmpty
                              ? null
                              : int.parse(maxSpendController.text),
                        ),
                      );
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('추가'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removeTier(int index) {
    setState(() => _tiers.removeAt(index));
  }

  void _addRuleToTier(int tierIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String? selectedCategory;
        final rateController = TextEditingController(text: '5');
        final maxBenefitController = TextEditingController(text: '10000');
        String benefitType = 'cashback';

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('혜택 규칙 추가', style: AppTextStyles.heading3),
                    const SizedBox(height: 20),
                    Text('카테고리', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    CategoryChipGroup(
                      selectedKey: selectedCategory,
                      onSelected: (key) {
                        setSheetState(() => selectedCategory = key);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('혜택 유형', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _typeChip(
                          label: '캐시백',
                          isSelected: benefitType == 'cashback',
                          onTap: () =>
                              setSheetState(() => benefitType = 'cashback'),
                        ),
                        const SizedBox(width: 8),
                        _typeChip(
                          label: '포인트',
                          isSelected: benefitType == 'point',
                          onTap: () =>
                              setSheetState(() => benefitType = 'point'),
                        ),
                        const SizedBox(width: 8),
                        _typeChip(
                          label: '할인',
                          isSelected: benefitType == 'discount',
                          onTap: () =>
                              setSheetState(() => benefitType = 'discount'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: rateController,
                      style: AppTextStyles.body1,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '혜택률',
                        suffixText: '%',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: maxBenefitController,
                      style: AppTextStyles.body1,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: '월 최대 혜택',
                        suffixText: '원',
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: selectedCategory == null
                          ? null
                          : () {
                              setState(() {
                                _tiers[tierIndex].rules.add(
                                  _RuleData(
                                    category: selectedCategory!,
                                    benefitType: benefitType,
                                    benefitRate: double.parse(
                                      rateController.text,
                                    ),
                                    maxBenefitAmount: int.parse(
                                      maxBenefitController.text,
                                    ),
                                  ),
                                );
                              });
                              Navigator.pop(ctx);
                            },
                      child: const Text('추가'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _removeRuleFromTier(int tierIndex, int ruleIndex) {
    setState(() => _tiers[tierIndex].rules.removeAt(ruleIndex));
  }

  Widget _typeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.cardLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('FF');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

class _TierData {
  String tierName;
  int minPrevSpend;
  int? maxPrevSpend;
  List<_RuleData> rules;

  _TierData({
    required this.tierName,
    required this.minPrevSpend,
    this.maxPrevSpend,
    List<_RuleData>? rules,
  }) : rules = rules ?? [];

  Map<String, dynamic> toJson() {
    return {
      'tier_name': tierName,
      'min_prev_spend': minPrevSpend,
      'max_prev_spend': maxPrevSpend,
      'rules': rules.map((r) => r.toJson()).toList(),
    };
  }
}

class _RuleData {
  String category;
  String benefitType;
  double benefitRate;
  int maxBenefitAmount;

  _RuleData({
    required this.category,
    required this.benefitType,
    required this.benefitRate,
    required this.maxBenefitAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'benefit_type': benefitType,
      'benefit_rate': benefitRate,
      'max_benefit_amount': maxBenefitAmount,
    };
  }
}

class _TierCard extends StatelessWidget {
  final _TierData tier;
  final int tierNumber;
  final VoidCallback onDelete;
  final VoidCallback onAddRule;
  final void Function(int ruleIndex) onDeleteRule;

  const _TierCard({
    required this.tier,
    required this.tierNumber,
    required this.onDelete,
    required this.onAddRule,
    required this.onDeleteRule,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.layers_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.tierName.isEmpty
                            ? 'Tier $tierNumber'
                            : tier.tierName,
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        '${tier.minPrevSpend}원 이상${tier.maxPrevSpend != null ? ' ~ ${tier.maxPrevSpend}원' : ''}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: onAddRule,
                  tooltip: '규칙 추가',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Tier 삭제',
                ),
              ],
            ),
          ),

          if (tier.rules.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text('혜택 규칙을 추가해주세요', style: AppTextStyles.body2),
              ),
            )
          else
            ...tier.rules.asMap().entries.map((entry) {
              final index = entry.key;
              final rule = entry.value;
              final cat = Categories.findByKey(rule.category);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.cardLight, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(cat.icon, size: 18, color: cat.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cat.label, style: AppTextStyles.body2),
                          Text(
                            '${rule.benefitType} ${rule.benefitRate}% (최대 ${rule.maxBenefitAmount}원)',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onDeleteRule(index),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
