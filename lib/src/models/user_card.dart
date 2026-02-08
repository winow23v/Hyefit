import 'card_master.dart';

class UserCard {
  final String id;
  final String userId;
  final String cardMasterId;
  final String? nickname;
  final int displayOrder;
  final DateTime createdAt;
  final CardMaster? cardMaster;

  const UserCard({
    required this.id,
    required this.userId,
    required this.cardMasterId,
    this.nickname,
    this.displayOrder = 0,
    required this.createdAt,
    this.cardMaster,
  });

  factory UserCard.fromJson(Map<String, dynamic> json) {
    return UserCard(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cardMasterId: json['card_master_id'] as String,
      nickname: json['nickname'] as String?,
      displayOrder: (json['display_order'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      cardMaster: json['card_master'] != null
          ? CardMaster.fromJson(json['card_master'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'card_master_id': cardMasterId,
      'nickname': nickname,
      'display_order': displayOrder,
    };
  }

  String get displayName {
    final name = nickname;
    final cardName = cardMaster?.cardName;
    if (name != null && cardName != null) return '$name / $cardName';
    return name ?? cardName ?? '카드';
  }
}
