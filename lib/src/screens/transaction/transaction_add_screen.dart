import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/categories.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/transaction.dart';
import '../../models/user_card.dart';
import '../../providers/card_provider.dart';
import '../../providers/transaction_provider.dart';

final _dateFormat = DateFormat('yyyy.MM.dd');

class TransactionAddScreen extends ConsumerStatefulWidget {
  const TransactionAddScreen({super.key});

  @override
  ConsumerState<TransactionAddScreen> createState() =>
      _TransactionAddScreenState();
}

class _TransactionAddScreenState extends ConsumerState<TransactionAddScreen> {
  static const int _transactionsPageSize = 6;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  final _cardPageController = PageController(viewportFraction: 0.92);
  final _categoryPageController = PageController(viewportFraction: 0.56);

  String? _selectedCategory;
  UserCard? _selectedCard;
  DateTime _selectedDate = DateTime.now();
  DateTime _historySelectedDate = DateTime.now();
  bool _isSubmitting = false;
  int _visibleTransactionCount = _transactionsPageSize;
  int _selectedCardPage = 0;
  int _selectedCategoryPage = 0;

  @override
  void initState() {
    super.initState();
    _selectedCategory = Categories.all.first.key;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    _cardPageController.dispose();
    _categoryPageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2, 1, 1), // 2년 전부터
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _ensureSelectedCard(List<UserCard> cards) {
    if (cards.isEmpty) return;

    final current = _selectedCard;
    final currentIndex = current == null
        ? -1
        : cards.indexWhere((card) => card.id == current.id);
    if (currentIndex >= 0) {
      if (currentIndex != _selectedCardPage) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _selectedCardPage = currentIndex);
          if (_cardPageController.hasClients) {
            _cardPageController.jumpToPage(currentIndex);
          }
        });
      }
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedCardPage = 0;
        _selectedCard = cards.first;
      });
      if (_cardPageController.hasClients) {
        _cardPageController.jumpToPage(0);
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('카테고리를 선택해주세요'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    if (_selectedCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('카드를 선택해주세요'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    FocusScope.of(context).unfocus();

    try {
      final amountText = _amountController.text
          .replaceAll(',', '')
          .replaceAll('원', '');
      final amount = int.parse(amountText);

      await ref
          .read(monthlyTransactionsProvider.notifier)
          .addTransaction(
            userCardId: _selectedCard!.id,
            amount: amount,
            category: _selectedCategory!,
            memo: _memoController.text.isNotEmpty ? _memoController.text : null,
            transactionDate: _selectedDate,
          );

      if (mounted) {
        // 입력 폼 초기화
        _amountController.clear();
        _memoController.clear();
        setState(() {
          _selectedDate = DateTime.now();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('소비 내역이 등록되었습니다'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('등록 실패: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<bool> _confirmDeleteTransaction(Transaction tx) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text('소비 내역 삭제', style: AppTextStyles.heading3),
          content: Text(
            '${tx.category} ${NumberFormat('#,###').format(tx.amount)}원 내역을 삭제할까요?',
            style: AppTextStyles.body2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('삭제', style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<bool> _handleDeleteTransaction(Transaction tx) async {
    try {
      await ref
          .read(monthlyTransactionsProvider.notifier)
          .deleteTransaction(tx.id);
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('소비 내역을 삭제했습니다'),
          backgroundColor: AppColors.success,
        ),
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e'), backgroundColor: AppColors.error),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userCards = ref.watch(userCardsProvider);
    final recentTransactions = ref.watch(monthlyTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('소비 입력')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 금액 입력
              Text('금액', style: AppTextStyles.label),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: AppTextStyles.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ThousandsSeparatorInputFormatter(),
                ],
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: AppTextStyles.number.copyWith(
                    color: AppColors.textHint,
                  ),
                  suffixText: '원',
                  suffixStyle: AppTextStyles.body1,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '금액을 입력해주세요';
                  }
                  final parsed = int.tryParse(value.replaceAll(',', ''));
                  if (parsed == null || parsed <= 0) {
                    return '올바른 금액을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // 날짜 선택
              Text('날짜', style: AppTextStyles.label),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _dateFormat.format(_selectedDate),
                        style: AppTextStyles.body1,
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textHint,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 카드 선택
              Text('카드', style: AppTextStyles.label),
              const SizedBox(height: 8),
              userCards.when(
                data: (cards) {
                  if (cards.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '등록된 카드가 없습니다. 카드 탭에서 추가해주세요.',
                        style: AppTextStyles.body2,
                      ),
                    );
                  }
                  _ensureSelectedCard(cards);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 92,
                        child: PageView.builder(
                          controller: _cardPageController,
                          itemCount: cards.length,
                          onPageChanged: (index) {
                            setState(() {
                              _selectedCardPage = index;
                              _selectedCard = cards[index];
                            });
                          },
                          itemBuilder: (context, index) {
                            final card = cards[index];
                            final isSelected = index == _selectedCardPage;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.card
                                    : AppColors.inputFill,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.credit_card_rounded,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      card.displayName,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.body1.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      if (cards.length > 1) ...[
                        const SizedBox(height: 8),
                        Text(
                          '좌우로 스와이프해서 카드 선택 (${_selectedCardPage + 1}/${cards.length})',
                          style: AppTextStyles.caption,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  );
                },
                loading: () =>
                    const LinearProgressIndicator(color: AppColors.primary),
                error: (e, _) => Text('오류: $e'),
              ),

              const SizedBox(height: 24),

              // 카테고리 선택
              Text('카테고리', style: AppTextStyles.label),
              const SizedBox(height: 8),
              SizedBox(
                height: 88,
                child: PageView.builder(
                  controller: _categoryPageController,
                  itemCount: Categories.all.length,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedCategoryPage = index;
                      _selectedCategory = Categories.all[index].key;
                    });
                  },
                  itemBuilder: (context, index) {
                    final category = Categories.all[index];
                    final isSelected = index == _selectedCategoryPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? category.color.withValues(alpha: 0.2)
                            : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? category.color
                              : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            category.icon,
                            size: 18,
                            color: isSelected
                                ? category.color
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              category.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body2.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? category.color
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '좌우로 스와이프해서 카테고리 선택 (${_selectedCategoryPage + 1}/${Categories.all.length})',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // 메모
              Text('메모 (선택)', style: AppTextStyles.label),
              const SizedBox(height: 8),
              TextFormField(
                controller: _memoController,
                style: AppTextStyles.body1,
                maxLines: 2,
                decoration: const InputDecoration(hintText: '어디서 사용했나요?'),
              ),

              const SizedBox(height: 32),

              // 등록 버튼
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textPrimary,
                        ),
                      )
                    : const Text('소비 등록'),
              ),

              const SizedBox(height: 32),

              // 날짜별 소비 내역
              Text('소비 내역 날짜 선택', style: AppTextStyles.heading3),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.primary,
                      onPrimary: AppColors.textPrimary,
                      surface: AppColors.card,
                      onSurface: AppColors.textPrimary,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                    ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: _historySelectedDate,
                    firstDate: DateTime(DateTime.now().year - 2, 1, 1),
                    lastDate: DateTime.now(),
                    currentDate: DateTime.now(),
                    onDateChanged: (picked) {
                      setState(() {
                        _historySelectedDate = picked;
                        _visibleTransactionCount = _transactionsPageSize;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${_dateFormat.format(_historySelectedDate)} 소비 내역',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 12),

              recentTransactions.when(
                data: (transactions) {
                  final dailyTransactions = transactions
                      .where(
                        (tx) => _isSameDate(
                          tx.transactionDate,
                          _historySelectedDate,
                        ),
                      )
                      .toList();
                  if (dailyTransactions.isEmpty) {
                    final isToday = _isSameDate(
                      _historySelectedDate,
                      DateTime.now(),
                    );
                    return Text(
                      isToday
                          ? '오늘은 절약했어요. 소비 내역이 없어요.'
                          : '${_dateFormat.format(_historySelectedDate)}은 절약했어요. 소비 내역이 없어요.',
                      style: AppTextStyles.body2,
                    );
                  }
                  final displayCount =
                      _visibleTransactionCount > dailyTransactions.length
                      ? dailyTransactions.length
                      : _visibleTransactionCount;
                  final display = dailyTransactions.take(displayCount).toList();
                  final hasMore = dailyTransactions.length > displayCount;
                  final canCollapse =
                      displayCount > _transactionsPageSize &&
                      dailyTransactions.length > _transactionsPageSize;

                  final transactionWidgets = display.map<Widget>((tx) {
                    return Dismissible(
                      key: ValueKey(tx.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        final confirmed = await _confirmDeleteTransaction(tx);
                        if (!confirmed) return false;
                        return _handleDeleteTransaction(tx);
                      },
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.error,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.category,
                                    style: AppTextStyles.body2.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (tx.memo != null)
                                    Text(
                                      tx.memo!,
                                      style: AppTextStyles.caption,
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${NumberFormat('#,###').format(tx.amount)}원',
                                  style: AppTextStyles.body1.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _dateFormat.format(tx.transactionDate),
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () async {
                                final confirmed =
                                    await _confirmDeleteTransaction(tx);
                                if (!confirmed) return;
                                await _handleDeleteTransaction(tx);
                              },
                              tooltip: '삭제',
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList();

                  if (hasMore || canCollapse) {
                    transactionWidgets.add(const SizedBox(height: 8));
                    transactionWidgets.add(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (hasMore)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  final nextCount =
                                      _visibleTransactionCount +
                                      _transactionsPageSize;
                                  _visibleTransactionCount =
                                      nextCount > dailyTransactions.length
                                      ? dailyTransactions.length
                                      : nextCount;
                                });
                              },
                              child: Text(
                                '더 보기 (${dailyTransactions.length - displayCount}개 남음)',
                              ),
                            ),
                          if (hasMore && canCollapse) const SizedBox(width: 8),
                          if (canCollapse)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _visibleTransactionCount =
                                      _transactionsPageSize;
                                });
                              },
                              child: const Text('접기'),
                            ),
                        ],
                      ),
                    );
                  }

                  return Column(children: transactionWidgets);
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Text('오류: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 천 단위 콤마 자동 포맷터
class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static final _formatter = NumberFormat('#,###', 'ko_KR');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final number = int.tryParse(newValue.text.replaceAll(',', ''));
    if (number == null) return oldValue;

    final formatted = _formatter.format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
