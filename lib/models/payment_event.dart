class PaymentEvent {
  final String id;
  final String username;
  final String title;
  final String type; // e.g., 'flight', 'birthday', 'bill', 'subscription', etc.
  final String icon; // icon name as string
  final DateTime date;
  bool isPaid;
  final double amount;
  final String? note;

  PaymentEvent({
    required this.id,
    required this.username,
    required this.title,
    required this.type,
    required this.icon,
    required this.date,
    this.isPaid = false,
    required this.amount,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'title': title,
        'type': type,
        'icon': icon,
        'date': date.toIso8601String(),
        'isPaid': isPaid,
        'amount': amount,
        'note': note,
      };

  factory PaymentEvent.fromJson(Map<String, dynamic> json) => PaymentEvent(
        id: json['id'] ?? '',
        username: json['username'] ?? '',
        title: json['title'] ?? '',
        type: json['type'] ?? '',
        icon: json['icon'] ?? 'payment',
        date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
        isPaid: json['isPaid'] ?? false,
        amount: (json['amount'] ?? 0.0).toDouble(),
        note: json['note'],
      );

  PaymentEvent copyWith({
    String? id,
    String? username,
    String? title,
    String? type,
    String? icon,
    DateTime? date,
    bool? isPaid,
    double? amount,
    String? note,
  }) {
    return PaymentEvent(
      id: id ?? this.id,
      username: username ?? this.username,
      title: title ?? this.title,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      date: date ?? this.date,
      isPaid: isPaid ?? this.isPaid,
      amount: amount ?? this.amount,
      note: note ?? this.note,
    );
  }
}
