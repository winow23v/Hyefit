class CardMaster {
  final String id;
  final String cardName;
  final String issuer;
  final int annualFee;
  final String imageColor;
  final DateTime createdAt;

  const CardMaster({
    required this.id,
    required this.cardName,
    required this.issuer,
    required this.annualFee,
    required this.imageColor,
    required this.createdAt,
  });

  factory CardMaster.fromJson(Map<String, dynamic> json) {
    return CardMaster(
      id: json['id'] as String,
      cardName: json['card_name'] as String,
      issuer: json['issuer'] as String,
      annualFee: json['annual_fee'] as int,
      imageColor: (json['image_color'] as String?) ?? '#7C83FD',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'card_name': cardName,
      'issuer': issuer,
      'annual_fee': annualFee,
      'image_color': imageColor,
    };
  }
}
