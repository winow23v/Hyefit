import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/card_provider.dart';

class AdminCardAddScreen extends ConsumerStatefulWidget {
  const AdminCardAddScreen({super.key});

  @override
  ConsumerState<AdminCardAddScreen> createState() =>
      _AdminCardAddScreenState();
}

class _AdminCardAddScreenState extends ConsumerState<AdminCardAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _issuerController = TextEditingController();
  final _feeController = TextEditingController(text: '0');
  String _selectedColor = '#7C83FD';
  bool _isSubmitting = false;

  static const _colorOptions = [
    '#7C83FD', '#2563EB', '#DC2626', '#7C3AED',
    '#059669', '#D97706', '#E11D48', '#6366F1',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final cardService = ref.read(cardServiceProvider);
      await cardService.addCardMaster(
        cardName: _nameController.text.trim(),
        issuer: _issuerController.text.trim(),
        annualFee: int.parse(_feeController.text.replaceAll(',', '')),
        imageColor: _selectedColor,
      );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('카드 정보', style: AppTextStyles.heading3),
              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                style: AppTextStyles.body1,
                decoration: const InputDecoration(
                  labelText: '카드 이름',
                  hintText: '예: 신한 Deep Dream',
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? '카드 이름을 입력해주세요' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _issuerController,
                style: AppTextStyles.body1,
                decoration: const InputDecoration(
                  labelText: '카드사',
                  hintText: '예: 신한카드',
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? '카드사를 입력해주세요' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _feeController,
                style: AppTextStyles.body1,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '연회비',
                  suffixText: '원',
                ),
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
                            ? Border.all(
                                color: AppColors.textPrimary, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.textPrimary),
                      )
                    : const Text('카드 추가'),
              ),
            ],
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
