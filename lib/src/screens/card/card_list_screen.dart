import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../components/card_thumbnail.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/user_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/card_provider.dart';
import 'card_add_screen.dart';

class CardListScreen extends ConsumerStatefulWidget {
  const CardListScreen({super.key});

  @override
  ConsumerState<CardListScreen> createState() => _CardListScreenState();
}

class _CardListScreenState extends ConsumerState<CardListScreen> {
  bool _isOrderEditMode = false;
  bool _isApplyingOrder = false;
  List<UserCard> _draftCards = [];

  void _startOrderEdit(List<UserCard> cards) {
    setState(() {
      _isOrderEditMode = true;
      _draftCards = List<UserCard>.from(cards);
    });
  }

  void _cancelOrderEdit() {
    setState(() {
      _isOrderEditMode = false;
      _draftCards = [];
    });
  }

  void _reorderDraftCards(int oldIndex, int newIndex) {
    setState(() {
      final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
      final moved = _draftCards.removeAt(oldIndex);
      _draftCards.insert(targetIndex, moved);
    });
  }

  Future<void> _applyOrderEdit() async {
    if (_isApplyingOrder || _draftCards.isEmpty) return;
    setState(() => _isApplyingOrder = true);

    try {
      await ref
          .read(userCardsProvider.notifier)
          .saveCardOrder(_draftCards.map((e) => e.id).toList());
      if (!mounted) return;
      setState(() {
        _isOrderEditMode = false;
        _draftCards = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('카드 순서가 적용되었습니다'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('순서 적용 실패: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isApplyingOrder = false);
    }
  }

  Future<void> _deleteCard(UserCard card) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('카드 삭제', style: AppTextStyles.heading3),
        content: Text(
          '${card.displayName}을(를) 삭제하시겠습니까?\n관련 소비 내역도 함께 삭제됩니다.',
          style: AppTextStyles.body2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      ref.read(userCardsProvider.notifier).removeCard(card.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userCards = ref.watch(userCardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: null,
        actions: [
          if (_isOrderEditMode) ...[
            TextButton(
              onPressed: _isApplyingOrder ? null : _cancelOrderEdit,
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: _isApplyingOrder ? null : _applyOrderEdit,
              child: _isApplyingOrder
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('적용'),
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.settings_rounded),
              tooltip: '카드 순서/삭제 설정',
              onPressed: () => userCards.whenData(_startOrderEdit),
            ),
        ],
      ),
      body: userCards.when(
        data: (cards) {
          if (cards.isEmpty) {
            final isGuest = ref.watch(isGuestModeProvider);
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.credit_card_rounded,
                    size: 64,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '등록된 카드가 없습니다',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isGuest
                        ? '회원가입하고 카드를 추가해보세요'
                        : '지금 바로 카드를 추가해보세요',
                    style: AppTextStyles.caption,
                  ),
                  if (!isGuest) ...[
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => const CardAddScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_card_rounded),
                      label: const Text('카드 추가하기'),
                    ),
                  ],
                ],
              ),
            );
          }

          if (_isOrderEditMode) {
            final cardsToEdit = _draftCards.isEmpty ? cards : _draftCards;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.drag_indicator_rounded,
                        size: 16,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '순서 조정/삭제 후 우측 상단 적용을 눌러주세요',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    buildDefaultDragHandles: false,
                    itemCount: cardsToEdit.length,
                    onReorder: _reorderDraftCards,
                    itemBuilder: (context, index) {
                      return _buildCardTile(
                        card: cardsToEdit[index],
                        index: index,
                        editMode: true,
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              return _buildCardTile(
                card: cards[index],
                index: index,
                editMode: false,
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) =>
            Center(child: Text('오류: $error', style: AppTextStyles.body2)),
      ),
    );
  }

  Widget _buildCardTile({
    required UserCard card,
    required int index,
    required bool editMode,
  }) {
    final cardColor = _parseColor(card.cardMaster?.imageColor ?? '#7C83FD');

    return Container(
      key: ValueKey(card.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: editMode ? null : () => context.push('/card/${card.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CardThumbnail(
                  cardMaster: card.cardMaster,
                  width: 48,
                  height: 48,
                  borderRadius: 12,
                  iconSize: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.displayName,
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (card.cardMaster != null)
                        Text(
                          '${card.cardMaster!.issuer} · ${card.cardMaster!.cardName}',
                          style: AppTextStyles.caption,
                        ),
                    ],
                  ),
                ),
                if (editMode) ...[
                  ReorderableDragStartListener(
                    index: index,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                    tooltip: '카드 삭제',
                    onPressed: () => _deleteCard(card),
                  ),
                ] else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textHint,
                  ),
              ],
            ),
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
