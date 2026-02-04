class Transaction {
  final String id;
  final String userId;
  final String userCardId;
  final int amount;
  final String category;
  final String? memo;
  final DateTime transactionDate;
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.userId,
    required this.userCardId,
    required this.amount,
    required this.category,
    this.memo,
    required this.transactionDate,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userCardId: json['user_card_id'] as String,
      amount: json['amount'] as int,
      category: json['category'] as String,
      memo: json['memo'] as String?,
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_card_id': userCardId,
      'amount': amount,
      'category': category,
      'memo': memo,
      'transaction_date':
          transactionDate.toIso8601String().substring(0, 10),
    };
  }
}
