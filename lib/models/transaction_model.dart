class TransactionModel {
  final String id;
  final String username;
  final String type; // 'credit' or 'debit'
  final String category; // 'salary', 'bills', 'shopping', 'food', 'transfer', 'withdrawal', 'other'
  final String description;
  final double amount;
  final String date;
  final String note;

  TransactionModel({
    required this.id,
    required this.username,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'type': type,
        'category': category,
        'description': description,
        'amount': amount,
        'date': date,
        'note': note,
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] ?? '',
        username: json['username'] ?? '',
        type: json['type'] ?? 'debit',
        category: json['category'] ?? 'other',
        description: json['description'] ?? '',
        amount: (json['amount'] ?? 0.0).toDouble(),
        date: json['date'] ?? '',
        note: json['note'] ?? '',
      );
}
