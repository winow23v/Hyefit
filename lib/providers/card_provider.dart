import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_master.dart';
import '../models/user_card.dart';
import '../services/card_service.dart';
import '../services/demo_data_service.dart';
import 'auth_provider.dart';

final cardServiceProvider = Provider<CardService>((ref) => CardService());

/// 시스템 카드 목록 (등록 가능한 전체 카드)
final allCardsProvider = FutureProvider<List<CardMaster>>((ref) async {
  final isGuest = ref.watch(isGuestModeProvider);
  if (isGuest) return DemoDataService.cards;

  final cardService = ref.watch(cardServiceProvider);
  return cardService.getAllCards();
});

/// 사용자 보유 카드 목록
final userCardsProvider =
    AsyncNotifierProvider<UserCardsNotifier, List<UserCard>>(
  UserCardsNotifier.new,
);

class UserCardsNotifier extends AsyncNotifier<List<UserCard>> {
  @override
  Future<List<UserCard>> build() async {
    final isGuest = ref.watch(isGuestModeProvider);
    if (isGuest) return DemoDataService.userCards;

    final user = ref.watch(currentUserProvider);
    if (user == null) return [];
    final cardService = ref.watch(cardServiceProvider);
    return cardService.getUserCards(user.id);
  }

  Future<void> addCard({
    required String cardMasterId,
    String? nickname,
  }) async {
    final isGuest = ref.read(isGuestModeProvider);
    if (isGuest) return; // 게스트는 추가 불가

    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final cardService = ref.read(cardServiceProvider);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await cardService.addUserCard(
        userId: user.id,
        cardMasterId: cardMasterId,
        nickname: nickname,
      );
      return cardService.getUserCards(user.id);
    });
  }

  Future<void> updateNickname({
    required String userCardId,
    required String nickname,
  }) async {
    final isGuest = ref.read(isGuestModeProvider);
    if (isGuest) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final cardService = ref.read(cardServiceProvider);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await cardService.updateUserCardNickname(
        userCardId: userCardId,
        nickname: nickname,
      );
      return cardService.getUserCards(user.id);
    });
  }

  Future<void> removeCard(String userCardId) async {
    final isGuest = ref.read(isGuestModeProvider);
    if (isGuest) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final cardService = ref.read(cardServiceProvider);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await cardService.removeUserCard(userCardId);
      return cardService.getUserCards(user.id);
    });
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}
