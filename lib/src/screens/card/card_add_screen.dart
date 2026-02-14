import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../components/card_thumbnail.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/card_master.dart';
import '../../providers/card_provider.dart';

class CardAddScreen extends ConsumerStatefulWidget {
  const CardAddScreen({super.key});

  @override
  ConsumerState<CardAddScreen> createState() => _CardAddScreenState();
}

class _CardAddScreenState extends ConsumerState<CardAddScreen> {
  final _searchController = TextEditingController();
  final _nicknameController = TextEditingController();
  String _searchQuery = '';
  CardMaster? _selectedCard;

  @override
  void dispose() {
    _searchController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  List<CardMaster> _filterCards(List<CardMaster> cards) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return [];
    return cards.where((card) {
      return card.cardName.toLowerCase().contains(query) ||
          card.issuer.toLowerCase().contains(query) ||
          card.description.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _addCard(CardMaster card, String? nickname) async {
    try {
      await ref
          .read(userCardsProvider.notifier)
          .addCard(
            cardMasterId: card.id,
            cardName: card.cardName,
            issuer: card.issuer,
            nickname: nickname,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('카드를 추가했습니다'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString();
      final message = raw.contains('카드 마스터에 없습니다')
          ? '카드 목록을 새로고침한 뒤 다시 시도해주세요.'
          : '카드 추가 실패: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  void _showNicknameDialog(CardMaster card) {
    _nicknameController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('카드 별명', style: AppTextStyles.heading3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${card.issuer} ${card.cardName}', style: AppTextStyles.body2),
            const SizedBox(height: 16),
            TextField(
              controller: _nicknameController,
              style: AppTextStyles.body1,
              decoration: const InputDecoration(
                labelText: '별명 (선택)',
                hintText: '예: 월급카드, 교통카드',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _addCard(
                card,
                _nicknameController.text.isNotEmpty
                    ? _nicknameController.text
                    : null,
              );
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allCards = ref.watch(allCardsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('카드 검색'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: AppTextStyles.body1,
              decoration: InputDecoration(
                hintText: '카드명, 카드사, 혜택으로 검색',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textHint,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: AppColors.textHint,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: allCards.when(
              data: (cards) {
                final query = _searchQuery.trim();
                if (query.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 48,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 12),
                        Text('원하는 카드를 검색해주세요', style: AppTextStyles.body2),
                        const SizedBox(height: 4),
                        Text(
                          '카드명, 카드사, 혜택 키워드로 찾을 수 있어요',
                          style: AppTextStyles.body2,
                        ),
                      ],
                    ),
                  );
                }

                final filtered = _filterCards(cards);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 12),
                        Text('"$query" 카드는 없습니다', style: AppTextStyles.body2),
                        const SizedBox(height: 4),
                        Text('다른 검색어로 다시 시도해주세요', style: AppTextStyles.caption),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final card = filtered[index];
                    final isSelected = _selectedCard?.id == card.id;
                    final cardColor = _parseColor(card.imageColor);

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedCard = card);
                        _showNicknameDialog(card);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : cardColor.withValues(alpha: 0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            CardThumbnail(
                              cardMaster: card,
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
                                    card.cardName,
                                    style: AppTextStyles.body1.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    card.issuer,
                                    style: AppTextStyles.caption,
                                  ),
                                  if (card.description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      card.description,
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.primary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.add_circle_outline_rounded,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textHint,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) =>
                  Center(child: Text('오류: $e', style: AppTextStyles.body2)),
            ),
          ),
        ],
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
